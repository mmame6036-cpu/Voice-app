class AmbientParticlesPainter extends CustomPainter {
  final double progress;
  AmbientParticlesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42);

    for (int i = 0; i < 18; i++) {
      final double baseX = random.nextDouble() * size.width;
      final double speed = 0.3 + (random.nextDouble() * 0.7);
      final double yOffset = (progress * size.height * speed + (i * 45)) % size.height;
      final double currentY = size.height - yOffset;
      final double radius = 2.0 + (random.nextDouble() * 3.5);
      final double opacity = 0.15 + (0.35 * math.sin((progress * 2 * math.pi) + i).abs());

      final colorList = [
        const Color(0xFF00E5FF),
        const Color(0xFFD500F9),
        const Color(0xFFFFD700),
      ];
      final color = colorList[i % colorList.length].withOpacity(opacity);

      paint.color = color;
      canvas.drawCircle(Offset(baseX, currentY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AmbientParticlesPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'main.dart';

class RoomChairsGrid extends StatefulWidget {
  final IO.Socket? socket;
  final String roomId;
  final Map<int, String> occupiedChairs;
  final Map<int, bool> speakingUsers;
  final Function(int chairNum)? onChairTap;

  const RoomChairsGrid({
    Key? key,
    required this.socket,
    this.roomId = '1001',
    required this.occupiedChairs,
    required this.speakingUsers,
    this.onChairTap,
  }) : super(key: key);

  @override
  State<RoomChairsGrid> createState() => _RoomChairsGridState();
}

class _RoomChairsGridState extends State<RoomChairsGrid> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _handleSeatTap(int chairNum) {
    final occupant = widget.occupiedChairs[chairNum];
    final isMe = occupant == AppData.currentUserName;

    if (occupant != null && !isMe) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ወንበር #$chairNum በ $occupant ተይዟል!'),
          duration: const Duration(milliseconds: 800),
        ),
      );
      return;
    }

    if (widget.onChairTap != null) widget.onChairTap!(chairNum);

    // ክፍሉን እና የተጠቃሚውን መረጃ ሙሉ በሙሉ መላክ
    widget.socket?.emit('chair_action', {
      'room': widget.roomId,
      'chairNum': chairNum,
      'userName': AppData.currentUserName,
      'action': isMe ? 'leave' : 'join',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 20,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          final chairNum = index + 1;
          final occupant = widget.occupiedChairs[chairNum];
          final isOccupied = occupant != null;
          final isSpeaking = widget.speakingUsers[chairNum] ?? false;

          return GestureDetector(
            onTap: () => _handleSeatTap(chairNum),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    final scale = isSpeaking ? _scaleAnimation.value : 1.0;
                    final glow = isSpeaking ? (0.3 + (_waveController.value * 0.7)) : 0.0;

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOccupied ? Colors.teal.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                          border: Border.all(
                            color: isSpeaking
                                ? Colors.greenAccent.withOpacity(glow)
                                : (isOccupied ? Colors.tealAccent : Colors.white24),

width: isSpeaking ? 2.5 : 1.2,
                          ),
                          boxShadow: isSpeaking
                              ? [
                                  BoxShadow(
                                    color: Colors.greenAccent.withOpacity(glow * 0.6),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ]
                              : [],
                        ),
                        child: Center(
                          child: isOccupied
                              ? Text(
                                  occupant.isNotEmpty ? occupant[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                )
                              : Icon(
                                  Icons.chair_rounded,
                                  size: 20,
                                  color: Colors.white.withOpacity(0.35),
                                ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  isOccupied ? occupant : '$chairNum',
                  style: TextStyle(
                    color: isOccupied ? Colors.tealAccent : Colors.white38,
                    fontSize: 10,
                    fontWeight: isOccupied ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
