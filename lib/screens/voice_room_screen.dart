import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../services/agora_service.dart';
import '../services/room_service.dart';

class VoiceRoomScreen extends StatefulWidget {
  final String roomTitle;
  final String roomId;
  final String hostName;
  final int userNumericId;
  final String userUid;
  final String userName;

  const VoiceRoomScreen({
    super.key,
    required this.roomTitle,
    required this.roomId,
    required this.hostName,
    required this.userNumericId,
    required this.userUid,
    required this.userName,
  });

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> {
  final AgoraService _agoraService = AgoraService();
  final RoomService _roomService = RoomService();

  bool _isMuted = false;
  int? _mySeatIndex;
  int _totalSeats = 30;
  final Set<int> _activeSpeakers = {};

  @override
  void initState() {
    super.initState();
    _setupRoom();
  }

  Future<void> _setupRoom() async {
    await _roomService.initializeRoom(
      roomId: widget.roomId,
      roomTitle: widget.roomTitle,
      hostUid: widget.userUid,
      hostName: widget.hostName,
    );

    await _agoraService.initEngine(
      onUserJoined: (uid) {},
      onUserOffline: (uid) {},
      onVolumeChanged: (List<AudioVolumeInfo> speakers) {
        if (!mounted) return;
        setState(() {
          _activeSpeakers.clear();
          for (var speaker in speakers) {
            if ((speaker.volume ?? 0) > 10) {
              _activeSpeakers.add(speaker.uid ?? 0);
            }
          }
        });
      },
    );

    await _agoraService.joinRoom(
      channelId: widget.roomId,
      uid: widget.userNumericId,
      isSpeaker: false,
    );
  }

  void _handleSeatAction(int index, dynamic seatData) async {
    final bool isMySeat = seatData != null && seatData['uid'] == widget.userUid;

    if (isMySeat) {
      await _roomService.leaveSeat(
        roomId: widget.roomId,
        uid: widget.userUid,
      );
      await _agoraService.switchRole(isSpeaker: false);
      setState(() {
        _mySeatIndex = null;
      });
    } else if (seatData == null) {
      await _roomService.takeSeat(
        roomId: widget.roomId,
        seatIndex: index,
        uid: widget.userUid,
        name: widget.userName,
      );
      await _agoraService.switchRole(isSpeaker: true);
      setState(() {
        _mySeatIndex = index;
      });
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _agoraService.setMicrophoneMute(_isMuted);
  }

  void _adjustSeats(int delta) {
    setState(() {
      final newCount = _totalSeats + delta;
      if (newCount >= 4 && newCount <= 30) {
        _totalSeats = newCount;
      }
    });
  }

  @override
  void dispose() {
    if (_mySeatIndex != null) {
      _roomService.leaveSeat(roomId: widget.roomId, uid: widget.userUid);
    }
    _agoraService.leaveRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0A1C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.roomTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Room ID: ${widget.roomId} • $_totalSeats Seats",
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.white60),

tooltip: "Reduce Seats",
            onPressed: _totalSeats > 4 ? () => _adjustSeats(-2) : null,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFFD700)),
            tooltip: "Increase Seats",
            onPressed: _totalSeats < 30 ? () => _adjustSeats(2) : null,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: _roomService.getRoomStream(widget.roomId),
          builder: (context, snapshot) {
            List<dynamic> seats = List.filled(30, null);

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data != null && data['seats'] != null) {
                seats = List.from(data['seats']);
              }
            }

            return Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFFD700), width: 3),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                        ),
                        child: const Icon(Icons.mic, color: Colors.white, size: 34),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.hostName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Text(
                        "Host Room",
                        style: TextStyle(color: Color(0xFFFFD700), fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _totalSeats,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.75,
                      ),
                      itemBuilder: (context, index) {
                        final seatData = index < seats.length ? seats[index] : null;
                        final bool isOccupied = seatData != null;
                        final String seatLabel = isOccupied ? (seatData['name'] ?? 'User') : "${index + 1}";
                        final bool isMe = isOccupied && seatData['uid'] == widget.userUid;

                        return GestureDetector(
                          onTap: () => _handleSeatAction(index, seatData),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 48,
                                height: 48,

decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isOccupied
                                      ? (isMe ? const Color(0xFF00C9A7) : const Color(0xFF6C5CE7))
                                      : Colors.white.withOpacity(0.07),
                                  border: Border.all(
                                    color: isOccupied ? Colors.white70 : Colors.white24,
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  isOccupied ? Icons.person : Icons.event_seat,
                                  color: isOccupied ? Colors.white : Colors.white24,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                seatLabel,
                                style: TextStyle(
                                  color: isOccupied ? Colors.white : Colors.white38,
                                  fontSize: 10,
                                  fontWeight: isOccupied ? FontWeight.bold : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF16122C),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isMuted ? Icons.mic_off : Icons.mic,
                          color: _mySeatIndex != null
                              ? (_isMuted ? Colors.redAccent : const Color(0xFF00C9A7))
                              : Colors.white24,
                          size: 28,
                        ),
                        onPressed: _mySeatIndex != null ? _toggleMute : null,
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        icon: const Icon(Icons.card_giftcard, size: 20),
                        label: const Text(
                          "Send Gift",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Gifts coming soon")),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
