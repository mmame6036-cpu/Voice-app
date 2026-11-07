import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomSettingsScreen extends StatefulWidget {
  final String roomId;
  final String currentRoomTitle;

  const RoomSettingsScreen({
    super.key,
    required this.roomId,
    required this.currentRoomTitle,
  });

  @override
  State<RoomSettingsScreen> createState() => _RoomSettingsScreenState();
}

class _RoomSettingsScreenState extends State<RoomSettingsScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _passwordController;
  String _roomType = "Public";
  int _seatsCount = 30;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentRoomTitle);
    _descController = TextEditingController();
    _passwordController = TextEditingController();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _titleController.text = data['title'] ?? widget.currentRoomTitle;
          _descController.text = data['description'] ?? "";
          _passwordController.text = data['password'] ?? "";
          _roomType = data['type'] ?? "Public";
          _seatsCount = (data['totalSeats'] as num?)?.toInt() ?? 30;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).set({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'password': _passwordController.text.trim(),
        'type': _roomType,
        'totalSeats': _seatsCount,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Settings updated successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBlacklistDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1638),
        title: const Text("Room Blacklist & Kick Out", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
            final List banned = (data['bannedUsers'] as List?) ?? [];

            if (banned.isEmpty) {
              return const Text("No users on the blacklist.", style: TextStyle(color: Colors.white54, fontSize: 13));
            }

            return SizedBox(
              width: double.maxFinite,
              height: 200,
              child: ListView.builder(
                itemCount: banned.length,
                itemBuilder: (ctx, idx) {
                  final user = banned[idx].toString();
                  return ListTile(
                    dense: true,
                    title: Text(user, style: const TextStyle(color: Colors.white)),

trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
                          'bannedUsers': FieldValue.arrayRemove([user]),
                        });
                      },
                    ),
                  );
                },
              ),
            );
          },
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
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18122B),
        elevation: 0,
        title: const Text("Room Settings", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700)))))
          else
            TextButton(
              onPressed: _saveSettings,
              child: const Text("Save", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 15)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildSectionHeader("BASIC INFO"),
          _buildTile(
            title: "Room ID",
            subtitle: widget.roomId,
            icon: Icons.tag,
            onTap: null,
          ),
          _buildTextFieldTile(
            title: "Room Name",
            controller: _titleController,
            hint: "Enter room title",
            icon: Icons.title,
          ),
          _buildTextFieldTile(
            title: "Room Description",
            controller: _descController,
            hint: "Say something about your room",
            icon: Icons.description_outlined,
          ),
          const SizedBox(height: 16),
          _buildSectionHeader("PERMISSIONS & SECURITY"),
          _buildTile(
            title: "Room Type",
            subtitle: _roomType,
            icon: Icons.category_outlined,
            onTap: () {
              setState(() {
                _roomType = _roomType == "Public" ? "Private" : "Public";
              });
            },
          ),
          _buildTextFieldTile(
            title: "Set Password",
            controller: _passwordController,
            hint: "Leave empty for no password",
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          _buildTile(
            title: "Mic Seats",
            subtitle: "$_seatsCount Seats Layout",
            icon: Icons.event_seat,
            onTap: () {
              final options = [6, 12, 20, 25, 30];
              final currentIdx = options.indexOf(_seatsCount);
              final nextIdx = (currentIdx + 1) % options.length;
              setState(() => _seatsCount = options[nextIdx]);
            },
          ),
          _buildTile(
            title: "Room Blacklist & Kick Out",
            subtitle: "Manage kicked/banned users",
            icon: Icons.block,
            trailingColor: Colors.redAccent,
            onTap: _showBlacklistDialog,
          ),
        ],
      ),
    );
  }

Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(title, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildTile({required String title, required String subtitle, required IconData icon, VoidCallback? onTap, Color? trailingColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1638),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: trailingColor ?? const Color(0xFFFFD700), size: 22),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
        trailing: onTap != null ? Icon(Icons.arrow_forward_ios, color: trailingColor ?? Colors.white38, size: 14) : null,
      ),
    );
  }

  Widget _buildTextFieldTile({required String title, required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1638),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                TextField(
                  controller: controller,
                  obscureText: isPassword,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
