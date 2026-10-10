import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/user_service.dart';
import '../services/socket_service.dart';

class RoomScreen extends StatefulWidget {
  final String roomId;
  final String roomTitle;
  final String hostName;

  const RoomScreen({
    Key? key,
    required this.roomId,
    required this.roomTitle,
    required this.hostName,
  }) : super(key: key);

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final UserService _userService = UserService();
  final SocketService _socketService = SocketService();

  RtcEngine? _engine;
  bool _isMicMuted = false;
  int? _myCurrentChair;

  final List<Map<String, dynamic>?> _chairs = List.generate(8, (_) => null);
  final List<String> _roomLogs = [];
  final ScrollController _logScrollController = ScrollController();
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupSocket();
    _initAgora();
  }

  void _setupSocket() {
    _socketService.connect();
    _socketService.joinRoom(widget.roomId);

    _socketService.onChairActionReceived = (data) {
      if (!mounted) return;
      final int chairIndex = data['chairIndex'] ?? 0;
      final String action = data['action'] ?? '';
      final String userName = data['userName'] ?? 'User';
      final String userId = data['userId']?.toString() ?? '';

      setState(() {
        if (action == 'sit') {
          _chairs[chairIndex] = {
            'userName': userName,
            'userId': userId,
          };
          _addLog('$userName (ID: $userId) sat on chair #${chairIndex + 1}');
        } else if (action == 'leave') {
          _chairs[chairIndex] = null;
          _addLog('$userName (ID: $userId) left chair #${chairIndex + 1}');
        }
      });
    };

    _socketService.onChatMessageReceived = (data) {
      if (!mounted) return;
      final String sender = data['sender'] ?? 'User';
      final String userId = data['userId']?.toString() ?? '';
      final String text = data['text'] ?? '';

      setState(() {
        _addLog('$sender (ID: $userId): $text');
      });
    };
  }

  Future<void> _initAgora() async {
    try {
      // 1. Request microphone permission
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        _addLog("Warning: Microphone permission denied");
        return;
      }

      // 2. Initialize Agora RTC engine
      _engine = createAgoraRtcEngine();
      await _engine?.initialize(const RtcEngineContext(
        appId: UserService.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine?.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            _addLog("Audio connected successfully 🎙️");
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            _addLog("User ID $remoteUid joined voice chat");
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            _addLog("User ID $remoteUid disconnected");
          },
          onError: (ErrorCodeType err, String msg) {
            _addLog("Voice error: $err");
          },
        ),
      );

      // 3. Audio setup
      await _engine?.enableAudio();
      await _engine?.enableLocalAudio(true);
      await _engine?.setDefaultAudioRouteToSpeakerphone(true);

      // 4. Fetch dynamic token from Render server with channel and UID 0
      String token = '';
      final cleanRoomId = widget.roomId.trim();

      try {
        final response = await http.get(Uri.parse(
          'https://voice-app-2-jd95.onrender.com/api/get-token?channelName=$cleanRoomId&uid=0',
        ));

if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          token = data['token'] ?? '';
          _addLog("Token acquired successfully");
        } else {
          _addLog("Token request failed: ${response.statusCode}");
        }
      } catch (e) {
        _addLog("Token request error: $e");
      }

      // 5. Join Agora room with dynamic token and UID 0
      await _engine?.joinChannel(
        token: token,
        channelId: widget.roomId.trim(),
        uid: 0, // <-- ይህ ቦታ የግድ 0 መሆን አለበት!
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
      );
    } catch (e) {
      _addLog("Agora Init Exception: $e");
    }
  }

  void _addLog(String text) {
    if (!mounted) return;
    setState(() {
      _roomLogs.add(text);
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleChair(int index) {
    if (_chairs[index] != null && _chairs[index]!['userId'] == _userService.userId) {
      setState(() {
        _chairs[index] = null;
        _myCurrentChair = null;
      });
      _socketService.sendChairAction(
        roomId: widget.roomId,
        chairIndex: index,
        action: 'leave',
      );
      return;
    }

    if (_chairs[index] != null) return;

    if (_myCurrentChair != null) {
      final prevChair = _myCurrentChair!;
      setState(() {
        _chairs[prevChair] = null;
      });
      _socketService.sendChairAction(
        roomId: widget.roomId,
        chairIndex: prevChair,
        action: 'leave',
      );
    }

    setState(() {
      _chairs[index] = {
        'userName': _userService.userName,
        'userId': _userService.userId,
      };
      _myCurrentChair = index;
    });

    _socketService.sendChairAction(
      roomId: widget.roomId,
      chairIndex: index,
      action: 'sit',
    );
  }

  void _toggleMic() {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
    _engine?.muteLocalAudioStream(_isMicMuted);
    _addLog(_isMicMuted ? "Mic muted 🔇" : "Mic unmuted 🎙️");
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    _socketService.sendChatMessage(roomId: widget.roomId, text: text);
    _chatController.clear();
  }

  @override
  void dispose() {
    if (_myCurrentChair != null) {
      _socketService.sendChairAction(
        roomId: widget.roomId,
        chairIndex: _myCurrentChair!,
        action: 'leave',
      );
    }
    _engine?.leaveChannel();
    _engine?.release();
    _logScrollController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Room ID: ${widget.roomId}', style: const TextStyle(fontSize: 12, color: Color(0xFF00C9A7))),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),

padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${_userService.coins}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5C248B), Color(0xFF28114B)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text('Tap any chair to speak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: 8,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final chair = _chairs[index];
                final bool isOccupied = chair != null;

                return GestureDetector(
                  onTap: () => _toggleChair(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOccupied ? const Color(0xFF00C9A7) : const Color(0xFF1E2638),
                          border: Border.all(
                            color: isOccupied ? Colors.white : Colors.white24,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isOccupied
                              ? Text(
                                  (chair['userName'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                                )
                              : const Icon(Icons.chair_outlined, color: Colors.white38, size: 26),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isOccupied ? chair['userName'] : 'Chair ${index + 1}',
                        style: TextStyle(
                          color: isOccupied ? Colors.white : Colors.white54,
                          fontSize: 11,
                          fontWeight: isOccupied ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,

overflow: TextOverflow.ellipsis,
                      ),
                      if (isOccupied)
                        Text(
                          'ID: ${chair['userId']}',
                          style: const TextStyle(
                            color: Color(0xFF00C9A7),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26).withOpacity(0.8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListView.builder(
                controller: _logScrollController,
                itemCount: _roomLogs.length,
                itemBuilder: (context, idx) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      _roomLogs[idx],
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF161B26),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isMicMuted ? Icons.mic_off : Icons.mic,
                    color: _isMicMuted ? Colors.redAccent : const Color(0xFF00C9A7),
                    size: 28,
                  ),
                  onPressed: _toggleMic,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF00C9A7), size: 22),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
