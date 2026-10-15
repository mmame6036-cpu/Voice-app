import 'package:flutter/material.dart';

class RoomSeatsGrid extends StatelessWidget {
  final int currentSeatCount;
  final Function(int seatIndex)? onSeatTap;

  const RoomSeatsGrid({
    Key? key,
    int? currentSeatCount,
    int? seatCount,
    int? seats,
    this.onSeatTap,
  })  : currentSeatCount = currentSeatCount ?? seatCount ?? seats ?? 25,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (currentSeatCount == 25) {
      return _build25SeatsLayout();
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: currentSeatCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: currentSeatCount <= 16 ? 4 : 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (ctx, i) => _buildSeatItem(seatNumber: i + 1, hasCrown: i < 3),
    );
  }

  Widget _build25SeatsLayout() {
    return Column(
      children: [
        _buildSeatItem(seatNumber: 1, isHost: true),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSeatItem(seatNumber: 2, hasCrown: true),
            _buildSeatItem(seatNumber: 3, hasCrown: true),
            _buildSeatItem(seatNumber: 4, hasCrown: true),
            _buildSeatItem(seatNumber: 5, hasCrown: true),
            _buildSeatItem(seatNumber: 6, hasCrown: true),
            _buildSeatItem(seatNumber: 7, hasCrown: false),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (i) => _buildSeatItem(seatNumber: i + 8)),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (i) => _buildSeatItem(seatNumber: i + 14)),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (i) => _buildSeatItem(seatNumber: i + 20)),
        ),
      ],
    );
  }

  Widget _buildSeatItem({required int seatNumber, bool isHost = false, bool hasCrown = false}) {
    return GestureDetector(
      onTap: () => onSeatTap?.call(seatNumber),
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
                  child: Icon(Icons.workspace_premium, size: 16, color: Color(0xFFFFD700)),
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
                    color: hasCrown ? Colors.amber.withOpacity(0.5) : Colors.white24,
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.chair, color: Colors.white70, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '$seatNumber',
            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
