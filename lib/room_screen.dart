import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/user_service.dart';
import 'services/socket_service.dart';
import 'chicken_road_game.dart';

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

  // Total chairs capacity: 10, 20, or 30 (excluding host seat: 9, 19, or 29)
  int _totalCapacity = 10;
  Map<String, dynamic>? _hostSeat;
  List<Map<String, dynamic>?> _chairs = List.generate(9, (_) => null);

  final List<String> _roomLogs = [];
  final ScrollController _logScrollController = ScrollController();
  final TextEditingController _chatController = TextEditingController();

  bool get _isHost => widget.roomId == _userService.userId;

  @override
  void initState() {
    super.initState();
    if (_isHost) {
      _hostSeat = {
        'userName': _userService.userName,
        'userId': _userService.userId,
      };
    }
    _setupSocket();
    _initAgora();
  }

  void _updateCapacity(int capacity) {
    setState(() {
      _totalCapacity = capacity;
      final int regularSeats = capacity - 1;
      if (regularSeats > _chairs.length) {
        _chairs.addAll(List.generate(regularSeats - _chairs.length, (_) => null));
      } else if (regularSeats < _chairs.length) {
        if (_myCurrentChair != null && _myCurrentChair! >= regularSeats) {
          _socketService.sendChairAction(roomId: widget.roomId, chairIndex: _myCurrentChair!, action: 'leave');
          _myCurrentChair = null;
        }
        _chairs = _chairs.sublist(0, regularSeats);
      }
      _addLog('Room seat capacity set to $_totalCapacity');
    });
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
        if (chairIndex == -1) {
          if (action == 'sit') {
            _hostSeat = {'userName': userName, 'userId': userId};
            _addLog('$userName sat on Host Seat');
          } else if (action == 'leave') {
            _hostSeat = null;
            _addLog('$userName left Host Seat');
          }
        } else if (chairIndex >= 0 && chairIndex < _chairs.length) {
          if (action == 'sit') {
            _chairs[chairIndex] = {'userName': userName, 'userId': userId};
            _addLog('$userName sat on chair #${chairIndex + 1}');
          } else if (action == 'leave') {
            _chairs[chairIndex] = null;
            _addLog('$userName left chair #${chairIndex + 1}');
          }
        }
      });
    };

    _socketService.onChatMessageReceived = (data) {
      if (!mounted) return;
      final String sender = data['sender'] ?? 'User';
      final String text = data['text'] ?? '';
      setState(() {
        _addLog('$sender: $text');
      });
    };
  }

  Future<void> _initAgora() async {
    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        _addLog("Warning: Microphone permission denied");
        return;
      }

