import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../services/user_service.dart';

class RoomSettingsSheet extends StatefulWidget {
  final String roomId;
  final String hostId;

  const RoomSettingsSheet({
    Key? key,
    required this.roomId,
    required this.hostId,
  }) : super(key: key);

  static Future<void> show(BuildContext context, {required String roomId, required String hostId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RoomSettingsSheet(roomId: roomId, hostId: hostId),
    );
  }

  @override
  State<RoomSettingsSheet> createState() => _RoomSettingsSheetState();
}

class _RoomSettingsSheetState extends State<RoomSettingsSheet> {
  String roomTitle = 'KEDIR';
  String roomDescription = 'ኑ አብረን እንደግ እንበልጽግ...';
  String roomType = 'Chatting';
  String joinPermission = 'Everyone Can Join';
  int seatCount = 25;
  String micMode = 'Free mic';
  String? coverUrl;

  final ImagePicker _picker = ImagePicker();

  // 1. Cover Upload
  Future<void> _pickAndUploadCover() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    var req = http.MultipartRequest('POST', Uri.parse(UserService.serverUrl + '/api/room-cover/upload'));
    req.fields['roomId'] = widget.roomId;
    req.fields['hostId'] = widget.hostId;
    req.files.add(await http.MultipartFile.fromPath('coverImage', image.path));

    var res = await req.send();
    var resp = await http.Response.fromStream(res);
    var data = jsonDecode(resp.body);

    if (data['success'] == true) {
      setState(() => coverUrl = data['coverUrl']);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('የክፍሉ ምስል ተቀይሯል!')));
    }
  }

  // 2. Room Name Dialog
  void _editRoomName() {
    TextEditingController controller = TextEditingController(text: roomTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Room Name'),
        content: TextField(controller: controller, maxLength: 30),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(ctx);
              final res = await http.post(
                Uri.parse(UserService.serverUrl + '/api/room-name/update'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'roomId': widget.roomId, 'title': newName, 'hostId': widget.hostId}),
              );
              if (jsonDecode(res.body)['success'] == true) {
                setState(() => roomTitle = newName);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  // 3. Room Description Dialog
  void _editRoomDescription() {
    TextEditingController controller = TextEditingController(text: roomDescription);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Room Description'),
        content: TextField(controller: controller, maxLength: 100, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newDesc = controller.text.trim();
              Navigator.pop(ctx);
              final res = await http.post(
                Uri.parse(UserService.serverUrl + '/api/room-description/update'),

headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'roomId': widget.roomId, 'description': newDesc, 'hostId': widget.hostId}),
              );
              if (jsonDecode(res.body)['success'] == true) {
                setState(() => roomDescription = newDesc);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  // 4. Room Type Selector
  void _selectRoomType() {
    final types = ['Emotion', 'Chatting', 'Music', 'Friends', 'Fitness', 'Lifestyle', 'Fashion'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        itemCount: types.length,
        itemBuilder: (ctx, i) => ListTile(
          title: Text(types[i]),
          onTap: () async {
            Navigator.pop(ctx);
            final res = await http.post(
              Uri.parse(UserService.serverUrl + '/api/room-type/update'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'roomId': widget.roomId, 'roomType': types[i], 'hostId': widget.hostId}),
            );
            if (jsonDecode(res.body)['success'] == true) {
              setState(() => roomType = types[i]);
            }
          },
        ),
      ),
    );
  }

  // 5. Mic Seats Selector
  void _selectSeats() {
    final seatOptions = [9, 16, 20, 24, 25, 30];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        itemCount: seatOptions.length,
        itemBuilder: (ctx, i) => ListTile(
          title: Text('${seatOptions[i]} Seats'),
          onTap: () async {
            Navigator.pop(ctx);
            final res = await http.post(
              Uri.parse(UserService.serverUrl + '/api/room-seats/update'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'roomId': widget.roomId, 'seatCount': seatOptions[i], 'hostId': widget.hostId}),
            );
            if (jsonDecode(res.body)['success'] == true) {
              setState(() => seatCount = seatOptions[i]);
            }
          },
        ),
      ),
    );
  }

  // 6. Mic Mode Selector
  void _selectMicMode() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Free mic'),
            onTap: () => _updateMicMode('free', 'Free mic', ctx),
          ),
          ListTile(
            title: const Text('Apply for Mic'),
            onTap: () => _updateMicMode('apply', 'Apply for Mic', ctx),
          ),
        ],
      ),
    );
  }

  Future<void> _updateMicMode(String mode, String label, BuildContext ctx) async {
    Navigator.pop(ctx);
    final res = await http.post(
      Uri.parse(UserService.serverUrl + '/api/room-mic-mode/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'roomId': widget.roomId, 'micMode': mode, 'hostId': widget.hostId}),
    );
    if (jsonDecode(res.body)['success'] == true) {
      setState(() => micMode = label);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          AppBar(
            title: const Text('Room Settings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.pop(context),

),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCard([
                  _buildItem('Room Cover', onTap: _pickAndUploadCover, trailing: coverUrl != null 
                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(UserService.serverUrl + coverUrl!, width: 40, height: 40, fit: BoxFit.cover))
                    : const Icon(Icons.image, color: Colors.amber)),
                ]),
                const SizedBox(height: 12),
                _buildCard([
                  _buildItem('Room ID', value: widget.roomId),
                  _buildDivider(),
                  _buildItem('Room Name', value: roomTitle, onTap: _editRoomName),
                  _buildDivider(),
                  _buildItem('Room Description', value: roomDescription, onTap: _editRoomDescription),
                  _buildDivider(),
                  _buildItem('Room Type', badge: roomType, onTap: _selectRoomType),
                  _buildDivider(),
                  _buildItem('Room Background', onTap: () {}),
                  _buildDivider(),
                  _buildItem('Join Permissions', value: joinPermission, onTap: () {}),
                ]),
                const SizedBox(height: 12),
                _buildCard([
                  _buildItem('Mic Seats', value: '$seatCount', onTap: _selectSeats),
                  _buildDivider(),
                  _buildItem('Mic Mode', value: micMode, onTap: _selectMicMode),
                ]),
                const SizedBox(height: 12),
                _buildCard([
                  _buildItem('Room Blacklist & Kick Out', onTap: () {}),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEEEEE));

  Widget _buildItem(String title, {String? value, String? badge, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.purple.shade400, borderRadius: BorderRadius.circular(12)),
              child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 12)),
            )
          else if (value != null)
            Text(value, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          if (trailing != null) trailing,
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}
