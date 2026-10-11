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
            icon: Icon(Icons.mic),
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

  // ከሰርቨሩ ዳታቤዝ ላይ ንቁ ክፍሎችን ማምጣት
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

  // አዲስ ክፍል መፍጠሪያ ፖፕአፕ
  void _showCreateRoomDialog() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Create Voice Room', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter Room Title',
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
              onPressed: () async {
                final title = titleController.text.trim();
                Navigator.pop(context);
                if (title.isNotEmpty) {
                  await _createNewRoom(title);
                }
              },
              child: const Text('Create', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // አዲሱን ክፍል ወደ ሰርቨር መላክና በቀጥታ መግባት
  Future<void> _createNewRoom(String title) async {
    try {
      final response = await http.post(
        Uri.parse('https://voice-app-2-jd95.onrender.com/api/rooms/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'category': 'General',
          'hostId': _user.userId,
          'hostName': _user.userName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final room = data['room'];
          _fetchRooms(); // ዝርዝሩን ማደስ

          if (!mounted) return;
          // በቀጥታ ወደ አዲሱ ክፍል መግባት
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RoomScreen(
                roomId: room['roomId'].toString(),
                roomTitle: room['title'].toString(),
                hostName: room['hostName'].toString(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Create room error: $e");
    }
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
            icon: const Icon(Icons.refresh, color: Color(0xFF00C9A7)),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00C9A7),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Create Room', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: _showCreateRoomDialog,
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
            const SizedBox(height: 20),
            const Text('Available Rooms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // ነባሪው ቋሚ ክፍል (Global Room)
            _buildRoomCard(
              roomId: '1001',
              title: 'Global Chat Lounge',
              host: 'Master Host',
            ),

            const SizedBox(height: 10),

            // በዳታቤዝ የተመዘገቡ አዳዲስ ክፍሎች
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
                  child: Text('No custom rooms yet. Tap "Create Room" to start one!', style: TextStyle(color: Colors.white38, fontSize: 13)),
                ),
              )
            else
              ..._rooms.map((room) {
                // 1001 አስቀድሞ ስላለ እንዳይደገም
                if (room['roomId'].toString() == '1001') return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildRoomCard(
                    roomId: room['roomId'].toString(),
                    title: room['title'] ?? 'Voice Lounge',
                    host: room['hostName'] ?? 'Host',
                  ),
                );
              }).toList(),
            const SizedBox(height: 80), // ለFloating Button ክፍተት
          ],
        ),
      ),
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
    if (!_user.isInitialized) {
      _user.initializeUser().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: const Color(0xFF00C9A7),
                child: Text(
                  _user.userName.isNotEmpty ? _user.userName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _user.userName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B26),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00C9A7)),
                ),
                child: Text(
                  'User ID: ${_user.userId}',
                  style: const TextStyle(color: Color(0xFF00C9A7), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                tileColor: const Color(0xFF161B26),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.monetization_on, color: Colors.amber),
                title: const Text('Balance Coins'),
                trailing: Text('${_user.coins}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
