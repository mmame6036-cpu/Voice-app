import 'package:flutter/material.dart';

class RoomBottomBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isMicMuted;
  final bool isSpeakerOn;
  final VoidCallback onSendMessage;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleSpeaker;

  const RoomBottomBar({
    Key? key,
    required this.controller,
    required this.isMicMuted,
    required this.isSpeakerOn,
    required this.onSendMessage,
    required this.onToggleMic,
    required this.onToggleSpeaker,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Say Hello...',
                        hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => onSendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF00FFD5), size: 18),
                    onPressed: onSendMessage,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.black.withOpacity(0.45),
            child: IconButton(
              icon: Icon(
                isMicMuted ? Icons.mic_off : Icons.mic,
                color: isMicMuted ? Colors.redAccent : const Color(0xFF00FFD5),
                size: 20,
              ),
              onPressed: onToggleMic,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.black.withOpacity(0.45),
            child: IconButton(
              icon: Icon(
                isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                color: isSpeakerOn ? const Color(0xFF00FFD5) : Colors.white60,
                size: 20,
              ),
              onPressed: onToggleSpeaker,
            ),
          ),
        ],
      ),
    );
  }
}
