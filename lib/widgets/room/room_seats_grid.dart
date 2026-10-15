import 'package:flutter/material.dart';

class RoomSeatsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> seats;
  final int currentSeatCount;
  final Function(int seatIndex)? onSeatTap;
  final Function(int count)? onSeatCountChanged;

  const RoomSeatsGrid({
    Key? key,
    required this.seats,
    required this.currentSeatCount,
    this.onSeatTap,
    this.onSeatCountChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (currentSeatCount == 25) {
      return _build25SeatsLayout();
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: seats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: currentSeatCount <= 16 ? 4 : 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (ctx, i) => _buildSeatItem(i, i < 3),
    );
  }

  Widget _build25SeatsLayout() {
    return Column(
      children: [
        _buildSeatItem(0, false, isHost: true),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSeatItem(1, true),
            _buildSeatItem(2, true),
            _buildSeatItem(3, true),
            _buildSeatItem(4, true),
            _buildSeatItem(5, true),
            _buildSeatItem(6, false),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (i) => _buildSeatItem(i + 7, false)),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (i) => _buildSeatItem(i + 13, false)),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (i) => _buildSeatItem(i + 19, false)),
        ),
      ],
    );
  }

  Widget _buildSeatItem(int index, bool hasCrown, {bool isHost = false}) {
    if (index >= seats.length) return const SizedBox(width: 38, height: 38);
    final seat = seats[index];
    final userName = seat['user'] as String?;
    final isSpeaking = seat['isSpeaking'] == true;

    return GestureDetector(
      onTap: () => onSeatTap?.call(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (hasCrown)
                const Positioned(
                  top: -12,
                  child: Icon(
                    Icons.workspace_premium,
                    size: 16,
                    color: Color(0xFFFFD700),
                  ),
                ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF4A4B54), Color(0xFF1E1F26)],
                    center: Alignment(-0.2, -0.3),
                  ),
                  border: Border.all(
                    color: isSpeaking
                        ? const Color(0xFF00C9A7)
                        : (hasCrown ? Colors.amber.withOpacity(0.5) : Colors.white24),
                    width: isSpeaking ? 2.0 : 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: userName != null && userName.isNotEmpty
                    ? Center(
                        child: Text(

userName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const Icon(Icons.chair, color: Colors.white70, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            userName != null && userName.isNotEmpty ? userName : '${index + 1}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
