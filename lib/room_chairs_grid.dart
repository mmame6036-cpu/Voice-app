import 'dart:math' as math;
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
          backgroundColor: Colors.redAccent,
          duration: const Duration(milliseconds: 1000),
        ),
      );
      return;
    }

    // ወዲያውኑ የአካባቢውን ተግባር ያነሳሳል
    if (widget.onChairTap != null) {
      widget.onChairTap!(chairNum);
    }

    // ሶኬት መረጃ ለሰርቨሩ ያስተላልፋል
    if (widget.socket != null && widget.socket!.connected) {
      widget.socket!.emit('chair_action', {
        'room': widget.roomId,
        'chairNum': chairNum,
        'userName': AppData.currentUserName,
        'action': isMe ? 'leave' : 'join',
      });
    } else {
      // ሶኬት ባይገናኝም እንኳን በራሱ ሰርቨር ላይ ይሰራል
      widget.socket?.emit('chair_action', {
        'room': widget.roomId,
        'chairNum': chairNum,
        'userName': AppData.currentUserName,
        'action': isMe ? 'leave' : 'join',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8, // ምርጥና ምቹ ባለ 8 ወንበር አቀማመጥ
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 14,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          final chairNum = index + 1;
          final occupant = widget.occupiedChairs[chairNum];
          final isOccupied = occupant != null;
          final isSpeaking = widget.speakingUsers[chairNum] ?? false;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => _handleSeatTap(chairNum),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      final scale = isSpeaking ? _scaleAnimation.value : 1.0;
                      final glow = isSpeaking ? (0.3 + (_waveController.value * 0.7)) : 0.0;

return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOccupied 
                                ? const Color(0xFF00C9A7).withOpacity(0.25) 
                                : Colors.white.withOpacity(0.08),
                            border: Border.all(
                              color: isSpeaking
                                  ? Colors.greenAccent.withOpacity(glow)
                                  : (isOccupied ? const Color(0xFF00C9A7) : Colors.white24),
                              width: isSpeaking ? 2.5 : 1.5,
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
                                      fontSize: 18,
                                    ),
                                  )
                                : Icon(
                                    Icons.chair_rounded,
                                    size: 24,
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isOccupied ? occupant : 'ወንበር $chairNum',
                    style: TextStyle(
                      color: isOccupied ? const Color(0xFF00C9A7) : Colors.white54,
                      fontSize: 11,
                      fontWeight: isOccupied ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
