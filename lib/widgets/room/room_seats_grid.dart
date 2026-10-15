import 'package:flutter/material.dart';

class RoomSeatsGrid extends StatelessWidget {
  final int seatCount;
  final Function(int seatIndex)? onSeatTap;

  const RoomSeatsGrid({
    Key? key,
    int? seats,
    int? seatCount,
    this.onSeatTap,
  })  : seatCount = seats ?? seatCount ?? 25,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (seatCount == 25) {
      return _build25SeatsLayout();
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: seatCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: seatCount <= 16 ? 4 : 5,
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
      onTap:
