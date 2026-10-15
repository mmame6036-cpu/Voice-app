import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/user_service.dart';
import 'screens/login_screen.dart';
import 'screens/coin_seller_screen.dart';

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
      debugShowCheckedModeBanner: false,
      title: 'Nile Voice',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0C0D12),
        primaryColor: const Color(0xFFFFD700),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
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
  bool _isLoading = false;
  String _selectedCategory = 'All';
  List<dynamic> _rooms = [];

  final List<String> _categories = const ['All', 'Party', 'Chat', 'Music', 'Gaming'];

  final List<Map<String, dynamic>> _banners = const [
    {
      'title': 'Welcome to Nile Voice',
      'subtitle': 'Explore live voice rooms & party together',
      'icon': Icons.graphic_eq,
      'colors': [Color(0xFF2C2619), Color(0xFF141620)],
    },
    {
      'title': 'VIP Membership',
      'subtitle': 'Get exclusive golden rewards daily',
      'icon': Icons.workspace_premium,
      'colors': [Color(0xFF1A2624), Color(0xFF141620)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  List<dynamic> _getDefaultRooms() {
    return [
      {
        'roomId': '1001',
        'title': 'Global Chat Lounge 🌍',
        'hostName': 'Master Host',
        'usersCount': '12',
      }
    ];
  }

  Future<void> _fetchRooms() async {
    setState(() => _isLoading = true);
    try {
      final response = await http
          .get(Uri.parse('https://voice-app-2-jd95.onrender.com/api/rooms'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          final fetched = data['rooms'] ?? [];
          setState(() {
            _rooms = fetched.isNotEmpty ? fetched : _getDefaultRooms();
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
        _rooms = _getDefaultRooms();
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Joining Room: $targetId')),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Opened ${_user.userName}'s Room")),
    );
    _fetchRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        title: const Text('Nile Voice', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF00C9A7), size: 24),
            tooltip: 'Search Room',
            onPressed: _showSearchRoomDialog,
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${_user.coins}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00C9A7),
        elevation: 6,
        onPressed: _openMyPersonalRoom,
        icon: const Icon(Icons.mic, color: Colors.black),
        label: const Text('My Room', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRooms,
        color: const Color(0xFF00C9A7),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              height: 120,
              child: PageView.builder(
                itemCount: _banners.length,

itemBuilder: (context, index) {
                  final b = _banners[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: b['colors'] as List<Color>),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                b['title'],
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                b['subtitle'],
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        Icon(b['icon'] as IconData, size: 48, color: Colors.white.withOpacity(0.85)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: const Color(0xFF00C9A7),
                    backgroundColor: const Color(0xFF161B26),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) => setState(() => _selectedCategory = cat),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active Audio Rooms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _fetchRooms();
                  },
                  child: const Text('Refresh', style: TextStyle(color: Color(0xFF00C9A7), fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRoomCard(
              roomId: '1001',
              title: 'Global Chat Lounge 🌍',
              host: 'Master Host',
              usersCount: '12',
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
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
                    usersCount: room['usersCount']?.toString() ?? '5',
                  ),
                );
              }).toList(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard({
    required String roomId,
    required String title,
    required String host,
    required String usersCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFF00C9A7),
                child: Icon(Icons.headset, color: Colors.black, size: 26),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF161B26), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text('ID: $roomId • Host: $host', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.people_alt_outlined, color: Color(0xFF00C9A7), size: 16),
              const SizedBox(width: 4),
              Text(usersCount, style: const TextStyle(color: Color(0xFF00C9A7), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
