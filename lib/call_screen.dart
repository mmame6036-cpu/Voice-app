import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'services/user_service.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final bool isHost;

  const CallScreen({
    Key? key,
    required this.channelName,
    this.isHost = false,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final UserService _user = UserService();
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initializeAgora();
  }

  Future<void> _initializeAgora() async {
    await [Permission.microphone].request();

    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: UserService.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (mounted) {
              setState(() {
                _isJoined = true;
              });
            }
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            // Remote user left
          },
        ),
      );

      await _engine!.enableAudio();
      await _engine!.setClientRole(
        role: widget.isHost ? ClientRoleType.clientRoleBroadcaster : ClientRoleType.clientRoleAudience,
      );

      // Fetch RTC Token if available or join with empty token
      String token = '';
      try {
        final res = await http.get(
          Uri.parse('${UserService.serverUrl}/api/get-token?channelName=${widget.channelName}'),
        ).timeout(const Duration(seconds: 3));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['token'] != null) {
            token = data['token'];
          }
        }
      } catch (_) {}

      await _engine!.joinChannel(
        token: token,
        channelId: widget.channelName,
        uid: int.tryParse(_user.userId) ?? 0,
        options: ChannelMediaOptions(
          clientRoleType: widget.isHost
              ? ClientRoleType.clientRoleBroadcaster
              : ClientRoleType.clientRoleAudience,
        ),
      );
    } catch (e) {
      debugPrint('Agora call error: $e');
    }
  }

  Future<void> _toggleMute() async {
    if (_engine == null) return;
    final nextState = !_isMuted;
    await _engine!.muteLocalAudioStream(nextState);
    setState(() {
      _isMuted = nextState;
    });
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.channelName, style: const TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFF1E293B),
              child: Icon(
                _isJoined ? Icons.record_voice_over : Icons.voice_over_off,
                size: 40,
                color: const Color(0xFF00C9A7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isJoined ? 'Connected to Room' : 'Connecting...',

style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 42,
                  icon: Icon(
                    _isMuted ? Icons.mic_off : Icons.mic,
                    color: _isMuted ? Colors.redAccent : const Color(0xFF00C9A7),
                  ),
                  onPressed: _toggleMute,
                ),
                const SizedBox(width: 24),
                IconButton(
                  iconSize: 42,
                  icon: const Icon(Icons.call_end, color: Colors.redAccent),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
