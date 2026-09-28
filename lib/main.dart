import 'package:flutter/material.dart';
import 'agency_screen.dart';

void main() {
  runApp(const VoiceApp());
}

class VoiceApp extends StatefulWidget {
  const VoiceApp({super.key});

  @override
  State<VoiceApp> createState() => _VoiceAppState();
}

class _VoiceAppState extends State<VoiceApp> {
  bool _isLoggedIn = true;

  void _login() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F11),
      ),
      home: _isLoggedIn
          ? MainNavigationScreen(onLogout: _logout)
          : LoginScreen(onLogin: _login),
    );
  }
}

// ==================== 1. LOG IN SCREEN ====================
class LoginScreen extends StatelessWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFF26C6DA), Color(0xFF00838F)],
                    ),
                  ),
                  child: const Icon(Icons.mic, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text('እንኳን ደህና መጡ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('ወደ ድምጽ ክፍሎች ለመግባት ስልክዎን ያስገቡ', style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 36),
                TextField(
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone, color: Color(0xFF26C6DA)),
                    hintText: 'ስልክ ቁጥር (09... / 07...)',
                    filled: true,
                    fillColor: const Color(0xFF1E1A29),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00ACC1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: onLogin,
                    child: const Text('Log In (ግባ)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== 2. MAIN NAVIGATION SCREEN ====================
class MainNavigationScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const MainNavigationScreen({super.key, required this.onLogout});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int userCoins = 50000;
  int userDiamonds = 1200;

  void addCoins(int amount) {
    setState(() {
      userCoins += amount;
    });
  }

  void addDiamonds(int amount) {
    setState(() {
      userDiamonds += amount;
    });
  }

@override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const RetroRoomScreen(),
      const AgencyCenterPage(),
      ProfileScreen(
        coins: userCoins,
        diamonds: userDiamonds,
        onAddCoins: () => addCoins(10000),
        onAddDiamonds: () => addDiamonds(100000),
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E1A29),
        selectedItemColor: const Color(0xFF26C6DA),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Live Room'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Agency'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ==================== 3. LIVE ROOM (RETRO STUDIO MIC) ====================
class RetroRoomScreen extends StatefulWidget {
  const RetroRoomScreen({super.key});

  @override
  State<RetroRoomScreen> createState() => _RetroRoomScreenState();
}

class _RetroRoomScreenState extends State<RetroRoomScreen> with SingleTickerProviderStateMixin {
  bool isMuted = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('VIP Live Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('በመገናኘት ላይ...', style: TextStyle(fontSize: 11, color: Color(0xFF26C6DA))),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),

          // ያማረው የ Retro Studio ማይክ ከነብርሃን ሞገዱ
          Center(
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: EdgeInsets.all(isMuted ? 4 : 4 + (_pulseController.value * 8)),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: isMuted
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withOpacity(0.6 * _pulseController.value),
                                  blurRadius: 20,
                                  spreadRadius: 6,
                                ),
                              ],
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFF26C6DA), Color(0xFF00838F)],
                        center: Alignment(-0.2, -0.2),

),
                      border: Border.all(
                        color: isMuted ? Colors.redAccent : const Color(0xFF80DEEA),
                        width: 3.5,
                      ),
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // የብርማ ክላሲክ ስቱዲዮ ማይክ ምስል
                          Container(
                            width: 44,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.white, Color(0xFFCFD8DC), Color(0xFF78909C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 3))
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                5,
                                (index) => Container(
                                  height: 2.5,
                                  margin: const EdgeInsets.symmetric(horizontal: 7),
                                  color: const Color(0xFF37474F),
                                ),
                              ),
                            ),
                          ),
                          if (isMuted)
                            const Icon(Icons.mic_off, color: Colors.redAccent, size: 45),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Host', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(width: 5),
                    Icon(Icons.verified, color: Colors.amber, size: 16),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // የተሳታፊ ወንበሮች
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(4, (index) => _buildSeat(index + 1)),
              ),
            ],
          ),

          const Spacer(),

          // የድምፅ መቆጣጠሪያ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1A29),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.headphones, color: Color(0xFF26C6DA), size: 22),
                    SizedBox(width: 10),
                    Text('የድምፅ ክፍል ክፍት ነው', style: TextStyle(color: Colors.white70)),
                  ],
                ),
                IconButton(
                  onPressed: () => setState(() => isMuted = !isMuted),
                  icon: CircleAvatar(
                    backgroundColor: isMuted ? Colors.redAccent : const Color(0xFF26C6DA),
                    child: Icon(isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildSeat(int seatNumber) {
    return Column(
      children: [
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1E1A29),
            border: Border.all(color: Colors.white12, width: 1.5),
          ),
          child: const Center(
            child: Icon(Icons.add, color: Colors.white38, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text('$seatNumber', style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }
}

// ==================== 4. PROFILE SCREEN ====================
class ProfileScreen extends StatelessWidget {
  final int coins;
  final int diamonds;
  final VoidCallback onAddCoins;
  final VoidCallback onAddDiamonds;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.coins,
    required this.diamonds,
    required this.onAddCoins,
    required this.onAddDiamonds,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.purple.shade300,
                    child: const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: Colors.greenAccent,
                      child: Icon(Icons.check, size: 15, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text('User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            const Text('ID: 98765432', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 20),

            // Coins & Diamonds Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1A29),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onAddCoins,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                              const SizedBox(width: 5),
                              Text('$coins', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text('Coins (+10k)', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  Container(height: 26, width: 1, color: Colors.white24),

Expanded(
                    child: InkWell(
                      onTap: onAddDiamonds,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.diamond, color: Colors.cyanAccent, size: 18),
                              const SizedBox(width: 5),
                              Text('$diamonds', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text('Diamonds (+100k)', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Wallet
            _buildItem(
              Icons.account_balance_wallet,
              'Wallet',
              Colors.amber,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WalletScreen(coins: coins, diamonds: diamonds)),
              ),
            ),
            const SizedBox(height: 10),

            // Badges
            _buildItem(
              Icons.military_tech,
              'Badges',
              Colors.orangeAccent,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BadgesScreen()),
              ),
            ),
            const SizedBox(height: 10),

            // Agency Center
            _buildItem(
              Icons.groups,
              'Agency Center\nየኤጀንሲ አስተዳደር እና ሆስቶች',
              Colors.tealAccent,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AgencyCenterPage()),
              ),
            ),
            const SizedBox(height: 10),

            // Log Out
            _buildItem(
              Icons.logout,
              'Log Out',
              Colors.redAccent,
              onLogout,
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(IconData icon, String title, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
      ),
    );
  }
}

// ==================== 5. WALLET SCREEN ====================
class WalletScreen extends StatelessWidget {
  final int coins;
  final int diamonds;

  const WalletScreen({super.key, required this.coins, required this.diamonds});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet'), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,

padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ያለዎት ሂሳብ', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Text('$coins Coins', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$diamonds Diamonds', style: const TextStyle(fontSize: 18, color: Colors.cyanAccent)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('ኮይን መግዣ አማራጮች (Recharge)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPackage('10,000 Coins', '100 ETB (Telebirr/CBE)'),
            _buildPackage('50,000 Coins', '500 ETB (Telebirr/CBE)'),
            _buildPackage('120,000 Coins', '1,000 ETB (Telebirr/CBE)'),
          ],
        ),
      ),
    );
  }

  Widget _buildPackage(String coinsText, String priceText) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFF1E1A29), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
              const SizedBox(width: 10),
              Text(coinsText, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26C6DA)),
            onPressed: () {},
            child: Text(priceText, style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ==================== 6. BADGES SCREEN ====================
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Badges'), backgroundColor: Colors.transparent),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildBadgeCard('VIP Member', Icons.workspace_premium, Colors.amber),
          _buildBadgeCard('Top Gifter', Icons.military_tech, Colors.deepOrangeAccent),
          _buildBadgeCard('Voice Star', Icons.star, const Color(0xFF26C6DA)),
          _buildBadgeCard('Active Host', Icons.local_fire_department, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1E1A29), borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
