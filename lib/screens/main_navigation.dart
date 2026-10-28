import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'room_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _coins = 1250;

  void _updateCoins(int newCoins) {
    setState(() {
      _coins = newCoins;
    });
  }

  void _joinRoom(String roomTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoicePartyRoomScreen(
          roomTitle: roomTitle,
          initialCoins: _coins,
          onCoinUpdate: _updateCoins,
          seatCount: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        coins: _coins,
        onCoinUpdate: _updateCoins,
        onJoinRoom: _joinRoom,
      ),
      const MessagesScreen(),
      ProfileScreen(coins: _coins),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF16162A),
        selectedItemColor: const Color(0xFFFFD700),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Message',
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
