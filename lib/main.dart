import 'package:flutter/material.dart';
import 'room_screen.dart';
import 'agency_screen.dart';

void main() {
  runApp(const VoiceApp());
}

class VoiceApp extends StatelessWidget {
  const VoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F111A),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const RoomScreen(),    // 1. የድምፅ ክፍል ገጽ
    const AgencyCenterPage(),  // 2. ፕሮፋይል እና ኤጀንሲ ገጽ
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF1A1C29),
        selectedItemColor: const Color(0xFF9C27B0),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: 'ላይቭ ሩም',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'ፕሮፋይል / ኤጀንሲ',
          ),
        ],
      ),
    );
  }
}
