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
        scaffoldBackgroundColor: const Color(0xFF0F0F11),
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

  // ተንቀሳቃሽ የኮይን እና ዳይመንድ መጠኖች
  int userCoins = 50000;
  int userDiamonds = 1200;

  // ኮይን ለመቀነስ (ለምሳሌ ስጦታ ሲላክ)
  void spendCoins(int amount) {
    if (userCoins >= amount) {
      setState(() {
        userCoins -= amount;
      });
    }
  }

  // ዳይመንድ ለመጨመር (ለምሳሌ 1 ሰዓት ሲሞላ ወይም ስጦታ ሲቀበል)
  void addDiamonds(int amount) {
    setState(() {
      userDiamonds += amount;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ሦስቱ የተገናኙ ገጾች
    final List<Widget> pages = [
      const RoomScreen(),
      const AgencyCenterPage(),
      ProfileScreen(
        coins: userCoins,
        diamonds: userDiamonds,
        onAddCoins: () => setState(() => userCoins += 10000), // ለሙከራ 10,000 ኮይን መጨመሪያ
        onAddDiamonds: () => addDiamonds(100000), // ለሙከራ 100,000 ዳይመንድ መጨመሪያ
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF1E1A29),
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: 'Live Room',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Agency',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// የተሟላው የፕሮፋይል ገጽ
class ProfileScreen extends StatelessWidget {
  final int coins;
  final int diamonds;
  final VoidCallback onAddCoins;
  final VoidCallback onAddDiamonds;

  const ProfileScreen({
    super.key,
    required this.coins,
    required this.diamonds,
    required this.onAddCoins,
    required this.onAddDiamonds,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.purple.shade300,
                    child: const Icon(Icons.person, size: 55, color: Colors.white),
                  ),
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(

radius: 14,
                      backgroundColor: Colors.greenAccent,
                      child: Icon(Icons.check, size: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('User', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('ID: 98765432', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 24),

            // የኮይን እና ዳይመንድ ካርድ (ተንቀሳቃሽ)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1A29),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onAddCoins, // ሲነካ ኮይን ይጨምራል
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                              const SizedBox(width: 6),
                              Text('$coins', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('Coins (+10k)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  Container(height: 30, width: 1, color: Colors.white24),
                  Expanded(
                    child: InkWell(
                      onTap: onAddDiamonds, // ሲነካ 100,000 ዳይመንድ ይጨምራል
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.diamond, color: Colors.cyanAccent, size: 20),
                              const SizedBox(width: 6),
                              Text('$diamonds', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('Diamonds (+100k)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildMenuItem(Icons.account_balance_wallet, 'Wallet', Colors.amber),
            const SizedBox(height: 12),
            _buildMenuItem(Icons.military_tech, 'Badges', Colors.orangeAccent),
            const SizedBox(height: 12),
            _buildMenuItem(Icons.groups, 'Agency Center\nየኤጀንሲ አስተዳደር እና ሆስቶች', Colors.tealAccent),
            const SizedBox(height: 12),
            _buildMenuItem(Icons.logout, 'Log Out', Colors.redAccent),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A29),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(

children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
        ],
      ),
    );
  }
}
