import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'main.dart';

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
  IO.Socket? socket;
  RtcEngine? _engine;
  bool _isMicMuted = false;
  int? _myCurrentChair;

  // 8 ወንበሮች - እያንዳንዱ ወንበር የተጠቃሚውን ስም እና ID ይይዛል
  final List<Map<String, dynamic>?> _chairs = List.generate(8, (_) => null);
  final List<String> _roomLogs = [];
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initSocket();
    _initAgora();
  }

  // 1. የሶኬት ግንኙነት (Socket.io)
  void _initSocket() {
    socket = IO.io(
      AppData.serverUrl,
      IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );
    socket?.connect();

    socket?.onConnect((_) {
      socket?.emit('join_room', {'room': widget.roomId});
    });

    // ሌላ ሰው ወይም እኔ ወንበር ስንይዝ/ስንለቅ የሚመጣ መረጃ
    socket?.on('chair_action', (data) {
      if (mounted) {
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
            _addLog('👤 $userName (ID: $userId) ወንበር #${chairIndex + 1} ያዘ');
          } else if (action == 'leave') {
            _chairs[chairIndex] = null;
            _addLog('🚪 $userName (ID: $userId) ከወንበር #${chairIndex + 1} ወረደ');
          }
        });
      }
    });

    socket?.on('chat_message', (data) {
      if (mounted) {
        setState(() {
          _addLog('${data['sender']} (ID: ${data['userId']}): ${data['text']}');
        });
      }
    });
  }

  // 2. የድምፅ ግንኙነት (Agora RTC Engine)
  Future<void> _initAgora() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine?.initialize(const RtcEngineContext(
        appId: AppData.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine?.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("Agora Channel Joined: ${connection.channelId}");
          },
          onUserMuteAudio: (RtcConnection connection, int remoteUid, bool muted) {
            setState(() {});
          },
        ),
      );

      await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine?.enableAudio();

      // ወደ ክፍሉ መግባት
      final uid = int.tryParse(AppData.currentUserId) ?? 0;
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
    _roomLogs.add(text);
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

// ወንበር ላይ መቀመጥ ወይም መልቀቅ
  void _toggleChair(int index) {
    if (_chairs[index] != null) {
      // ወንበሩ የተያዘው በእኔ ከሆነ መልቀቅ
      if (_chairs[index]!['userId'] == AppData.currentUserId) {
        socket?.emit('chair_action', {
          'room': widget.roomId,
          'chairIndex': index,
          'userName': AppData.currentUserName,
          'userId': AppData.currentUserId,
          'action': 'leave',
        });
        setState(() => _myCurrentChair = null);
      }
      return;
    }

    // ከቀድሞ ወንበር መነሳት
    if (_myCurrentChair != null) {
      socket?.emit('chair_action', {
        'room': widget.roomId,
        'chairIndex': _myCurrentChair,
        'userName': AppData.currentUserName,
        'userId': AppData.currentUserId,
        'action': 'leave',
      });
    }

    // አዲሱን ወንበር መያዝ - ስም እና ID አብረው ይላካሉ
    socket?.emit('chair_action', {
      'room': widget.roomId,
      'chairIndex': index,
      'userName': AppData.currentUserName,
      'userId': AppData.currentUserId,
      'action': 'sit',
    });
    setState(() => _myCurrentChair = index);
  }

  void _toggleMic() {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
    _engine?.muteLocalAudioStream(_isMicMuted);
  }

  @override
  void dispose() {
    if (_myCurrentChair != null) {
      socket?.emit('chair_action', {
        'room': widget.roomId,
        'chairIndex': _myCurrentChair,
        'userName': AppData.currentUserName,
        'userId': AppData.currentUserId,
        'action': 'leave',
      });
    }
    socket?.disconnect();
    socket?.dispose();
    _engine?.leaveChannel();
    _engine?.release();
    _logScrollController.dispose();
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
                Text('${AppData.userCoins}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner
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
                Text('Voice Room Live & Active!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),

// 8 Chairs Grid (ከስሩ የተጠቃሚው ID አብሮ የሚታይበት)
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
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
                      // ስም
                      Text(
                        isOccupied ? chair['userName'] : 'ወንበር ${index + 1}',
                        style: TextStyle(
                          color: isOccupied ? Colors.white : Colors.white54,
                          fontSize: 11,
                          fontWeight: isOccupied ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // ከስሙ ስር የሚቀመጠው የተጠቃሚው ID
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

          // System Messages / Room Logs
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

// Bottom Action Bar
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Say Hello...', style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.sports_esports_outlined, color: Colors.amber, size: 26),
                const SizedBox(width: 14),
                const Icon(Icons.card_giftcard, color: Colors.amber, size: 26),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
