import 'package:flutter/material.dart';

class BasicToolsSheet extends StatelessWidget {
  final Function(int updatedSeats)? onSeatsChanged;
  final int currentSeats;

  const BasicToolsSheet({
    Key? key,
    this.onSeatsChanged,
    this.currentSeats = 25,
  }) : super(key: key);

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
          const Text('Basic Tools', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),

          // Row 1
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
                  MaterialPageRoute(builder: (_) => RoomSettingsScreen(currentSeats: currentSeats)),
                );
                if (res != null) {
                  onSeatsChanged?.call(res);
                }
              }),
            ],
          ),
          const SizedBox(height: 18),

          // Row 2
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

          // Row 3
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

  Widget _buildToolIcon(IconData icon, String label, VoidCallback onTap, {Color iconColor = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
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

// ---------------------------------------------------------------------------
// ROOM SETTINGS SCREEN
// ---------------------------------------------------------------------------
class RoomSettingsScreen extends StatefulWidget {
  final int currentSeats;
  const RoomSettingsScreen({Key? key, required this.currentSeats}) : super(key: key);

  @override
  State<RoomSettingsScreen> createState() => _RoomSettingsScreenState();
}

class _RoomSettingsScreenState extends State<RoomSettingsScreen> {
  late int _seats;

  @override
  void initState() {
    super.initState();
    _seats = widget.currentSeats;
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
          title: const Text('Room Settings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17)),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _buildSettingCard(
              children: [
                _buildTile(
                  title: 'Room Cover',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 44,
                          height: 44,
                          color: Colors.black,
                          child: const Center(
                            child: Text('HAMZA\nFANS', textAlign: TextAlign.center, style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold)),
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
                _buildTile(title: 'Room ID', trailing: const Text('505798', style: TextStyle(color: Colors.black54, fontSize: 14))),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(title: 'Room Name', value: 'KEDIR', showArrow: true),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(title: 'Room Description', value: 'ኑ አብረን እንደግ እንበልፅግ ...', showArrow: true),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(
                  title: 'Room Type',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF9B51E0), borderRadius: BorderRadius.circular(12)),
                        child: const Text('Chatting', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(title: 'Room Background', showArrow: true),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(title: 'Join Permissions', value: 'Everyone Can Join', showArrow: true),
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
                      MaterialPageRoute(builder: (_) => MicSeatsSelectorScreen(selectedSeats: _seats)),
                    );
                    if (sel != null) setState(() => _seats = sel);
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(title: 'Mic Mode', value: 'Free mic', showArrow: true),
              ],
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              children: [
                _buildTile(title: 'Room Blacklist & Kick Out', showArrow: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _buildTile({required String title, String? value, Widget? trailing, bool showArrow = false, VoidCallback? onTap}) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null) Text(value, style: const TextStyle(fontSize: 13, color: Colors.black45)),
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

// ---------------------------------------------------------------------------
// MIC SEATS SELECTOR SCREEN
// ---------------------------------------------------------------------------
class MicSeatsSelectorScreen extends StatefulWidget {
  final int selectedSeats;
  const MicSeatsSelectorScreen({Key? key, required this.selectedSeats}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context, _chosen),
        ),
        centerTitle: true,
        title: const Text('Mic Seats', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17)),
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
                      border: Border.all(color: isSelected ? const Color(0xFF00C9A7) : Colors.transparent, width: 2),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_seat, color: Colors.white70, size: 36),
                          const SizedBox(height: 8),
                          Text('$count Seats', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
                onPressed: () => Navigator.pop(context, _chosen),
                child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
