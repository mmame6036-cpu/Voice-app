import 'package:flutter/material.dart';

class RoomSettingsData {
  String roomName;
  String roomDescription;
  int seatCount;
  String? password;
  bool isRoomAudioMuted;
  bool isAllMicClosed;
  List<String> admins;
  List<String> blacklistedUsers;

  RoomSettingsData({
    required this.roomName,
    required this.roomDescription,
    this.seatCount = 25,
    this.password,
    this.isRoomAudioMuted = false,
    this.isAllMicClosed = false,
    List<String>? admins,
    List<String>? blacklistedUsers,
  })  : admins = admins ?? [],
        blacklistedUsers = blacklistedUsers ?? [];
}

class BasicToolsSheet extends StatelessWidget {
  final RoomSettingsData settings;
  final VoidCallback onToggleRoomVoice;
  final VoidCallback onToggleAllMic;
  final VoidCallback onOpenPasswordDialog;
  final VoidCallback onOpenAdminSheet;
  final VoidCallback onOpenRoomSettings;

  const BasicToolsSheet({
    super.key,
    required this.settings,
    required this.onToggleRoomVoice,
    required this.onToggleAllMic,
    required this.onOpenPasswordDialog,
    required this.onOpenAdminSheet,
    required this.onOpenRoomSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF141226),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Basic Tools",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _toolItem(
                icon: settings.isRoomAudioMuted ? Icons.volume_off : Icons.volume_up,
                label: settings.isRoomAudioMuted ? "Voice Off" : "Voice On",
                color: settings.isRoomAudioMuted ? Colors.redAccent : Colors.cyanAccent,
                onTap: () {
                  Navigator.pop(context);
                  onToggleRoomVoice();
                },
              ),
              _toolItem(
                icon: Icons.share,
                label: "Share",
                color: Colors.white,
                onTap: () => Navigator.pop(context),
              ),
              _toolItem(
                icon: Icons.music_note,
                label: "Music",
                color: Colors.white,
                onTap: () => Navigator.pop(context),
              ),
              _toolItem(
                icon: Icons.settings,
                label: "Room Settings",
                color: const Color(0xFFFFD700),
                onTap: () {
                  Navigator.pop(context);
                  onOpenRoomSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _toolItem(
                icon: Icons.group,
                label: "Room Admin",
                color: Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  onOpenAdminSheet();
                },
              ),
              _toolItem(
                icon: settings.password != null ? Icons.lock : Icons.lock_open,
                label: settings.password != null ? "Change Pass" : "Set Password",

color: settings.password != null ? const Color(0xFFFFD700) : Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  onOpenPasswordDialog();
                },
              ),
              _toolItem(
                icon: Icons.mic,
                label: "Open all mic",
                color: Colors.greenAccent,
                onTap: () {
                  Navigator.pop(context);
                  if (settings.isAllMicClosed) onToggleAllMic();
                },
              ),
              _toolItem(
                icon: Icons.mic_off,
                label: "Close all mic",
                color: Colors.redAccent,
                onTap: () {
                  Navigator.pop(context);
                  if (!settings.isAllMicClosed) onToggleAllMic();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _toolItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class RoomSettingsScreen extends StatefulWidget {
  final RoomSettingsData settings;
  final Function(RoomSettingsData) onUpdateSettings;
  final List<String?> currentSeats;
  final Function(int) onKickSeat;

  const RoomSettingsScreen({
    super.key,
    required this.settings,
    required this.onUpdateSettings,
    required this.currentSeats,
    required this.onKickSeat,
  });

  @override
  State<RoomSettingsScreen> createState() => _RoomSettingsScreenState();
}

class _RoomSettingsScreenState extends State<RoomSettingsScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late int _seatCount;

  final List<int> allowedLayouts = [8, 12, 16, 20, 25, 30];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.settings.roomName);
    _descController = TextEditingController(text: widget.settings.roomDescription);
    _seatCount = widget.settings.seatCount;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    widget.settings.roomName = _titleController.text.trim();
    widget.settings.roomDescription = _descController.text.trim();
    widget.settings.seatCount = _seatCount;
    widget.onUpdateSettings(widget.settings);
    Navigator.pop(context);
  }

  void _openSeatsPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141226),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Mic Seats",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: allowedLayouts.map((count) {
                final isSelected = _seatCount == count;

return ChoiceChip(
                  label: Text("$count Seats"),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFFD700),
                  backgroundColor: const Color(0xFF221F3A),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) {
                    setState(() => _seatCount = count);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openKickOutDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141226),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Kick User Out of Seat",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: widget.currentSeats.length,
                itemBuilder: (context, index) {
                  final user = widget.currentSeats[index];
                  if (user == null) return const SizedBox.shrink();
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF2A224E),
                      child: Icon(Icons.person, color: Color(0xFFFFD700)),
                    ),
                    title: Text(user, style: const TextStyle(color: Colors.white)),
                    subtitle: Text("Seat ${index == 0 ? 'Host' : index}", style: const TextStyle(color: Colors.white54)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () {
                        widget.onKickSeat(index);
                        Navigator.pop(context);
                      },
                      child: const Text("Kick", style: TextStyle(color: Colors.white)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Room Settings",
          style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text("Save", style: TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(

labelText: "Room Name",
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: "Room Description",
                    border: UnderlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  title: const Text("Mic Seats"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("$_seatCount", style: const TextStyle(color: Colors.black54, fontSize: 15)),
                      const Icon(Icons.chevron_right, color: Colors.black38),
                    ],
                  ),
                  onTap: _openSeatsPicker,
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text("Room Blacklist & Kick Out"),
                  trailing: const Icon(Icons.chevron_right, color: Colors.black38),
                  onTap: _openKickOutDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
