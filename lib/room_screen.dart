import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'user_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;
  bool isConnected = false;

  Function(Map<String, dynamic>)? onChairActionReceived;
  Function(Map<String, dynamic>)? onChatMessageReceived;

  void connect() {
    if (socket != null && socket!.connected) return;

    socket = IO.io(
      UserService.serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    socket?.connect();

    socket?.onConnect((_) {
      isConnected = true;
      debugPrint('Socket Connected Successfully');
    });

    socket?.onDisconnect((_) {
      isConnected = false;
      debugPrint('Socket Disconnected');
    });

    // Seat events listener
    socket?.on('chair_action', (data) {
      if (data != null && onChairActionReceived != null) {
        if (data is Map<String, dynamic>) {
          onChairActionReceived!(data);
        } else if (data is Map) {
          onChairActionReceived!(Map<String, dynamic>.from(data));
        }
      }
    });

    // Chat message listener
    socket?.on('chat_message', (data) {
      if (data != null && onChatMessageReceived != null) {
        if (data is Map<String, dynamic>) {
          onChatMessageReceived!(data);
        } else if (data is Map) {
          onChatMessageReceived!(Map<String, dynamic>.from(data));
        }
      }
    });

    // Fallback broadcast listener
    socket?.on('message', (data) {
      if (data != null && onChatMessageReceived != null) {
        if (data is Map<String, dynamic>) {
          onChatMessageReceived!(data);
        } else if (data is Map) {
          onChatMessageReceived!(Map<String, dynamic>.from(data));
        }
      }
    });
  }

  void joinRoom(String roomId) {
    if (socket == null || !socket!.connected) {
      connect();
    }
    socket?.emit('join_room', roomId);
    socket?.emit('join', roomId);
  }

  void sendChairAction({
    required String roomId,
    required int chairIndex,
    required String action,
  }) {
    final user = UserService();
    final payload = {
      'room': roomId,
      'roomId': roomId,
      'chairIndex': chairIndex,
      'userName': user.userName,
      'userId': user.userId,
      'action': action,
    };
    socket?.emit('chair_action', payload);
  }

  void sendChatMessage({
    required String roomId,
    required String text,
  }) {
    final user = UserService();
    final payload = {
      'room': roomId,
      'roomId': roomId,
      'sender': user.userName,
      'userId': user.userId,
      'text': text,
    };
    socket?.emit('chat_message', payload);
    socket?.emit('message', payload);
  }

  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
    isConnected = false;
  }
}

import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'services/user_service.dart';
import 'services/socket_service.dart';

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
          _addLog('$userName (ID: $userId) sat on Seat #${chairIndex + 1}');
        } else if (action == 'leave') {
          _chairs[chairIndex] = null;
          _addLog('$userName (ID: $userId) left Seat #${chairIndex + 1}');
        }
      });
    };

    _socketService.onChatMessageReceived = (data) {
      if (!mounted) return;
      final String sender = data['sender'] ?? 'User';
      final String userId = data['userId']?.toString() ?? '';
      final String text = data['text'] ?? '';

      // የራስህ መልዕክት ቀድሞ በስክሪኑ ስለሚታይ እንዳይደገም
      if (userId != _userService.userId) {
        setState(() {
          _addLog('$sender (ID: $userId): $text');
        });
      }
    };
  }

  Future<void> _initAgora() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine?.initialize(const RtcEngineContext(
        appId: UserService.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine?.enableAudio();

      final uid = int.tryParse(_userService.userId) ?? 0;
      await _engine?.joinChannel(
        token: '',
        channelId: widget.roomId,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
        ),
      );
    } catch (e) {
      debugPrint("Agora Error: $e");
    }
  }

  void _addLog(String text) {
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
    setState(() {
      if (_chairs[index] != null && _chairs[index]!['userId'] == _userService.userId) {
        _chairs[index] = null;
        _myCurrentChair = null;
        _addLog('${_userService.userName} left Seat #${index + 1}');
        _socketService.sendChairAction(
          roomId: widget.roomId,
          chairIndex: index,
          action: 'leave',
        );
        return;
      }

      if (_chairs[index] != null) {
        return;
      }

if (_myCurrentChair != null) {
        _chairs[_myCurrentChair!] = null;
        _socketService.sendChairAction(
          roomId: widget.roomId,
          chairIndex: _myCurrentChair!,
          action: 'leave',
        );
      }

      _chairs[index] = {
        'userName': _userService.userName,
        'userId': _userService.userId,
      };
      _myCurrentChair = index;
      _addLog('${_userService.userName} (ID: ${_userService.userId}) sat on Seat #${index + 1}');

      _socketService.sendChairAction(
        roomId: widget.roomId,
        chairIndex: index,
        action: 'sit',
      );
    });
  }

  void _toggleMic() {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
    _engine?.muteLocalAudioStream(_isMicMuted);
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    // በስክሪኑ ላይ ወዲያውኑ ማሳየት
    _addLog('${_userService.userName} (ID: ${_userService.userId}): $text');

    // በሶኬት ለሌሎች መላክ
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
                Text('Tap any seat to sit down and speak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
                        isOccupied ? chair['userName'] : 'Seat ${index + 1}',
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
                        hintText: 'Say Hello...',
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
