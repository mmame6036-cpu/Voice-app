import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/room_settings_screen.dart';

class RoomToolsSheet extends StatelessWidget {
  final String roomId;
  final String roomTitle;
  final String userName;
  final bool isHost;
  final VoidCallback onToggleVoice;
  final bool isVoiceOn;

  const RoomToolsSheet({
    super.key,
    required this.roomId,
    required this.roomTitle,
    required this.userName,
    required this.isHost,
    required this.onToggleVoice,
    required this.isVoiceOn,
  });

  static void show(
    BuildContext context, {
    required String roomId,
    required String roomTitle,
    required String userName,
    required bool isHost,
    required VoidCallback onToggleVoice,
    required bool isVoiceOn,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => RoomToolsSheet(
        roomId: roomId,
        roomTitle: roomTitle,
        userName: userName,
        isHost: isHost,
        onToggleVoice: onToggleVoice,
        isVoiceOn: isVoiceOn,
      ),
    );
  }

  void _showSetPasswordDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1638),
        title: const Text("Set Room Password", style: TextStyle(color: Colors.white, fontSize: 15)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter 4-digit PIN",
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
            onPressed: () async {
              final pin = controller.text.trim();
              await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
                'password': pin,
              }, SetOptions(merge: true));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Save", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAdminManagementDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1638),
        title: const Text("Room Admins", style: TextStyle(color: Colors.white, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Add Admin Username",
                hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
              onPressed: () async {
                final target = controller.text.trim();
                if (target.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
                    'admins': FieldValue.arrayUnion([target]),
                  }, SetOptions(merge: true));

controller.clear();
                }
              },
              child: const Text("Add Admin", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF130F26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.only(top: 14, bottom: 24, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Basic Tools",
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 10,
            children: [
              _buildToolItem(
                icon: isVoiceOn ? Icons.volume_up : Icons.volume_off,
                label: isVoiceOn ? "Voice On" : "Voice Off",
                iconColor: isVoiceOn ? const Color(0xFF00E5FF) : Colors.white54,
                onTap: () {
                  onToggleVoice();
                  Navigator.pop(context);
                },
              ),
              _buildToolItem(
                icon: Icons.send_outlined,
                label: "Share",
                iconColor: Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Share link for room $roomId copied!")),
                  );
                },
              ),
              _buildToolItem(
                icon: Icons.music_note,
                label: "Music",
                iconColor: const Color(0xFFFF4081),
                onTap: () => Navigator.pop(context),
              ),
              _buildToolItem(
                icon: Icons.settings,
                label: "Room Settings",
                iconColor: const Color(0xFFFFD700),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => RoomSettingsScreen(
                        roomId: roomId,
                        currentRoomTitle: roomTitle,
                      ),
                    ),
                  );
                },
              ),
              _buildToolItem(
                icon: Icons.people_outline,
                label: "Room Admin",
                iconColor: const Color(0xFF00E5FF),
                onTap: () {
                  Navigator.pop(context);
                  _showAdminManagementDialog(context);
                },
              ),
              _buildToolItem(
                icon: Icons.lock_outline,
                label: "Set Password",
                iconColor: const Color(0xFFFFD700),
                onTap: () {
                  Navigator.pop(context);
                  _showSetPasswordDialog(context);
                },
              ),
              _buildToolItem(

icon: Icons.mic,
                label: "Open all mic",
                iconColor: const Color(0xFF00E676),
                onTap: () => Navigator.pop(context),
              ),
              _buildToolItem(
                icon: Icons.mic_off,
                label: "Close all mic",
                iconColor: Colors.redAccent,
                onTap: () => Navigator.pop(context),
              ),
              _buildToolItem(
                icon: Icons.mail_outline,
                label: "Red Packet",
                iconColor: Colors.redAccent,
                onTap: () => Navigator.pop(context),
              ),
              _buildToolItem(
                icon: Icons.work_outline,
                label: "Backpack",
                iconColor: const Color(0xFFFFB300),
                onTap: () => Navigator.pop(context),
              ),
              _buildToolItem(
                icon: Icons.auto_awesome,
                label: "Effect Setting",
                iconColor: const Color(0xFFE040FB),
                onTap: () => Navigator.pop(context),
              ),
              _buildToolItem(
                icon: Icons.sports_mma,
                label: "PK",
                iconColor: const Color(0xFF2979FF),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
