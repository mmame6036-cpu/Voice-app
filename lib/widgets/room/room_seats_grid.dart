import 'package:flutter/material.dart';

class RoomSeatsGrid extends StatelessWidget {
  final int currentSeatCount;
  final Function(int seatIndex)? onSeatTap;
  final Function(int count)? onSeatCountChanged;
  final Function(int count)? onSeatsCountChanged;
  final Function(int count)? onSeatsChanged;

  const RoomSeatsGrid({
    Key? key,
    int? currentSeatCount,
    int? seatCount,
    int? seats,
    int? seatsCount,
    this.onSeatTap,
    this.onSeatCountChanged,
    this.onSeatsCountChanged,
    this.onSeatsChanged,
    Function(int)? onSeatSelected,
  })  : currentSeatCount = currentSeatCount ?? seatCount ?? seats ?? seatsCount ?? 25,
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
      itemBuilder: (ctx, i) => _buildSeatItem(i + 1, false, i < 3),
    );
  }

  Widget _build25SeatsLayout() {
    return Column(
      children: [
        _buildSeatItem(1, true, false),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSeatItem(2, false, true),
            _buildSeatItem(3, false, true),
            _buildSeatItem(4, false, true),
            _buildSeatItem(5, false, true),
            _buildSeatItem(6, false, true),
            _buildSeatItem(7, false, false),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (i) => _buildSeatItem(i + 8, false, false)),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (i) => _buildSeatItem(i + 14, false, false)),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (i) => _buildSeatItem(i + 20, false, false)),
        ),
      ],
    );
  }

  Widget _buildSeatItem(int seatNumber, bool isHost, bool hasCrown) {
    return GestureDetector(
      onTap: () {
        if (onSeatTap != null) {
          onSeatTap!(seatNumber);
        }
      },
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
