import 'package:flutter/material.dart';
import '../services/agora_service.dart';

class VoiceRoomScreen extends StatefulWidget {
  final String roomTitle;
  final String roomId;
  final String hostName;
  final int userNumericId;

  const VoiceRoomScreen({
    super.key,
    required this.roomTitle,
    required this.roomId,
    required this.hostName,
    required this.userNumericId,
  });

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> {
  final AgoraService _agoraService = AgoraService();
  bool _isMuted = false;
  int? _mySeatIndex;

  // Default is set to 30 seats, can be adjusted dynamically up to 30
  int _totalSeats = 30;
  late List<String?> _seats;

  @override
  void initState() {
    super.initState();
    _seats = List.filled(30, null);
    _seats[0] = widget.hostName; // Seat 0 belongs to the Room Host
    _initializeAgoraRoom();
  }

  Future<void> _initializeAgoraRoom() async {
    await _agoraService.initAgora(
      onUserJoined: (uid) {},
      onUserOffline: (uid) {},
    );

    await _agoraService.joinVoiceRoom(
      channelId: widget.roomId,
      uid: widget.userNumericId,
      isBroadcaster: false,
    );
  }

  void _handleSeatTap(int index) async {
    if (_mySeatIndex == index) {
      // Leave current seat and become audience
      setState(() {
        _seats[index] = null;
        _mySeatIndex = null;
      });
      await _agoraService.switchRole(isBroadcaster: false);
    } else if (_seats[index] == null) {
      // Take the empty seat and enable broadcaster role
      setState(() {
        if (_mySeatIndex != null) {
          _seats[_mySeatIndex!] = null;
        }
        _seats[index] = "Me";
        _mySeatIndex = index;
      });
      await _agoraService.switchRole(isBroadcaster: true);
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _agoraService.muteLocalAudio(_isMuted);
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
          // Seat adjustment buttons (+ / -)
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.white60),
            tooltip: "Reduce seats",
            onPressed: _totalSeats > 4 ? () => _adjustSeats(-2) : null,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFFD700)),
            tooltip: "Increase seats up to 30",
            onPressed: _totalSeats < 30 ? () => _adjustSeats(2) : null,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Host Badge
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
            // Dynamic Seats Grid (Up to 30 seats)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _totalSeats,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5, // 5 columns fits 30 seats cleanly
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final occupier = _seats[index];
                    final isOccupied = occupier != null;
                    final isMe = _mySeatIndex == index;

                    return GestureDetector(
                      onTap: () => _handleSeatTap(index),
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
                            isOccupied ? occupier : "${index + 1}",
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
            // Bottom Controls Bar
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
                        const SnackBar(content: Text("Gifts coming in Phase 3!")),
                      );
                    },
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
