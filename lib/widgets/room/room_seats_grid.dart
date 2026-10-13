import 'package:flutter/material.dart';

class RoomSeatsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> seats;
  final Function(int index) onSeatTap;
  final int currentSeatCount;
  final Function(int count) onSeatCountChanged;

  const RoomSeatsGrid({
    Key? key,
    required this.seats,
    required this.onSeatTap,
    required this.currentSeatCount,
    required this.onSeatCountChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final visibleSeats = seats.take(currentSeatCount).toList();
    final hostSeat = visibleSeats.isNotEmpty ? visibleSeats[0] : null;
    final otherSeats = visibleSeats.length > 1 ? visibleSeats.sublist(1) : [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hostSeat != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildHostSeat(hostSeat),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.72,
            ),
            itemCount: otherSeats.length,
            itemBuilder: (context, index) {
              final seat = otherSeats[index];
              final seatIndex = seat['index'] as int;
              final isGold = seatIndex >= 2 && seatIndex <= 7;
              return _buildSeatItem(seat, seatIndex - 1, isGold: isGold);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 14, top: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<int>(
              initialValue: currentSeatCount,
              tooltip: 'Change Seat Count',
              onSelected: onSeatCountChanged,
              color: const Color(0xFF1E2536),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_seat, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$currentSeatCount Seats',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                _buildMenuItem(10),
                _buildMenuItem(20),
                _buildMenuItem(30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<int> _buildMenuItem(int count) {
    return PopupMenuItem<int>(
      value: count,
      child: Text(
        '$count Seats',
        style: TextStyle(
          color: currentSeatCount == count ? const Color(0xFF00FFD5) : Colors.white,
          fontWeight: currentSeatCount == count ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildHostSeat(Map<String, dynamic> seat) {
    final hasUser = seat['user'] != null;
    final isSpeaking = seat['isSpeaking'] == true;
    final userName = seat['user'] ?? 'Host';

return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSeatTap(0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isSpeaking)
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00FFD5), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FFD5).withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: hasUser
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'H',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : const Icon(Icons.star, color: Colors.white, size: 24),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSeatItem(Map<String, dynamic> seat, int actualIndex, {required bool isGold}) {
    final hasUser = seat['user'] != null;
    final isSpeaking = seat['isSpeaking'] == true;
    final userName = seat['user'] ?? '';
    final seatIndex = seat['index'] as int;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSeatTap(actualIndex),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isSpeaking)
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(

shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00FFD5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FFD5).withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isGold
                      ? Border.all(color: const Color(0xFFFFD700), width: 1.5)
                      : Border.all(color: Colors.white24, width: 0.5),
                  gradient: hasUser
                      ? const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF8E44AD)],
                        )
                      : LinearGradient(
                          colors: isGold
                              ? [
                                  const Color(0xFF5A4515).withOpacity(0.6),
                                  const Color(0xFF2E2207).withOpacity(0.6)
                                ]
                              : [
                                  Colors.black.withOpacity(0.35),
                                  Colors.black.withOpacity(0.2)
                                ],
                        ),
                ),
                child: Center(
                  child: hasUser
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        )
                      : Icon(
                          Icons.mic_none,
                          color: isGold ? const Color(0xFFFFD700) : Colors.white38,
                          size: 15,
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                  decoration: BoxDecoration(
                    color: isGold ? const Color(0xFFD4AF37) : Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$seatIndex',
                    style: TextStyle(
                      fontSize: 7,
                      color: isGold ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            hasUser ? userName : '$seatIndex',
            style: TextStyle(
              fontSize: 9,
              color: isGold && !hasUser ? const Color(0xFFFFD700) : (hasUser ? Colors.white : Colors.white60),
              fontWeight: hasUser || isGold ? FontWeight.bold : FontWeight.normal,
              shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
