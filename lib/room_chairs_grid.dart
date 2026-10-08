import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'main.dart';

class RoomChairsGrid extends StatefulWidget {
  final IO.Socket? socket;
  final Function(int)? onChairTap;
  final Map<int, bool> speakingUsers;

  const RoomChairsGrid({
    Key? key,
    this.socket,
    this.onChairTap,
    this.speakingUsers = const {},
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
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  @override
  void disposeProfile() {
    _waveController.dispose();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: 30,
      itemBuilder: (context, index) {
        final chairNum = index + 1;
        final isOccupied = AppData.currentUserName.isNotEmpty && chairNum == 1;
        // ማይክ ክፍት ሲሆን ወይም በ speakingUsers ውስጥ ሲበራ
        final bool isSpeaking = (widget.speakingUsers[chairNum] == true) || (isOccupied && widget.speakingUsers[1] != false);

        return GestureDetector(
          onTap: () {
            if (widget.onChairTap != null) widget.onChairTap!(chairNum);
            widget.socket?.emit('chair_action', {
              'chairNum': chairNum,
              'userName': AppData.currentUserName,
              'action': isOccupied ? 'leave' : 'join',
            });
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  final scale = isSpeaking ? _scaleAnimation.value : 1.0;
                  final glowOpacity = isSpeaking ? (0.3 + (_waveController.value * 0.6)) : 0.0;

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: isSpeaking
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF00E676).withOpacity(glowOpacity),
                                  blurRadius: 14 + (_waveController.value * 8),
                                  spreadRadius: 4 + (_waveController.value * 4),
                                ),
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(glowOpacity * 0.7),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                        border: Border.all(
                          color: isSpeaking

? const Color(0xFF00E676)
                              : (isOccupied ? const Color(0xFFFFD700) : Colors.white12),
                          width: isSpeaking ? 2.5 : 1.5,
                        ),
                        color: isOccupied ? const Color(0xFF00897B) : Colors.white.withOpacity(0.04),
                      ),
                      child: Center(
                        child: isOccupied
                            ? const Text(
                                'U',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : const Icon(Icons.chair_rounded, color: Colors.white38, size: 22),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              Text(
                isOccupied ? AppData.currentUserName : '$chairNum',
                style: TextStyle(
                  color: isSpeaking
                      ? const Color(0xFF00E676)
                      : (isOccupied ? const Color(0xFFFFD700) : Colors.white38),
                  fontSize: 10,
                  fontWeight: (isSpeaking || isOccupied) ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
