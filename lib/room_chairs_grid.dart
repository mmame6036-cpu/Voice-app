import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'main.dart';

class RoomChairsGrid extends StatefulWidget {
  final IO.Socket? socket;
  final Function(int)? onChairTap;
  final Map<int, String> occupiedChairs;
  final Map<int, bool> speakingUsers;

  const RoomChairsGrid({
    Key? key,
    this.socket,
    this.onChairTap,
    this.occupiedChairs = const {},
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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 20 የታመቁና የተጣበቡ ወንበሮች (5 አምዶች x 4 ረድፎች)
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.82,
      ),
      itemCount: 20,
      itemBuilder: (context, index) {
        final chairNum = index + 1;
        final occupantName = widget.occupiedChairs[chairNum];
        final bool isOccupied = occupantName != null && occupantName.isNotEmpty;
        final bool isMe = isOccupied && occupantName == AppData.currentUserName;
        final bool isSpeaking = widget.speakingUsers[chairNum] ?? false;

        return GestureDetector(
          onTap: () {
            // ሌላ ሰው የያዘውን ወንበር እንዳይነካ መከልከል
            if (isOccupied && !isMe) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ ወንበር #$chairNum በ $occupantName ተይዟል!'),
                  duration: const Duration(milliseconds: 800),
                ),
              );
              return;
            }

            if (widget.onChairTap != null) widget.onChairTap!(chairNum);

            // ወንበር መያዝ ወይም መልቀቅ
            widget.socket?.emit('chair_action', {
              'room':  '1001',
              'chairNum': chairNum,
              'userName': AppData.currentUserName,
              'action': isMe ? 'leave' : 'join',
            });
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  final scale = isSpeaking ? _scaleAnimation.value : 1.0;
                  final glow = isSpeaking ? (0.3 + (_waveController.value * 0.5)) : 0.0;

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: isSpeaking
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF00E676).withOpacity(glow),
                                  blurRadius: 10 + (_waveController.value * 6),
                                  spreadRadius: 2 + (_waveController.value * 3),

)
                              ]
                            : [],
                        border: Border.all(
                          color: isSpeaking
                              ? const Color(0xFF00E676)
                              : (isMe
                                  ? const Color(0xFFFFD700)
                                  : (isOccupied ? Colors.tealAccent : Colors.white12)),
                          width: isSpeaking ? 2.5 : 1.5,
                        ),
                        color: isOccupied
                            ? (isMe ? const Color(0xFF00897B) : const Color(0xFF1E293B))
                            : Colors.white.withOpacity(0.04),
                      ),
                      child: Center(
                        child: isOccupied
                            ? Text(
                                occupantName.isNotEmpty ? occupantName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              )
                            : const Icon(Icons.chair_rounded, color: Colors.white30, size: 20),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 3),
              Text(
                isOccupied ? occupantName : '$chairNum',
                style: TextStyle(
                  color: isSpeaking
                      ? const Color(0xFF00E676)
                      : (isOccupied ? Colors.white : Colors.white38),
                  fontSize: 9,
                  fontWeight: isOccupied ? FontWeight.bold : FontWeight.normal,
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
