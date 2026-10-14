import 'package:flutter/material.dart';

class RoomSeatsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> seats;
  final int currentSeatCount;
  final Function(int) onSeatTap;
  final Function(int) onSeatCountChanged;

  const RoomSeatsGrid({
    Key? key,
    required this.seats,
    required this.currentSeatCount,
    required this.onSeatTap,
    required this.onSeatCountChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. የሆስት (Host) ወንበር ከላይ መሃል ላይ
        if (seats.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildSeatItem(context, 0, isHost: true),
          const SizedBox(height: 12),
        ],

        // 2. የተቀሩት ተሳታፊ ወንበሮች (በ 4 ረድፍ ተቀራራቢ ሆነው)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: seats.length > 1 ? seats.length - 1 : 0,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final actualIndex = index + 1;
              return _buildSeatItem(context, actualIndex, isHost: false);
            },
          ),
        ),

        const SizedBox(height: 10),

        // 3. የወንበር ብዛት መቆጣጠሪያ ቁልፍ
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: PopupMenuButton<int>(
              initialValue: currentSeatCount,
              onSelected: onSeatCountChanged,
              color: const Color(0xFF1E2638),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 8,
                  child: Text('8 Seats', style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
                const PopupMenuItem(
                  value: 12,
                  child: Text('12 Seats', style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
                const PopupMenuItem(
                  value: 16,
                  child: Text('16 Seats', style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
                const PopupMenuItem(
                  value: 20,
                  child: Text('20 Seats', style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_seat_rounded, color: Color(0xFFFFB800), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$currentSeatCount Seats',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeatItem(BuildContext context, int index, {required bool isHost}) {

if (index >= seats.length) return const SizedBox();
    final seat = seats[index];
    final bool isOccupied = seat['user'] != null;
    final bool isSpeaking = seat['isSpeaking'] == true;
    final String displayName = isOccupied ? seat['user'].toString() : (isHost ? 'Host' : '${index + 1}');

    return GestureDetector(
      onTap: () => onSeatTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // ድምፅ ሲያወራ የሚበራ ክብ (Speaking Wave)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isHost ? 58 : 50,
                height: isHost ? 58 : 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSpeaking
                        ? const Color(0xFF00FFCC)
                        : (isOccupied ? const Color(0xFF4A90E2) : Colors.transparent),
                    width: isSpeaking ? 2.5 : 1.5,
                  ),
                  boxShadow: isSpeaking
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00FFCC).withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ]
                      : [],
                ),
              ),

              // የወንበሩ ዋና አምሳል (Avatar or Empty Seat)
              Container(
                width: isHost ? 52 : 44,
                height: isHost ? 52 : 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isOccupied
                      ? (isHost
                          ? const LinearGradient(colors: [Color(0xFFFF9900), Color(0xFFFF5E3A)])
                          : const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))
                      : null,
                  color: isOccupied ? null : Colors.black.withOpacity(0.35),
                  border: Border.all(
                    color: isOccupied ? Colors.white70 : Colors.white24,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: isOccupied
                      ? Text(
                          displayName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : Icon(
                          isHost ? Icons.star_rounded : Icons.mic_none_rounded,
                          color: isHost ? const Color(0xFFFFB800) : Colors.white38,
                          size: isHost ? 24 : 20,
                        ),
                ),
              ),

              // የወንበር ቁጥር መለያ (Badge)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isHost ? const Color(0xFFFF9900) : const Color(0xFF1E2638),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Text(
                    isHost ? '★' : '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // የስም ወይም የወንበር መለያ ጽሑፍ
          SizedBox(
            width: 60,
            child: Text(
              displayName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isOccupied ? Colors.white : Colors.white60,
                fontSize: 10.5,
                fontWeight: isOccupied ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
