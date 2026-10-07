import 'package:flutter/material.dart';
import 'main.dart';

// በክፍሉ ውስጥ የተቀመጡ ሰዎች
Map<int, String> occupiedChairs = {};

class RoomChairsGrid extends StatelessWidget {
  final dynamic socket;
  final Function(int chairIndex)? onChairTap;

  const RoomChairsGrid({
    Key? key,
    this.socket,
    this.onChairTap,
  }) : super(key: key);

  void _onSeatClick(BuildContext context, int chairNum) {
    final String myName = AppData.currentUserName;

    if (occupiedChairs[chairNum] == myName) {
      occupiedChairs.remove(chairNum);
    } else {
      occupiedChairs.removeWhere((k, v) => v == myName);
      occupiedChairs[chairNum] = myName;
    }

    if (socket != null) {
      socket.emit('chair_action', {
        'chairNum': chairNum,
        'userName': myName,
        'action': occupiedChairs.containsKey(chairNum) ? 'join' : 'leave',
      });
    }

    if (onChairTap != null) onChairTap!(chairNum);
    (context as Element).markNeedsBuild();
  }

  Widget _buildSeat(BuildContext context, int chairNum, {bool isHost = false}) {
    final bool isOccupied = occupiedChairs.containsKey(chairNum);
    final String? occupantName = occupiedChairs[chairNum];
    final double size = isHost ? 64.0 : 42.0;

    return GestureDetector(
      onTap: () => _onSeatClick(context, chairNum),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOccupied ? Colors.amber.withOpacity(0.25) : Colors.black.withOpacity(0.4),
              border: Border.all(
                color: isOccupied ? const Color(0xFFFFD700) : Colors.white24,
                width: isOccupied ? 2.0 : 1.0,
              ),
              boxShadow: isOccupied
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: Center(
              child: isOccupied
                  ? CircleAvatar(
                      radius: (size / 2) - 3,
                      backgroundColor: Colors.teal,
                      child: Text(
                        occupantName != null && occupantName.isNotEmpty ? occupantName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    )
                  : Icon(
                      Icons.weekend_rounded,
                      color: Colors.white60,
                      size: isHost ? 28 : 18,
                    ),
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: size + 10,
            child: Text(
              isOccupied ? occupantName! : '$chairNum',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isOccupied ? const Color(0xFFFFD700) : Colors.white54,
                fontSize: 10,
                fontWeight: isOccupied ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          // ረድፍ 1፦ የሆስት ወንበር (ወንበር 1) እና 2, 3, 4, 5
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildSeat(context, 1, isHost: true),
              for (int i = 2; i <= 5; i++) _buildSeat(context, i),
            ],
          ),
          const SizedBox(height: 14),

// ረድፍ 2፦ 6 እስከ 10
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [for (int i = 6; i <= 10; i++) _buildSeat(context, i)],
          ),
          const SizedBox(height: 14),

          // ረድፍ 3፦ 11 እስከ 15
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [for (int i = 11; i <= 15; i++) _buildSeat(context, i)],
          ),
          const SizedBox(height: 14),

          // ረድፍ 4፦ 16 እስከ 20
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [for (int i = 16; i <= 20; i++) _buildSeat(context, i)],
          ),
          const SizedBox(height: 14),

          // ረድፍ 5፦ 21 እስከ 25
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [for (int i = 21; i <= 25; i++) _buildSeat(context, i)],
          ),
          const SizedBox(height: 14),

          // ረድፍ 6፦ 26 እስከ 30
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [for (int i = 26; i <= 30; i++) _buildSeat(context, i)],
          ),
        ],
      ),
    );
  }
}