_engine = createAgoraRtcEngine();
      await _engine?.initialize(const RtcEngineContext(
        appId: UserService.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine?.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            _addLog("Audio connected successfully");
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            _addLog("User $remoteUid joined voice chat");
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            _addLog("User $remoteUid left");
          },
          onError: (ErrorCodeType err, String msg) {
            _addLog("Voice error: $err");
          },
        ),
      );

      await _engine?.enableAudio();
      await _engine?.enableLocalAudio(true);
      await _engine?.setDefaultAudioRouteToSpeakerphone(true);

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
        }
      } catch (e) {
        _addLog("Token request error: $e");
      }

      await _engine?.joinChannel(
        token: token,
        channelId: cleanRoomId,
        uid: 0,
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

  void _toggleHostChair() {
    if (!_isHost) return;
    if (_hostSeat != null) {
      _socketService.sendChairAction(roomId: widget.roomId, chairIndex: -1, action: 'leave');
      setState(() => _hostSeat = null);
    } else {
      _socketService.sendChairAction(roomId: widget.roomId, chairIndex: -1, action: 'sit');
      setState(() {
        _hostSeat = {'userName': _userService.userName, 'userId': _userService.userId};
      });
    }
  }

  void _toggleChair(int index) {
    if (_chairs[index] != null && _chairs[index]!['userId'] == _userService.userId) {
      _socketService.sendChairAction(roomId: widget.roomId, chairIndex: index, action: 'leave');
      setState(() {
        _myCurrentChair = null;
      });
      return;
    }

    if (_chairs[index] != null) return;

    if (_myCurrentChair != null) {
      _socketService.sendChairAction(roomId: widget.roomId, chairIndex: _myCurrentChair!, action: 'leave');
    }

    _socketService.sendChairAction(roomId: widget.roomId, chairIndex: index, action: 'sit');
    setState(() {
      _myCurrentChair = index;
    });
  }

  void _toggleMic() {
    setState(() => _isMicMuted = !_isMicMuted);
    _engine?.muteLocalAudioStream(_isMicMuted);
    _addLog(_isMicMuted ? "Mic muted" : "Mic unmuted");
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _socketService.sendChatMessage(roomId: widget.roomId, text: text);
    _chatController.clear();
  }

void _openGameBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ChickenRoadGameView(
          socket: _socketService.socket,
          onCoinsChanged: () {
            if (mounted) setState(() {});
          },
        );
      },
    );
  }

  void _showSeatCapacitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131124),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Seats Mode',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose the total seat capacity for your room',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCapacityButton(10),
                  _buildCapacityButton(20),
                  _buildCapacityButton(30),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCapacityButton(int count) {
    final bool isSelected = _totalCapacity == count;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _updateCapacity(count);
      },
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00C9A7) : const Color(0xFF1E1B38),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF00C9A7) : Colors.white12,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_seat,
              color: isSelected ? Colors.black : Colors.white70,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              '$count Seats',
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_myCurrentChair != null) {
      _socketService.sendChairAction(roomId: widget.roomId, chairIndex: _myCurrentChair!, action: 'leave');
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
      backgroundColor: const Color(0xFF0D0B18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131124),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('ID: ${widget.roomId} • $_totalCapacity Seats', style: const TextStyle(fontSize: 12, color: Colors.amber)),

],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF00C9A7)),
            tooltip: 'Seats Layout',
            onPressed: _showSeatCapacitySelector,
          ),
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
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _toggleHostChair,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                        color: _hostSeat != null ? Colors.amber : const Color(0xFF1E1B38),
                      ),
                      child: Center(
                        child: _hostSeat != null
                            ? Text(
                                (_hostSeat!['userName'] ?? 'H')[0].toUpperCase(),
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                              )
                            : const Icon(Icons.chair, color: Colors.amber, size: 28),
                      ),
                    ),
                    const Positioned(
                      top: -2,
                      child: Icon(Icons.star, color: Colors.amber, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _hostSeat != null ? _hostSeat!['userName'] : widget.hostName,
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  'Host • ID: ${widget.roomId}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            flex: 6,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _chairs.length,
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
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
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOccupied ? const Color(0xFF00C9A7) : const Color(0xFF1B1833),
                          border: Border.all(
                            color: isOccupied ? Colors.white : Colors.amber.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: isOccupied
                              ? Text(
                                  (chair['userName'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                )
                              : const Icon(Icons.chair_outlined, color: Colors.white54, size: 20),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOccupied ? chair['userName'] : '${index + 1}',
                        style: TextStyle(
                          color: isOccupied ? Colors.white : Colors.amber.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                color: const Color(0xFF131124).withOpacity(0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: ListView.builder(
                controller: _logScrollController,
                itemCount: _roomLogs.length,
                itemBuilder: (context, idx) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: const Color(0xFF131124),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isMicMuted ? Icons.mic_off : Icons.mic,
                    color: _isMicMuted ? Colors.redAccent : const Color(0xFF00C9A7),
                    size: 26,
                  ),
                  onPressed: _toggleMic,
                ),
                IconButton(
                  icon: const Icon(Icons.sports_esports, color: Colors.amber, size: 28),
                  tooltip: 'Play Games',
                  onPressed: _openGameBottomSheet,
                ),
                const SizedBox(width: 4),
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
