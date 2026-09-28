import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _login() => setState(() => _isLoggedIn = true);
  void _logout() => setState(() => _isLoggedIn = false);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice App',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF4F7F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: _isLoggedIn
          ? MainNavigationScreen(onLogout: _logout)
          : LoginScreen(onLogin: _login),
    );
  }
}

// ==================== LOG IN SCREEN ====================
class LoginScreen extends StatelessWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFF26C6DA), Color(0xFF00838F)],
                    ),
                  ),
                  child: const Icon(Icons.mic, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'እንኳን ደህና መጡ',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                const Text('ወደ ድምጽ ክፍሎች ለመግባት ስልክዎን ያስገቡ', style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 36),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone, color: Color(0xFF26C6DA)),
                    hintText: 'ስልክ ቁጥር (09... / 07...)',
                    hintStyle: const TextStyle(color: Colors.white38),
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

// ==================== MAIN NAVIGATION SCREEN (4 TABS) ====================
class MainNavigationScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const MainNavigationScreen({super.key, required this.onLogout});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 3; // በ "Me" ገጽ እንዲከፈት

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const RetroRoomScreen(),
      const Scaffold(body: Center(child: Text('Moment Screen', style: TextStyle(fontSize: 18)))),
      const Scaffold(body: Center(child: Text('Message Screen', style: TextStyle(fontSize: 18)))),
      MeProfileScreen(onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Room'),
                _buildNavItem(1, Icons.public, 'Moment'),
                _buildNavItem(2, Icons.notifications_none_rounded, 'Message'),
                _buildMeNavItem(3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF00E5FF) : Colors.grey.shade400, size: 28),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black87 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeNavItem(int index) {
    final bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)])
                  : null,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.person,
              color: isSelected ? Colors.white : Colors.grey.shade400,
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Me',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF00B0FF) : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ME (PROFILE) SCREEN - FULL 19 FEATURES ====================
class MeProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const MeProfileScreen({super.key, required this.onLogout});

  @override
  State<MeProfileScreen> createState() => _MeProfileScreenState();
}

class _MeProfileScreenState extends State<MeProfileScreen> {
  int coins = 0;
  double points = 23902.29;
  int followedCount = 3118;
  int followingCount = 519;
  int friendsCount = 104;

void addCoins(int amount) {
    setState(() => coins += amount);
  }

