import 'package:flutter/material.dart';

class RoomBottomBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isMicMuted;
  final VoidCallback onSendMessage;
  final VoidCallback onToggleMic;
  final VoidCallback onOpenGifts;
  final VoidCallback onOpenTools;
  final VoidCallback? onOpenGame;

  const RoomBottomBar({
    Key? key,
    required this.controller,
    required this.isMicMuted,
    required this.onSendMessage,
    required this.onToggleMic,
    required this.onOpenGifts,
    required this.onOpenTools,
    this.onOpenGame,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Say Hello',
                        hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => onSendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onOpenGame,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.85),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_esports, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onOpenGifts,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.card_giftcard, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onToggleMic,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isMicMuted
                    ? Colors.black.withOpacity(0.45)
                    : const Color(0xFF00FFD5).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isMicMuted ? Colors.white24 : const Color(0xFF00FFD5),
                  width: 1,
                ),
              ),
              child: Icon(

isMicMuted ? Icons.mic_off : Icons.mic,
                color: isMicMuted ? Colors.white54 : const Color(0xFF00FFD5),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onOpenTools,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
              child: const Icon(Icons.apps, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
