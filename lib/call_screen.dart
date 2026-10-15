import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'services/user_service.dart';

class CallScreen extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String channelName;
  final bool isIncoming;

  const CallScreen({
    Key? key,
    required this.targetUserId,
    required this.targetUserName,
    required this.channelName,
    this.isIncoming = false,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final UserService _user = UserService();
  late IO.Socket _socket;
  RtcEngine? _engine;

  bool _isCallConnected = false;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  String _callStatus = 'Calling...';

  Timer? _callDurationTimer;
  Timer? _coinDeductTimer;
  int _callSeconds = 0;

  @override
  void initState() {
    super.initState();
    _callStatus = widget.isIncoming ? 'Incoming Call...' : 'Calling...';
    _initSocket();
    if (!widget.isIncoming) {
      _initAgora();
    }
  }

  void _initSocket() {
    _socket = IO.io(
      UserService.serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket.connect();

    _socket.onConnect((_) {
      _socket.emit('user_connected', _user.userId);
      if (!widget.isIncoming) {
        // Send call request to target user
        _socket.emit('call_user', {
          'callerId': _user.userId,
          'callerName': _user.userName,
          'targetUserId': widget.targetUserId,
        });
      }
    });

    _socket.on('call_ringing', (data) {
      if (mounted) setState(() => _callStatus = 'Ringing...');
    });

    _socket.on('call_accepted', (data) async {
      if (mounted) {
        setState(() {
          _callStatus = 'Connected';
          _isCallConnected = true;
        });
        _startCallTimers();
      }
    });

    _socket.on('call_rejected', (data) {
      _showToast(data['reason'] ?? 'Call Declined');
      _finishCall();
    });

    _socket.on('call_ended', (_) {
      _showToast('Call Ended');
      _finishCall();
    });

    _socket.on('call_balance_depleted', (data) {
      _showToast(data['message'] ?? 'Coins depleted');
      _finishCall();
    });

    _socket.on('call_coin_deducted', (data) {
      if (data['remainingCoins'] != null) {
        _user.coins = data['remainingCoins'];
      }
    });
  }

  Future<void> _initAgora() async {
    try {
      final response = await http.get(
        Uri.parse('${UserService.serverUrl}/api/get-token?channelName=${widget.channelName}'),
      );
      String token = '';
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) token = data['token'];
      }

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        const RtcEngineContext(appId: UserService.agoraAppId),
      );

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("Joined call channel: ${connection.channelId}");
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (mounted) {
              setState(() {
                _callStatus = 'Connected';
                _isCallConnected = true;
              });
              _startCallTimers();
            }
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            _finishCall();
          },
        ),
      );

await _engine!.enableAudio();
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );

      await _engine!.joinChannel(
        token: token,
        channelId: widget.channelName,
        uid: int.tryParse(_user.userId) ?? 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
        ),
      );
    } catch (e) {
      debugPrint("Agora init error: $e");
    }
  }

  void _startCallTimers() {
    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _callSeconds++);
      }
    });

    // Deduct coins every 60 seconds (Only caller pays)
    if (!widget.isIncoming) {
      _coinDeductTimer?.cancel();
      _coinDeductTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
        _socket.emit('call_deduct_coins', {
          'callerId': _user.userId,
          'receiverId': widget.targetUserId,
          'amount': 20,
        });
      });
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _engine?.muteLocalAudioStream(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    _engine?.setEnableSpeakerphone(_isSpeakerOn);
  }

  void _acceptCall() async {
    _socket.emit('accept_call', {
      'callerId': widget.targetUserId,
      'receiverId': _user.userId,
      'channelName': widget.channelName,
    });
    setState(() {
      _callStatus = 'Connecting...';
      _isCallConnected = true;
    });
    await _initAgora();
  }

  void _rejectCall() {
    _socket.emit('reject_call', {
      'callerId': widget.targetUserId,
      'reason': 'Call declined',
    });
    _finishCall();
  }

  void _endCall() {
    _socket.emit('end_call', {
      'targetUserId': widget.targetUserId,
    });
    _finishCall();
  }

  void _finishCall() {
    _callDurationTimer?.cancel();
    _coinDeductTimer?.cancel();
    _engine?.leaveChannel();
    _engine?.release();
    _socket.disconnect();
    if (mounted) Navigator.pop(context);
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    _callDurationTimer?.cancel();
    _coinDeductTimer?.cancel();
    _engine?.leaveChannel();
    _engine?.release();
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // User Avatar
            CircleAvatar(
              radius: 64,
              backgroundColor: const Color(0xFF161B26),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF00C9A7),
                child: Text(
                  widget.targetUserName.isNotEmpty
                      ? widget.targetUserName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // User Name
            Text(
              widget.targetUserName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),

// User ID
            Text(
              'ID: ${widget.targetUserId}',
              style: const TextStyle(fontSize: 14, color: Colors.white54),
            ),
            const SizedBox(height: 16),

            // Call Status / Duration Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isCallConnected ? _formatDuration(_callSeconds) : _callStatus,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isCallConnected ? const Color(0xFF00C9A7) : Colors.amber,
                ),
              ),
            ),

            const Spacer(),

            // Rate Notice
            if (!widget.isIncoming)
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text(
                  'Call Rate: 20 Coins / min',
                  style: TextStyle(fontSize: 12, color: Colors.white38),
                ),
              ),

            // Bottom Control Action Buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 48, left: 32, right: 32),
              child: widget.isIncoming && !_isCallConnected
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Decline Call
                        FloatingActionButton(
                          heroTag: 'btn_reject',
                          backgroundColor: Colors.redAccent,
                          onPressed: _rejectCall,
                          child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                        ),
                        // Accept Call
                        FloatingActionButton(
                          heroTag: 'btn_accept',
                          backgroundColor: Colors.greenAccent.shade700,
                          onPressed: _acceptCall,
                          child: const Icon(Icons.call, color: Colors.white, size: 30),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mute Mic Button
                        IconButton(
                          iconSize: 32,
                          icon: Icon(
                            _isMuted ? Icons.mic_off : Icons.mic,
                            color: _isMuted ? Colors.redAccent : Colors.white,
                          ),
                          onPressed: _toggleMute,
                        ),

                        // End Call Red Button
                        FloatingActionButton(
                          heroTag: 'btn_end',
                          backgroundColor: Colors.redAccent,
                          onPressed: _endCall,
                          child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                        ),

                        // Speaker Toggle Button
                        IconButton(
                          iconSize: 32,
                          icon: Icon(
                            _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                            color: _isSpeakerOn ? const Color(0xFF00C9A7) : Colors.white,
                          ),
                          onPressed: _toggleSpeaker,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