  void _openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F7F8),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),

            // 1. HEADER PROFILE (User Info & Badges)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 3),
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KEDIR ,,,,',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            _buildBadgePill('♂ 17', const Color(0xFF26C6DA)),
                            _buildBadgePill('▲ 18', const Color(0xFF66BB6A)),
                            _buildBadgePill('✪ 14', const Color(0xFF5C6BC0)),
                            _buildBadgePill('AGENCY', const Color(0xFF0288D1)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Text('ID: 1753925', style: TextStyle(fontSize: 13, color: Colors.black54)),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(const ClipboardData(text: '1753925'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('ID ተገልብጧል (Copied)!'), duration: Duration(seconds: 1)),
                                );
                              },
                              child: const Icon(Icons.copy, size: 14, color: Colors.black45),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black38),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. SOCIAL COUNTS (Followed, Following, Friends)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCountItem('$followedCount', 'Followed', () {
                    _openPage(SimpleDetailScreen(title: 'Followed', content: 'የተከታዮች ዝርዝር: $followedCount ሰዎች'));

}),
                  Container(height: 24, width: 1, color: Colors.black12),
                  _buildCountItem('$followingCount', 'Following', () {
                    _openPage(SimpleDetailScreen(title: 'Following', content: 'የሚከታተሏቸው ሰዎች: $followingCount'));
                  }),
                  Container(height: 24, width: 1, color: Colors.black12),
                  _buildCountItem('$friendsCount', 'Friends', () {
                    _openPage(SimpleDetailScreen(title: 'Friends', content: 'የጓደኞች ዝርዝር: $friendsCount'));
                  }),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 3. VIP CLUB BANNER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () => _openPage(const VipClubScreen()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3E2723), Color(0xFF1B0000)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium, color: Color(0xFFFFD54F), size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('VIP Club', style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 15)),
                            SizedBox(height: 2),
                            Text('Upgrade to VIP and get free coins daily', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCC80),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Get VIP', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 4. WALLET BAR (Coins & Points)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    // Coins
                    Expanded(
                      child: InkWell(
                        onTap: () => _openPage(WalletScreen(coins: coins, points: points, onAddCoins: () => addCoins(10000))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Coins', style: TextStyle(color: Colors.black54, fontSize: 13)),
                            const SizedBox(height: 6),

Row(
                              children: [
                                const Icon(Icons.monetization_on, color: Colors.amber, size: 22),
                                const SizedBox(width: 6),
                                Text('$coins', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(height: 38, width: 1, color: Colors.black12),
                    const SizedBox(width: 20),

                    // Points
                    Expanded(
                      child: InkWell(
                        onTap: () => _openPage(SimpleDetailScreen(title: 'Points & Earnings', content: 'የተሰበሰበ ጠቅላላ ነጥብ: $points Points')),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Points', style: TextStyle(color: Colors.black54, fontSize: 13)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00E5FF)),
                                  child: const Text('H', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                                const SizedBox(width: 6),
                                Text('$points', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00B0FF))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 5. GRID 1: 8 SERVICES
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // 5. Recharge
                        _buildGridItem(Icons.account_balance_wallet, 'Recharge', Colors.amber, () {
                          _openPage(WalletScreen(coins: coins, points: points, onAddCoins: () => addCoins(10000)));
                        }),
                        // 6. Store
                        _buildGridItem(Icons.storefront, 'Store', Colors.pinkAccent, () {
                          _openPage(const StoreScreen());
                        }),
                        // 7. Invitation
                        _buildGridItem(Icons.mark_email_unread, 'Invitation', Colors.redAccent, () {
                          _openPage(const InvitationScreen());
                        }),
                        // 8. Backpack
                        _buildGridItem(Icons.backpack, 'Backpack', const Color(0xFF00B0FF), () {
                          _openPage(const BackpackScreen());
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(

mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // 9. Lucky Island
                        _buildGridItem(Icons.wb_sunny, 'Lucky Island', Colors.green, () {
                          _openPage(const LuckyIslandScreen());
                        }),
                        // 10. Level
                        _buildGridItem(Icons.military_tech, 'Level', Colors.purpleAccent, () {
                          _openPage(const LevelScreen());
                        }),
                        // 11. Task
                        _buildGridItem(Icons.calendar_month, 'Task', Colors.teal, () {
                          _openPage(const TaskScreen());
                        }),
                        // 12. Badge
                        _buildGridItem(Icons.shield, 'Badge', Colors.deepOrangeAccent, () {
                          _openPage(const BadgesScreen());
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 6. GRID 2: 7 MANAGEMENT & SETTINGS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // 13. Host Center
                        _buildGridItem(Icons.record_voice_over, 'Host Center', const Color(0xFF00B0FF), () {
                          _openPage(const HostCenterScreen());
                        }),
                        // 14. Agency
                        _buildGridItem(Icons.business_center, 'Agency', const Color(0xFF00B0FF), () {
                          _openPage(const AgencyCenterPage());
                        }),
                        // 15. Coin Seller
                        _buildGridItem(Icons.attach_money, 'Coin Seller', const Color(0xFF00B0FF), () {
                          _openPage(const CoinSellerScreen());
                        }),
                        // 16. Support
                        _buildGridItem(Icons.support_agent, 'Support', const Color(0xFF00B0FF), () {
                          _openPage(const SupportScreen());
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(width: 14),
                        // 17. About
                        _buildGridItem(Icons.info_outline, 'About', const Color(0xFF00B0FF), () {
                          _openPage(const AboutScreen());
                        }),
                        const SizedBox(width: 32),
                        // 18. Setting
                        _buildGridItem(Icons.settings, 'Setting', const Color(0xFF00B0FF), () {
                          _openPage(SettingsScreen(onLogout: widget.onLogout));
                        }),
                        const SizedBox(width: 32),
                        // 19. Network Line
                        _buildGridItem(Icons.speed, 'Network Line', const Color(0xFF00B0FF), () {
                          _openPage(const NetworkLineScreen());
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

Widget _buildBadgePill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildCountItem(String count, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String label, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== ALL 19 SUB-SCREENS WITH COMPLETE LOGIC ====================

// 1. VIP Club Screen
class VipClubScreen extends StatelessWidget {
  const VipClubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VIP Club')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3E2723), Color(0xFF1B0000)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: const [
                  Icon(Icons.workspace_premium, color: Color(0xFFFFD54F), size: 60),
                  SizedBox(height: 10),
                  Text('VIP Privilege', style: TextStyle(color: Color(0xFFFFD54F), fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('የየዕለቱ ነፃ ኮይኖች፣ ልዩ ባጆች እና የመግቢያ አኒሜሽን', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB300), minimumSize: const Size(double.infinity, 48)),
              onPressed: () {},
              child: const Text('ወደ VIP አድግ (Subscribe)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. Store Screen
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store (መደብር)')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _buildStoreItem('Crown Avatar Frame', '5,000 Coins', Icons.camera),
          _buildStoreItem('Sports Car Entry', '20,000 Coins', Icons.directions_car),
          _buildStoreItem('Dragon Mic Ring', '15,000 Coins', Icons.shield),
          _buildStoreItem('Golden Chat Bubble', '8,000 Coins', Icons.chat),
        ],
      ),
    );
  }

Widget _buildStoreItem(String name, String price, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: const Color(0xFF00B0FF)),
          const SizedBox(height: 8),
          Text(name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(price, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }
}

// 3. Invitation Screen
class InvitationScreen extends StatelessWidget {
  const InvitationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitation (ጓደኛ መጋበዣ)')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.share, size: 70, color: Color(0xFF00B0FF)),
            const SizedBox(height: 16),
            const Text('ጓደኞችህን ጋብዝ እና ነፃ ኮይኖችን አግኝ!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('የመጋበዣ ኮድህ: 1753925', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Color(0xFF00B0FF)),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: '1753925'));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ኮድ ተገልብጧል!')));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 4. Backpack Screen
class BackpackScreen extends StatelessWidget {
  const BackpackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backpack (የኔ ንብረቶች)')),
      body: const Center(
        child: Text('በአሁኑ ሰዓት የተያዘ ምንም ስጦታ ወይም እቃ የለም።', style: TextStyle(color: Colors.black54)),
      ),
    );
  }
}

// 5. Lucky Island Screen
class LuckyIslandScreen extends StatelessWidget {
  const LuckyIslandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lucky Island (የዕድል ጌም)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.casino, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            const Text('Lucky Wheel & Mini Games', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('ኮይኖችን አሽክርክር እና ትላልቅ ሽልማቶችን ውሰድ!', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {},
              child: const Text('አሁን አሽክርክር (Spin)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// 6. Level Screen
class LevelScreen extends StatelessWidget {
  const LevelScreen({super.key});

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User & Host Level')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('User Level: Level 17', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  LinearProgressIndicator(value: 0.65, color: Color(0xFF26C6DA), backgroundColor: Colors.black12),
                  SizedBox(height: 6),
                  Text('ወደ Level 18 ለማደግ 3,500 ነጥብ ይቀራል', style: TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 7. Task Screen
class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Tasks (የእለት ተግባራት)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTaskItem('በቀጥታ ድምፅ ክፍል ለ 10 ደቂቃ መቆየት', '+50 Coins', true),
          _buildTaskItem('1 ስጦታ ለጓደኛ መላክ', '+100 Coins', false),
          _buildTaskItem('አፑን ለጓደኞች ማጋራት', '+200 Coins', false),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String task, String reward, bool done) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(task, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text(reward, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// 8. Host Center Screen
class HostCenterScreen extends StatelessWidget {
  const HostCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host Center (የሆስት ማዕከል)')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Column(children: [Text('የዛሬ ሰዓት', style: TextStyle(color: Colors.black54)), Text('2h 45m', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                  Column(children: [Text('የዛሬ ነጥብ', style: TextStyle(color: Colors.black54)), Text('12,400', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00B0FF)))]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 9. Coin Seller Screen
class CoinSellerScreen extends StatelessWidget {
  const CoinSellerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coin Seller (የኮይን ነጋዴ ማዕከል)')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text('ይፋዊ የኮይን ወኪል ለመሆን በኤጀንሲ በኩል ማመልከት ይችላሉ።', textAlign: TextAlign.center, style: TextStyle(fontSize: 15)),
        ),
      ),
    );
  }
}

// 10. Support Screen
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support & Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.telegram, color: Color(0xFF00B0FF)),
              title: Text('Telegram Official Channel'),
              subtitle: Text('@VoiceApp_Official'),
            ),
            const ListTile(
              leading: Icon(Icons.email, color: Colors.redAccent),
              title: Text('Email Support'),
              subtitle: Text('support@voiceapp.com'),
            ),
          ],
        ),
      ),
    );
  }
}

// 11. About Screen
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Voice App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.mic, size: 60, color: Color(0xFF00B0FF)),
            SizedBox(height: 12),
            Text('Voice App v1.0.0', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Professional Live Voice Chat Platform', style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

// 12. Settings Screen
class SettingsScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const SettingsScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings (ቅንብሮች)')),
      body: ListView(
        children: [
          const ListTile(leading: Icon(Icons.notifications), title: Text('የመልእክት ማሳወቂያ (Notifications)')),
          const ListTile(leading: Icon(Icons.lock), title: Text('የይለፍ ቃል እና ደህንነት')),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log Out (ውጣ)', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
        ],
      ),
    );
  }
}

// 13. Network Line Screen
class NetworkLineScreen extends StatefulWidget {
  const NetworkLineScreen({super.key});

  @override
  State<NetworkLineScreen> createState() => _NetworkLineScreenState();
}

class _NetworkLineScreenState extends State<NetworkLineScreen> {
  int selectedLine = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Line (የኔትወርክ ፍጥነት)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLineTile(1, 'Line 1 (Auto Fast)', '45 ms', Colors.green),
          _buildLineTile(2, 'Line 2 (Ethiopia Server)', '62 ms', Colors.green),
          _buildLineTile(3, 'Line 3 (Backup Server)', '120 ms', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildLineTile(int index, String title, String ping, Color color) {
    return RadioListTile<int>(
      value: index,
      groupValue: selectedLine,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('Ping: $ping', style: TextStyle(color: color)),
      onChanged: (val) => setState(() => selectedLine = val!),
    );
  }
}

// 14. Simple Detail Screen (ለ Followed, Following, Friends)
class SimpleDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  const SimpleDetailScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(content, style: const TextStyle(fontSize: 16, color: Colors.black87)),
      ),
    );
  }
}

// ==================== WALLET SCREEN ====================
class WalletScreen extends StatelessWidget {
  final int coins;
  final double points;
  final VoidCallback onAddCoins;

  const WalletScreen({
    super.key,
    required this.coins,
    required this.points,
    required this.onAddCoins,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        title: const Text('My Wallet', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
                  Text('$coins Coins', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('$points Points', style: const TextStyle(fontSize: 18, color: Colors.cyanAccent)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('ኮይን መግዣ አማራጮች (Recharge)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            _buildPackage(context, '10,000 Coins', '100 ETB (Telebirr/CBE)'),
            _buildPackage(context, '50,000 Coins', '500 ETB (Telebirr/CBE)'),
            _buildPackage(context, '120,000 Coins', '1,000 ETB (Telebirr/CBE)'),
          ],
        ),
      ),
    );
  }

  Widget _buildPackage(BuildContext context, String coinsText, String priceText) {
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
              Text(coinsText, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26C6DA)),
            onPressed: () {
              onAddCoins();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('10,000 ኮይን በተሳካ ሁኔታ ተሞልቷል!')));
            },
            child: Text(priceText, style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ==================== BADGES SCREEN ====================
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        title: const Text('My Badges', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,

iconTheme: const IconThemeData(color: Colors.white),
      ),
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}

// ==================== LIVE ROOM (RETRO STUDIO MIC) ====================
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
            Text('VIP Live Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('በመገናኘት ላይ...', style: TextStyle(fontSize: 11, color: Color(0xFF26C6DA))),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),

          // Retro Studio Mic
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
                    Text('Host', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    SizedBox(width: 5),
                    Icon(Icons.verified, color: Colors.amber, size: 16),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Participants seats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) => _buildSeat(index + 1)),
            ),
          ),

          const Spacer(),

          // Bottom Voice Controls
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
