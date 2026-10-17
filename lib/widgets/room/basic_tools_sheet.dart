import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../services/user_service.dart';

class BasicToolsSheet extends StatelessWidget {
  final Function(int updatedSeats)? onSeatsChanged;
  final int currentSeats;
  final String roomId;
  final String hostId;

  const BasicToolsSheet({
    Key? key,
    this.onSeatsChanged,
    this.currentSeats = 25,
    this.roomId = '1001',
    this.hostId = '1000',
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    int currentSeats = 25,
    String roomId = '1001',
    String hostId = '1000',
    Function(int updatedSeats)? onSeatsChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BasicToolsSheet(
        currentSeats: currentSeats,
        roomId: roomId,
        hostId: hostId,
        onSeatsChanged: onSeatsChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: const BoxDecoration(
        color: Color(0xFF16171E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Basic Tools',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildToolIcon(Icons.volume_up, 'Voice On', () {}),
              _buildToolIcon(Icons.send_rounded, 'Share', () {}),
              _buildToolIcon(Icons.music_note, 'music', () {}),
              _buildToolIcon(Icons.settings, 'Room Settings', () async {
                Navigator.pop(context);
                final res = await Navigator.push<int>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoomSettingsScreen(
                      currentSeats: currentSeats,
                      roomId: roomId,
                      hostId: hostId,
                    ),
                  ),
                );
                if (res != null) {
                  onSeatsChanged?.call(res);
                }
              }),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildToolIcon(Icons.manage_accounts, 'Room Admin', () {}),
              _buildToolIcon(Icons.lock_outline, 'Set Password', () {}),
              _buildToolIcon(Icons.mic, 'Open all mic', () {}),
              _buildToolIcon(Icons.mic_off, 'Close all mic', () {}),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const SizedBox(width: 8),
              _buildToolIcon(Icons.redeem, 'Red Packet', () {}, iconColor: Colors.redAccent),
              const Spacer(),
              _buildToolIcon(Icons.checkroom, 'Backpack', () {}),
              const Spacer(),
              _buildToolIcon(Icons.star_outline, 'Effect Setting', () {}),
              const Spacer(flex: 2),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildToolIcon(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,

child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class RoomSettingsScreen extends StatefulWidget {
  final int currentSeats;
  final String roomId;
  final String hostId;

  const RoomSettingsScreen({
    Key? key,
    required this.currentSeats,
    required this.roomId,
    required this.hostId,
  }) : super(key: key);

  @override
  State<RoomSettingsScreen> createState() => _RoomSettingsScreenState();
}

class _RoomSettingsScreenState extends State<RoomSettingsScreen> {
  late int _seats;
  late String _roomId;
  String _title = 'KEDIR';
  String _description = 'ኑ አብረን እንደግ እንበልጽግ...';
  String _roomType = 'Chatting';
  String _background = 'Default';
  String _joinPermission = 'Everyone Can Join';
  String _micMode = 'Free mic';
  String? _coverUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _seats = widget.currentSeats;
    _roomId = widget.roomId;
  }

  // 1. Room Cover Upload
  Future<void> _updateRoomCover() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    try {
      var req = http.MultipartRequest('POST', Uri.parse(UserService.serverUrl + '/api/room-cover/upload'));
      req.fields['roomId'] = _roomId;
      req.fields['hostId'] = widget.hostId;
      req.files.add(await http.MultipartFile.fromPath('coverImage', image.path));

      var streamed = await req.send();
      var res = await http.Response.fromStream(streamed);
      var data = jsonDecode(res.body);

      if (data['success'] == true) {
        setState(() => _coverUrl = data['coverUrl']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('የክፍሉ ምስል በተሳካ ሁኔታ ተቀይሯል!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ስህተት: $e'), backgroundColor: Colors.red));
    }
  }

  // 2. Room ID Info / Copy
  void _showRoomIdDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Room ID'),
        content: Text('የክፍል መለያ ቁጥር (ID): $_roomId'),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _roomId));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room ID ተገልብጧል (Copied)!')));
            },
            child: const Text('Copy ID'),
          ),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('እሺ')),
        ],
      ),
    );
  }

  // 3. Room Name Dialog
  void _editRoomName() {
    TextEditingController controller = TextEditingController(text: _title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Room Name'),
        content: TextField(
          controller: controller,
          maxLength: 30,
          decoration: const InputDecoration(hintText: 'የክፍሉን ስም አስገባ'),
        ),
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
                body: jsonEncode({'roomId': _roomId, 'title': newName, 'hostId': widget.hostId}),
              );

              if (jsonDecode(res.body)['success'] == true) {
                setState(() => _title = newName);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  // 4. Room Description Dialog
  void _editRoomDescription() {
    TextEditingController controller = TextEditingController(text: _description);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Room Description'),
        content: TextField(
          controller: controller,
          maxLength: 100,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'የክፍሉን መግለጫ አስገባ'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newDesc = controller.text.trim();
              Navigator.pop(ctx);

              final res = await http.post(
                Uri.parse(UserService.serverUrl + '/api/room-description/update'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'roomId': _roomId, 'description': newDesc, 'hostId': widget.hostId}),
              );

              if (jsonDecode(res.body)['success'] == true) {
                setState(() => _description = newDesc);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  // 5. Room Type Bottom Sheet
  void _selectRoomType() {
    final types = ['Emotion', 'Chatting', 'Music', 'Friends', 'Fitness', 'Lifestyle', 'Fashion'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ListView.builder(
        shrinkWrap: true,
        itemCount: types.length,
        itemBuilder: (ctx, i) => ListTile(
          title: Text(types[i], style: const TextStyle(fontWeight: FontWeight.w500)),
          trailing: _roomType == types[i] ? const Icon(Icons.check, color: Color(0xFF9B51E0)) : null,
          onTap: () async {
            Navigator.pop(ctx);
            final res = await http.post(
              Uri.parse(UserService.serverUrl + '/api/room-type/update'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'roomId': _roomId, 'roomType': types[i], 'hostId': widget.hostId}),
            );

            if (jsonDecode(res.body)['success'] == true) {
              setState(() => _roomType = types[i]);
            }
          },
        ),
      ),
    );
  }

  // 6. Room Background Bottom Sheet
  void _selectBackground() {
    final themes = ['Default', 'Neon Club', 'Romantic Pink', 'Royal Blue', 'Golden Luxury'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ListView.builder(
        shrinkWrap: true,
        itemCount: themes.length,
        itemBuilder: (ctx, i) => ListTile(
          title: Text(themes[i]),
          trailing: _background == themes[i] ? const Icon(Icons.check, color: Colors.green) : null,
          onTap: () async {
            Navigator.pop(ctx);
            final res = await http.post(
              Uri.parse(UserService.serverUrl + '/api/room-background/update'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'roomId': _roomId, 'backgroundUrl': themes[i], 'hostId': widget.hostId}),
            );

if (jsonDecode(res.body)['success'] == true) {
              setState(() => _background = themes[i]);
            }
          },
        ),
      ),
    );
  }

  // 7. Join Permissions Dialog
  void _selectJoinPermissions() {
    TextEditingController pwdController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Permissions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Everyone Can Join'),
              leading: const Icon(Icons.public),
              onTap: () async {
                Navigator.pop(ctx);
                final res = await http.post(
                  Uri.parse(UserService.serverUrl + '/api/room-permissions/update'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'roomId': _roomId, 'permissionType': 'everyone', 'hostId': widget.hostId}),
                );
                if (jsonDecode(res.body)['success'] == true) {
                  setState(() => _joinPermission = 'Everyone Can Join');
                }
              },
            ),
            const Divider(),
            TextField(
              controller: pwdController,
              decoration: const InputDecoration(hintText: 'የክፍሉን Password አስገባ'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final pwd = pwdController.text.trim();
              if (pwd.isEmpty) return;
              Navigator.pop(ctx);

              final res = await http.post(
                Uri.parse(UserService.serverUrl + '/api/room-permissions/update'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'roomId': _roomId, 'permissionType': 'password', 'password': pwd, 'hostId': widget.hostId}),
              );

              if (jsonDecode(res.body)['success'] == true) {
                setState(() => _joinPermission = 'Password: $pwd');
              }
            },
            child: const Text('Set Password'),
          ),
        ],
      ),
    );
  }

  // 8. Mic Mode Bottom Sheet
  void _selectMicMode() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Free mic'),
            subtitle: const Text('ማንም ሰው ያለፍቃድ ማይክ መያዝ ይችላል'),
            trailing: _micMode == 'Free mic' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () => _applyMicMode('free', 'Free mic', ctx),
          ),
          ListTile(
            title: const Text('Apply for Mic'),
            subtitle: const Text('በሆስት ፍቃድ ብቻ ማይክ መያዝ ይቻላል'),
            trailing: _micMode == 'Apply for Mic' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () => _applyMicMode('apply', 'Apply for Mic', ctx),
          ),
        ],
      ),
    );
  }

  Future<void> _applyMicMode(String mode, String label, BuildContext ctx) async {
    Navigator.pop(ctx);
    final res = await http.post(
      Uri.parse(UserService.serverUrl + '/api/room-mic-mode/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'roomId': _roomId, 'micMode': mode, 'hostId': widget.hostId}),
    );
    if (jsonDecode(res.body)['success'] == true) {
      setState(() => _micMode = label);
    }
  }

  // 9. Blacklist & Kick Out Dialog
  void _showBlacklistDialog() async {
    final res = await http.get(Uri.parse(UserService.serverUrl + '/api/room-blacklist/list?roomId=' + _roomId));
    final data = jsonDecode(res.body);

List blacklist = data['blacklist'] ?? [];
    List kickOutList = data['kickOutList'] ?? [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Room Blacklist & Kick Out'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('የታገዱ ሰዎች ብዛት: ${blacklist.length}'),
              Text('የተባረሩ ሰዎች ብዛት: ${kickOutList.length}'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('እሺ')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _seats);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context, _seats),
          ),
          centerTitle: true,
          title: const Text(
            'Room Settings',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _buildSettingCard(
              children: [
                _buildTile(
                  title: 'Room Cover',
                  onTap: _updateRoomCover,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _coverUrl != null
                            ? Image.network(
                                UserService.serverUrl + _coverUrl!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 44,
                                height: 44,
                                color: Colors.black,
                                child: const Center(
                                  child: Text(
                                    'HAMZA\nFANS',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              children: [
                _buildTile(
                  title: 'Room ID',
                  trailing: Text(_roomId, style: const TextStyle(color: Colors.black54, fontSize: 14)),
                  onTap: _showRoomIdDialog,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(title: 'Room Name', value: _title, showArrow: true, onTap: _editRoomName),

const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(title: 'Room Description', value: _description, showArrow: true, onTap: _editRoomDescription),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(
                  title: 'Room Type',
                  onTap: _selectRoomType,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B51E0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _roomType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(title: 'Room Background', value: _background, showArrow: true, onTap: _selectBackground),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(title: 'Join Permissions', value: _joinPermission, showArrow: true, onTap: _selectJoinPermissions),
              ],
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              children: [
                _buildTile(
                  title: 'Mic Seats',
                  value: '$_seats',
                  showArrow: true,
                  onTap: () async {
                    final sel = await Navigator.push<int>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MicSeatsSelectorScreen(
                          selectedSeats: _seats,
                          roomId: _roomId,
                          hostId: widget.hostId,
                        ),
                      ),
                    );
                    if (sel != null) {
                      setState(() => _seats = sel);
                    }
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(title: 'Mic Mode', value: _micMode, showArrow: true, onTap: _selectMicMode),
              ],
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              children: [
                _buildTile(title: 'Room Blacklist & Kick Out', showArrow: true, onTap: _showBlacklistDialog),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    required String title,
    String? value,
    Widget? trailing,
    bool showArrow = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
      ),
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)

Text(value, style: const TextStyle(fontSize: 13, color: Colors.black45)),
              if (showArrow) ...[
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios, size: 13, color: Colors.black26),
              ],
            ],
          ),
      onTap: onTap,
    );
  }
}

class MicSeatsSelectorScreen extends StatefulWidget {
  final int selectedSeats;
  final String roomId;
  final String hostId;

  const MicSeatsSelectorScreen({
    Key? key,
    required this.selectedSeats,
    required this.roomId,
    required this.hostId,
  }) : super(key: key);

  @override
  State<MicSeatsSelectorScreen> createState() => _MicSeatsSelectorScreenState();
}

class _MicSeatsSelectorScreenState extends State<MicSeatsSelectorScreen> {
  late int _chosen;
  final List<int> _seatOptions = [9, 16, 20, 24, 25, 30];

  @override
  void initState() {
    super.initState();
    _chosen = widget.selectedSeats;
  }

  Future<void> _saveSeats() async {
    try {
      final res = await http.post(
        Uri.parse(UserService.serverUrl + '/api/room-seats/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'roomId': widget.roomId, 'seatCount': _chosen, 'hostId': widget.hostId}),
      );

      if (jsonDecode(res.body)['success'] == true) {
        Navigator.pop(context, _chosen);
      }
    } catch (e) {
      Navigator.pop(context, _chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Mic Seats',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _seatOptions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (ctx, idx) {
                final count = _seatOptions[idx];
                final isSelected = _chosen == count;
                return GestureDetector(
                  onTap: () => setState(() => _chosen = count),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E212B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00C9A7) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_seat, color: Colors.white70, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            '$count Seats',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],

),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C9A7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: _saveSeats,
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
