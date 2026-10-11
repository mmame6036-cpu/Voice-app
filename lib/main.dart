import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/user_service.dart';
import 'room_screen.dart';
import 'messages_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserService().initializeUser();
  runApp(const NileVoiceApp());
}

class NileVoiceApp extends StatelessWidget {
  const NileVoiceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nile Voice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F141C),
        primaryColor: const Color(0xFF00C9A7),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF161B26),
        selectedItemColor: const Color(0xFF00C9A7),
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.headset),
            label: 'Rooms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _user = UserService();
  List<dynamic> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    try {
      final response = await http.get(
        Uri.parse('https://voice-app-2-jd95.onrender.com/api/rooms'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _rooms = data['rooms'] ?? [];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Fetch rooms error: $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSearchRoomDialog() {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.search, color: Color(0xFF00C9A7)),
              SizedBox(width: 8),
              Text('Search Room by ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: TextField(
            controller: searchController,
            keyboardType: TextInputType.text,
            style: const TextStyle(color: Colors.white),

decoration: InputDecoration(
              hintText: 'Enter Room ID (e.g. 1001)',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9A7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final targetId = searchController.text.trim();
                Navigator.pop(context);
                if (targetId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoomScreen(
                        roomId: targetId,
                        roomTitle: "Room $targetId",
                        hostName: "Host",
                      ),
                    ),
                  );
                }
              },
              child: const Text('Join Room', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openMyPersonalRoom() async {
    try {
      await http.post(
        Uri.parse('https://voice-app-2-jd95.onrender.com/api/rooms/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'roomId': _user.userId,
          'title': "${_user.userName}'s Room",
          'category': 'Party',
          'hostId': _user.userId,
          'hostName': _user.userName,
        }),
      );
    } catch (_) {}

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomScreen(
          roomId: _user.userId,
          roomTitle: "${_user.userName}'s Room",
          hostName: _user.userName,
        ),
      ),
    ).then((_) => _fetchRooms());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        title: const Text('Live Audio Rooms', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF00C9A7), size: 26),
            tooltip: 'Search Room by ID',
            onPressed: _showSearchRoomDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchRooms();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text('${_user.coins}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00C9A7),
        elevation: 6,
        onPressed: _openMyPersonalRoom,
        child: const Icon(Icons.mic, color: Colors.black, size: 30),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRooms,
        color: const Color(0xFF00C9A7),

child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF5C248B), Color(0xFF1F104F)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.amber, size: 36),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, ${_user.userName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Your ID: ${_user.userId}', style: const TextStyle(color: Color(0xFF00C9A7), fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showSearchRoomDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.white38, size: 20),
                    SizedBox(width: 10),
                    Text('Search room by ID...', style: TextStyle(color: Colors.white38, fontSize: 14)),
                    Spacer(),
                    Text('Search', style: TextStyle(color: Color(0xFF00C9A7), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _openMyPersonalRoom,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: borderGradient(),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF00C9A7).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF00C9A7),
                      child: Icon(Icons.mic, color: Colors.black),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Enter My Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF00C9A7))),
                          const SizedBox(height: 4),
                          Text('Room ID: ${_user.userId} • Tap to enter', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Color(0xFF00C9A7), size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Explore Rooms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildRoomCard(
              roomId: '1001',
              title: 'Global Chat Lounge',
              host: 'Master Host',

),
            const SizedBox(height: 10),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
                ),
              )
            else if (_rooms.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('No other active rooms right now.', style: TextStyle(color: Colors.white38, fontSize: 13)),
                ),
              )
            else
              ..._rooms.map((room) {
                final rId = room['roomId'].toString();
                if (rId == '1001' || rId == _user.userId) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildRoomCard(
                    roomId: rId,
                    title: room['title'] ?? 'Party Room',
                    host: room['hostName'] ?? 'Host',
                  ),
                );
              }).toList(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  LinearGradient borderGradient() {
    return LinearGradient(
      colors: [const Color(0xFF00C9A7).withOpacity(0.18), const Color(0xFF161B26)],
    );
  }

  Widget _buildRoomCard({required String roomId, required String title, required String host}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoomScreen(
              roomId: roomId,
              roomTitle: title,
              hostName: host,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF00C9A7),
              child: Icon(Icons.headset, color: Colors.black),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('Room ID: $roomId • Host: $host', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _user = UserService();

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    await _user.initializeUser();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshProfile,
          color: const Color(0xFF00C9A7),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),

child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFF00C9A7),
                      child: Text(
                        _user.userName.isNotEmpty ? _user.userName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user.userName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B26),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              'ID: ${_user.userId}',
                              style: const TextStyle(color: Color(0xFF00C9A7), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E2415), Color(0xFF161B26)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('VIP Club', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Upgrade to VIP and get free daily coins', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,

),
                        onPressed: () {},
                        child: const Text('Get VIP', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B26),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Coins', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_user.coins}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.amber,
                              child: Icon(Icons.monetization_on, color: Colors.black, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B26),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Points', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                  SizedBox(height: 6),
                                  Text(
                                    '0',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(0xFF9C27B0),
                              child: Icon(Icons.diamond, color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(

color: const Color(0xFF161B26),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionItem(icon: Icons.mic_external_on, label: 'Host Center'),
                      _buildActionItem(icon: Icons.groups_outlined, label: 'Agency'),
                      _buildActionItem(icon: Icons.storefront_outlined, label: 'Coin Seller'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B26),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 10,
                    children: [
                      _buildGridMenuItem(icon: Icons.task_alt, label: 'Task'),
                      _buildGridMenuItem(icon: Icons.person_add_alt, label: 'Invite'),
                      _buildGridMenuItem(icon: Icons.shopping_bag_outlined, label: 'Store'),
                      _buildGridMenuItem(icon: Icons.backpack_outlined, label: 'Backpack'),
                      _buildGridMenuItem(icon: Icons.military_tech_outlined, label: 'Level'),
                      _buildGridMenuItem(icon: Icons.shield_outlined, label: 'Medal Wall'),
                      _buildGridMenuItem(icon: Icons.headset_mic_outlined, label: 'Support'),
                      _buildGridMenuItem(icon: Icons.tune, label: 'Settings'),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String label}) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00C9A7), size: 26),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildGridMenuItem({required IconData icon, required String label}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white60),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
