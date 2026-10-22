import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/user_service.dart';
import 'room_screen.dart';
import 'messages_screen.dart';
import 'recharge_screen.dart';
import 'points_screen.dart';
import 'host_center_screen.dart';
import 'agency_screen.dart';
import 'coin_seller_screen.dart';
import 'daily_tasks_screen.dart';
import 'face_verification_screen.dart';
import 'screen/login_screen.dart';

import 'store_screen.dart';
import 'backpack_screen.dart';
import 'level_screen.dart';
import 'support_screen.dart';
import 'settings_screen.dart';
import 'invite_screen.dart';

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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainNavigationScreen(),
        '/face_verification': (context) => const FaceVerificationScreen(),
        '/store': (context) => const StoreScreen(),
        '/backpack': (context) => const BackpackScreen(),
        '/level': (context) => const LevelScreen(),
        '/support': (context) => const SupportScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
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

  String _mainTab = 'Party'; // 'Follow' or 'Party'
  String _selectedCountry = 'All';

  final List<Map<String, String>> _countries = const [
    {'name': 'All', 'flag': ''},
    {'name': 'Ethiopia', 'flag': '🇪🇹'},
    {'name': 'Philippines', 'flag': '🇵🇭'},
    {'name': 'Burma', 'flag': '🇲🇲'},
    {'name': 'Kenya', 'flag': '🇰🇪'},
    {'name': 'Saudi Arabia', 'flag': '🇸🇦'},
    {'name': 'UAE', 'flag': '🇦🇪'},
  ];

  final List<Map<String, dynamic>> _banners = const [
    {
      'title': 'Weekly PK Star Tournament',

'subtitle': 'Win up to 50,000 Coins!',
      'colors': [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
      'icon': Icons.emoji_events,
    },
    {
      'title': 'Recharge Bonus 20%',
      'subtitle': 'Get extra coins on Binance Pay',
      'colors': [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)],
      'icon': Icons.monetization_on,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  List<Map<String, dynamic>> _getDefaultRooms() {
    return [
      {
        'roomId': '2001',
        'title': 'Ethiopian Coffee & Chat ☕',
        'hostName': 'Selam',
        'usersCount': '8',
        'country': 'Ethiopia',
      },
      {
        'roomId': '2002',
        'title': 'Habesha Music Lounge 🎵',
        'hostName': 'DJ_Nile',
        'usersCount': '15',
        'country': 'Ethiopia',
      },
      {
        'roomId': '2003',
        'title': 'Tech & Crypto Talks 🚀',
        'hostName': 'Kedir',
        'usersCount': '6',
        'country': 'Ethiopia',
      },
      {
        'roomId': '2004',
        'title': 'Manila Friends Chill 🇵🇭',
        'hostName': 'Maria',
        'usersCount': '11',
        'country': 'Philippines',
      },
      {
        'roomId': '2005',
        'title': 'Yangon Golden Night 🇲🇲',
        'hostName': 'Aung',
        'usersCount': '19',
        'country': 'Burma',
      },
    ];
  }

  Future<void> _fetchRooms() async {
    try {
      final response = await http
          .get(Uri.parse('${UserService.serverUrl}/api/rooms'))
          .timeout(const Duration(seconds: 5));

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
    } catch (_) {}

    if (mounted) {
      setState(() {
        _rooms = _getDefaultRooms();
        _isLoading = false;
      });
    }
  }

  void _showDailySignInDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C3CE9), Color(0xFF8F14E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Sign-in',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Claim free G-Coins daily to send gifts!',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),

shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.card_giftcard, color: Colors.amberAccent, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Consecutive Check-ins: Active',
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      children: [
                        _buildDailyItem('Day 1', '+100', true),
                        _buildDailyItem('Day 2', '+200', true),
                        _buildDailyItem('Day 3', '+300', true),
                        _buildDailyItem('Day 4', '+400', false),
                        _buildDailyItem('Day 5', '+500', false),
                        _buildDailyItem('Day 6', '+600', false),
                        _buildDailyItem('Day 7', '+1000', false, isJackpot: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C9A7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    setState(() {
                      _user.coins += 300;
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 Claimed 300 Daily G-Coins successfully!'),
                        backgroundColor: Color(0xFF00C9A7),
                      ),
                    );
                  },
                  child: const Text(
                    'Claim Coins Now',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyItem(String day, String reward, bool isClaimed, {bool isJackpot = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isJackpot ? const Color(0xFFFFF3E0) : const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isJackpot ? Colors.amber : (isClaimed ? const Color(0xFF00C9A7) : Colors.transparent),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(day, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(
            reward,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isJackpot ? Colors.deepOrange : const Color(0xFF6C3CE9),

),
          ),
          const SizedBox(height: 2),
          Icon(
            isClaimed ? Icons.check_circle : Icons.monetization_on,
            size: 14,
            color: isClaimed ? const Color(0xFF00C9A7) : Colors.amber,
          ),
        ],
      ),
    );
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
              Text('Search Room or User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter Room ID, User ID or Name...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
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
                        roomTitle: 'Room $targetId',
                        hostName: 'Host',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Search', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openMyPersonalRoom() async {
    try {
      await http.post(
        Uri.parse('${UserService.serverUrl}/api/rooms/create'),
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

  List<dynamic> get _filteredRooms {
    if (_mainTab == 'Follow') {
      return _rooms.take(2).toList();
    }
    if (_selectedCountry == 'All') {
      return _rooms;
    }
    return _rooms.where((r) => r['country'] == _selectedCountry).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      body: SafeArea(
        child: Column(

children: [
            // TOP HEADER: Follow & Party Tabs + Search & Daily Coins Check-in
            Container(
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _mainTab = 'Follow'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Follow',
                          style: TextStyle(
                            fontSize: _mainTab == 'Follow' ? 22 : 17,
                            fontWeight: FontWeight.bold,
                            color: _mainTab == 'Follow' ? Colors.white : Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_mainTab == 'Follow')
                          Container(
                            width: 18,
                            height: 3,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C9A7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => setState(() => _mainTab = 'Party'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Party',
                          style: TextStyle(
                            fontSize: _mainTab == 'Party' ? 22 : 17,
                            fontWeight: FontWeight.bold,
                            color: _mainTab == 'Party' ? Colors.white : Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_mainTab == 'Party')
                          Container(
                            width: 18,
                            height: 3,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C9A7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white, size: 24),
                    tooltip: 'Search Room',
                    onPressed: _showSearchRoomDialog,
                  ),
                  GestureDetector(
                    onTap: _showDailySignInDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.card_giftcard, color: Colors.white, size: 15),
                          SizedBox(width: 4),
                          Text(
                            'Coins',

style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // HORIZONTAL COUNTRY FILTER
            SizedBox(
              height: 34,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _countries.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final country = _countries[idx];
                  final name = country['name']!;
                  final flag = country['flag']!;
                  final isSelected = (_selectedCountry == name);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCountry = name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00C9A7) : const Color(0xFF161B26),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00C9A7) : Colors.white12,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          if (flag.isNotEmpty) ...[
                            Text(flag, style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            name,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // ROOMS FEED & BANNERS
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchRooms,
                color: const Color(0xFF00C9A7),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    SizedBox(
                      height: 115,
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
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        b['subtitle'],
                                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(b['icon'] as IconData, size: 44, color: Colors.white.withOpacity(0.85)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _mainTab == 'Follow' ? 'Followed Rooms' : 'Active Live Rooms',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _isLoading = true);
                            _fetchRooms();
                          },
                          child: const Text('Refresh', style: TextStyle(color: Color(0xFF00C9A7), fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
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
                      ..._filteredRooms.map((room) {
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
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00C9A7),
        elevation: 6,
        onPressed: _openMyPersonalRoom,
        icon: const Icon(Icons.mic, color: Colors.black),
        label: const Text('My Room', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRoomCard({
    required String roomId,
    required String title,
    required String host,

required String usersCount,
  }) {
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

  Future<void> _openFaceVerification() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FaceVerificationScreen()),
    );
    if (result == true && mounted) {
      await _refreshProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isVerified = _user.isFaceVerified;

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
                          Row(
                            children: [
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
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: isVerified ? null : _openFaceVerification,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isVerified
                                        ? const Color(0xFF00C9A7).withOpacity(0.18)
                                        : Colors.orangeAccent.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isVerified ? const Color(0xFF00C9A7) : Colors.orangeAccent,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isVerified ? Icons.verified : Icons.error_outline,
                                        color: isVerified ? const Color(0xFF00C9A7) : Colors.orangeAccent,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isVerified ? 'Verified' : 'Verify Face',
                                        style: TextStyle(
                                          color: isVerified ? const Color(0xFF00C9A7) : Colors.orangeAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),

),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
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
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RechargeScreen()),
                          );
                          _refreshProfile();
                        },
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PointsScreen()),
                          );
                          _refreshProfile();
                        },
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
                                    const Text('Points', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_user.points}',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              const CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(0xFF38B29C),
                                child: Icon(Icons.diamond, color: Colors.white, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B26),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HostCenterScreen()),

);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: _buildActionItem(icon: Icons.mic_external_on, label: 'Host Center'),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AgencyScreen()),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: _buildActionItem(icon: Icons.groups_outlined, label: 'Agency'),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CoinSellerScreen()),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: _buildActionItem(icon: Icons.storefront_outlined, label: 'Coin Seller'),
                          ),
                        ),
                      ),
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
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DailyTasksScreen(),
                            ),
                          );
                        },
                        child: _buildGridMenuItem(icon: Icons.task_alt, label: 'Task'),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InviteScreen(
                                userId: _user.userId,
                                userName: _user.userName.isNotEmpty ? _user.userName : 'User_${_user.userId}',
                                onRewardClaimed: (bonusCoins) {
                                  _user.coins += bonusCoins;
                                  _refreshProfile();
                                },
                              ),
                            ),

);
                        },
                        child: _buildGridMenuItem(icon: Icons.person_add_alt, label: 'Invite'),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const StoreScreen()),
                          );
                        },
                        child: _buildGridMenuItem(icon: Icons.shopping_bag_outlined, label: 'Store'),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BackpackScreen()),
                          );
                        },
                        child: _buildGridMenuItem(icon: Icons.backpack_outlined, label: 'Backpack'),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LevelScreen()),
                          );
                        },
                        child: _buildGridMenuItem(icon: Icons.military_tech_outlined, label: 'Level'),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const InternalMedalWallScreen()),
                          );
                        },
                        child: _buildGridMenuItem(icon: Icons.shield_outlined, label: 'Medal Wall'),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SupportScreen()),
                          );
                        },
                        child: _buildGridMenuItem(icon: Icons.headset_mic_outlined, label: 'Support'),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                        child: _buildGridMenuItem(icon: Icons.tune, label: 'Settings'),
                      ),
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
      mainAxisSize: MainAxisSize.min,
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
