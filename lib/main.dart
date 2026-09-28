import 'dart:math';
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

// ==================== MAIN NAVIGATION SCREEN ====================
class MainNavigationScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const MainNavigationScreen({super.key, required this.onLogout});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 3;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const RetroRoomScreen(),
      const Scaffold(body: Center(child: Text('Moment Screen', style: TextStyle(fontSize: 18)))),
      const MessageScreen(),
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

// ==================== ME (PROFILE) SCREEN (19 FEATURES) ====================
class MeProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const MeProfileScreen({super.key, required this.onLogout});

  @override
  State<MeProfileScreen> createState() => _MeProfileScreenState();
}

class _MeProfileScreenState extends State<MeProfileScreen> {
  int coins = 50000;
  double points = 23902.29;
  String userName = 'KEDIR ,,,,';
  String userId = '1753925';

  int followedCount = 3118;
  int followingCount = 519;
  int friendsCount = 104;

// የቦርሳ እቃዎች (Backpack state)
  List<Map<String, dynamic>> myItems = [
    {'title': 'Ocean World', 'category': 'Theme', 'inUse': true, 'icon': Icons.water},
    {'title': 'VIP Room Card', 'category': 'Room Card', 'inUse': false, 'icon': Icons.credit_card},
    {'title': 'Sunny Cactus', 'category': 'ChatBubble', 'inUse': false, 'icon': Icons.chat_bubble},
  ];

  void addCoins(int amount) {
    setState(() => coins += amount);
  }

  void deductCoins(int amount) {
    setState(() => coins -= amount);
  }

  void addItemToBackpack(String title, String category, IconData icon) {
    setState(() {
      myItems.add({
        'title': title,
        'category': category,
        'inUse': false,
        'icon': icon,
      });
    });
  }

  void toggleItemUse(int index) {
    setState(() {
      myItems[index]['inUse'] = !myItems[index]['inUse'];
    });
  }

  void _openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _editProfileDialog() {
    TextEditingController nameController = TextEditingController(text: userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ፕሮፋይል ማስተካከያ'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'የተጠቃሚ ስም'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ሰርዝ')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() => userName = nameController.text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('አስቀምጥ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F7F8),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),

            // 1. Header (User Info)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  InkWell(
                    onTap: _editProfileDialog,
                    child: Container(
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 16, color: Colors.black45),
                              onPressed: _editProfileDialog,
                            ),
                          ],
                        ),
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
                            Text('ID: $userId', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: userId));
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
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black38),
                    onPressed: _editProfileDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Social Counts (Followed, Following, Friends)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCountItem('$followedCount', 'Followed', () {
                    _openPage(SocialListScreen(title: 'Followed (ተከታዮች)', initialCount: followedCount));
                  }),
                  Container(height: 24, width: 1, color: Colors.black12),
                  _buildCountItem('$followingCount', 'Following', () {
                    _openPage(SocialListScreen(title: 'Following (የምከተላቸው)', initialCount: followingCount));
                  }),
                  Container(height: 24, width: 1, color: Colors.black12),
                  _buildCountItem('$friendsCount', 'Friends', () {
                    _openPage(SocialListScreen(title: 'Friends (ጓደኞች)', initialCount: friendsCount));
                  }),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 3. VIP Club Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () => _openPage(VipClubScreen(onSubscribe: () => addCoins(5000))),
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

            // 4. Wallet Bar (Coins & Points)
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
                    Expanded(
                      child: InkWell(
                        onTap: () => _openPage(RechargeScreen(onRechargeSuccess: (amt) => addCoins(amt))),
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
                    Expanded(
                      child: InkWell(
                        onTap: () => _openPage(PointsCenterScreen(points: points)),
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

// 5. Grid 1: 8 Services
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
                        _buildGridItem(Icons.account_balance_wallet, 'Recharge', Colors.amber, () {
                          _openPage(RechargeScreen(onRechargeSuccess: (amt) => addCoins(amt)));
                        }),
                        _buildGridItem(Icons.storefront, 'Store', Colors.pinkAccent, () {
                          _openPage(StoreScreen(
                            userCoins: coins,
                            onBuyItem: (name, cat, price, icon) {
                              deductCoins(price);
                              addItemToBackpack(name, cat, icon);
                            },
                          ));
                        }),
                        _buildGridItem(Icons.mark_email_unread, 'Invitation', Colors.redAccent, () {
                          _openPage(InvitationScreen(userId: userId));
                        }),
                        _buildGridItem(Icons.backpack, 'Backpack', const Color(0xFF00B0FF), () {
                          _openPage(BackpackScreen(items: myItems, onToggleUse: toggleItemUse));
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildGridItem(Icons.wb_sunny, 'Lucky Island', Colors.green, () {
                          _openPage(LuckyIslandScreen(
                            userCoins: coins,
                            onSpinDeduct: (amt) => deductCoins(amt),
                            onSpinWin: (amt) => addCoins(amt),
                          ));
                        }),
                        _buildGridItem(Icons.military_tech, 'Level', Colors.purpleAccent, () {
                          _openPage(const LevelScreen());
                        }),
                        _buildGridItem(Icons.calendar_month, 'Task', Colors.teal, () {
                          _openPage(TaskScreen(onClaimReward: (amt) => addCoins(amt)));
                        }),
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

            // 6. Grid 2: 7 Management
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
                        _buildGridItem(Icons.record_voice_over, 'Host Center', const Color(0xFF00B0FF), () {
                          _openPage(const HostCenterScreen());
                        }),
                        _buildGridItem(Icons.business_center, 'Agency', const Color(0xFF00B0FF), () {

_openPage(const AgencyCenterPage());
                        }),
                        _buildGridItem(Icons.attach_money, 'Coin Seller', const Color(0xFF00B0FF), () {
                          _openPage(CoinSellerScreen(userCoins: coins));
                        }),
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
                        _buildGridItem(Icons.info_outline, 'About', const Color(0xFF00B0FF), () {
                          _openPage(const AboutScreen());
                        }),
                        const SizedBox(width: 32),
                        _buildGridItem(Icons.settings, 'Setting', const Color(0xFF00B0FF), () {
                          _openPage(SettingsScreen(onLogout: widget.onLogout));
                        }),
                        const SizedBox(width: 32),
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
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
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

// ==================== SUB-SCREENS WITH FULL INTERACTIVE LOGIC ====================

// 1. Social List Screen (Followed / Following / Friends)
class SocialListScreen extends StatefulWidget {
  final String title;
  final int initialCount;
  const SocialListScreen({super.key, required this.title, required this.initialCount});

  @override
  State<SocialListScreen> createState() => _SocialListScreenState();
}

class _SocialListScreenState extends State<SocialListScreen> {
  late List<bool> followedStates;

  @override
  void initState() {
    super.initState();
    followedStates = List.generate(10, (index) => true);
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          final isFollowing = followedStates[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade200,
              child: Text('U${index + 1}'),
            ),
            title: Text('User_${index + 1024}'),
            subtitle: Text('ID: ${889900 + index}'),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing ? Colors.grey.shade300 : const Color(0xFF00B0FF),
                foregroundColor: isFollowing ? Colors.black87 : Colors.white,
              ),
              onPressed: () {
                setState(() => followedStates[index] = !isFollowing);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isFollowing ? 'ከተከታይነት ተሰርዟል' : 'ተከታትለዋል')),
                );
              },
              child: Text(isFollowing ? 'Following' : '+ Follow'),
            ),
          );
        },
      ),
    );
  }
}

// 2. VIP Club Screen
class VipClubScreen extends StatelessWidget {
  final VoidCallback onSubscribe;
  const VipClubScreen({super.key, required this.onSubscribe});

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
                  Text('የየዕለቱ 5,000 ነፃ ኮይኖች፣ የወርቅ ባጅ እና ልዩ የመግቢያ አኒሜሽን', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                onSubscribe();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('እንኳን ደስ አለዎት! VIP አባል ሆነዋል፤ 5,000 ነፃ ኮይን ተቀብለዋል!')),
                );
                Navigator.pop(context);
              },
              child: const Text('አሁን VIP ሁን (5,000 Free Coins)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. Points Center Screen (ሆስት ነጥብ ማስተዳደሪያ)
class PointsCenterScreen extends StatelessWidget {
  final double points;
  const PointsCenterScreen({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Points & Earnings')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(

width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1A29),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('የተሰበሰበ ጠቅላላ ነጥብ', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('$points Points', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
                  const SizedBox(height: 4),
                  Text('ተመጣጣኝ ዋጋ: \$${(points / 10000).toStringAsFixed(2)} USD', style: const TextStyle(color: Colors.white54)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ACC1),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('የወጪ ጥያቄዎ ለኤጀንሲ አስተዳዳሪ ተልኳል!')));
              },
              icon: const Icon(Icons.outbox, color: Colors.white),
              label: const Text('ነጥብ ወደ ብር ቀይር (Withdraw)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// 4. Store Screen (እውነተኛ ግዢ የሚሰራ)
class StoreScreen extends StatefulWidget {
  final int userCoins;
  final Function(String name, String category, int price, IconData icon) onBuyItem;
  const StoreScreen({super.key, required this.userCoins, required this.onBuyItem});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  int activeCategory = 0;
  final List<String> categories = ['Popular', 'Frame', 'Entry', 'Theme', 'ChatBubble'];

  final List<Map<String, dynamic>> storeItems = [
    {'name': 'Iron Claw', 'coins': 10000, 'category': 'Entry', 'icon': Icons.pets, 'color': Colors.blue},
    {'name': 'Stellaphant', 'coins': 20000, 'category': 'Entry', 'icon': Icons.shield, 'color': Colors.amber},
    {'name': 'Metropolis Lord', 'coins': 15000, 'category': 'Frame', 'icon': Icons.circle_outlined, 'color': Colors.deepOrange},
    {'name': 'Fighter Frame', 'coins': 12000, 'category': 'Frame', 'icon': Icons.star_border, 'color': Colors.purple},
    {'name': 'Neon City Theme', 'coins': 8000, 'category': 'Theme', 'icon': Icons.apartment, 'color': Colors.teal},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFC),
      appBar: AppBar(
        title: const Text('Store'),
        actions: [
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text('${widget.userCoins}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: List.generate(categories.length, (index) {
                    return InkWell(

onTap: () => setState(() => activeCategory = index),
                      child: Chip(
                        backgroundColor: activeCategory == index ? const Color(0xFF00E5FF) : Colors.grey.shade100,
                        label: Text(
                          categories[index],
                          style: TextStyle(
                            color: activeCategory == index ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: storeItems.length,
              itemBuilder: (context, index) {
                final item = storeItems[index];
                return Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Icon(item['icon'] as IconData, size: 48, color: item['color'] as Color),
                      const SizedBox(height: 6),
                      Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('${item['coins']} Coins', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B0FF)),
                        onPressed: () {
                          if (widget.userCoins >= (item['coins'] as int)) {
                            widget.onBuyItem(
                              item['name'] as String,
                              item['category'] as String,
                              item['coins'] as int,
                              item['icon'] as IconData,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${item['name']} ተገዝቷል! በ Backpack ውስጥ ያገኙታል')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('በቂ ኮይን የለዎትም! እባክዎ መጀመሪያ ይሙሉ')),
                            );
                          }
                        },
                        child: const Text('ግዛ (Buy)', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// 5. Backpack Screen (የገዛሃቸውን እቃዎች Use/Unuse ማድረግ)
class BackpackScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Function(int) onToggleUse;
  const BackpackScreen({super.key, required this.items, required this.onToggleUse});

  @override
  State<BackpackScreen> createState() => _BackpackScreenState();
}

class _BackpackScreenState extends State<BackpackScreen> {
  int tabIndex = 0;
  final List<String> categories = ['Theme', 'Room Card', 'Room Frame', 'Profile Card', 'ChatBubble', 'Entry'];

  @override
  Widget build(BuildContext context) {
    final currentCategory = categories[tabIndex];
    final filteredItems = widget.items.where((it) => it['category'] == currentCategory).toList();

return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: const Text('Backpack'),
        backgroundColor: const Color(0xFF00E5FF),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF00E5FF),
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final bool isSelected = tabIndex == index;
                return Center(
                  child: InkWell(
                    onTap: () => setState(() => tabIndex = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        categories[index],
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF00B0FF) : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: filteredItems.isEmpty
                  ? const Center(child: Text('በዚህ ምድብ ውስጥ የተያዘ እቃ የለም። በመደብር ይግዙ!', style: TextStyle(color: Colors.black45)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, idx) {
                        final item = filteredItems[idx];
                        final globalIndex = widget.items.indexOf(item);
                        final bool inUse = item['inUse'] as bool;
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FBFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: inUse ? Colors.green : Colors.black12, width: 1.5),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Icon(item['icon'] as IconData, size: 44, color: const Color(0xFF00B0FF)),
                              const SizedBox(height: 6),
                              Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: inUse ? Colors.green : Colors.grey.shade400,
                                ),
                                onPressed: () {
                                  widget.onToggleUse(globalIndex);
                                  setState(() {});
                                },

child: Text(inUse ? 'ጥቅም ላይ ነው (In Use)' : 'ተጠቀም (Use)', style: const TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// 6. Lucky Island Screen (የሚሽከረከር እውነተኛ Wheel Game)
class LuckyIslandScreen extends StatefulWidget {
  final int userCoins;
  final Function(int) onSpinDeduct;
  final Function(int) onSpinWin;
  const LuckyIslandScreen({super.key, required this.userCoins, required this.onSpinDeduct, required this.onSpinWin});

  @override
  State<LuckyIslandScreen> createState() => _LuckyIslandScreenState();
}

class _LuckyIslandScreenState extends State<LuckyIslandScreen> {
  String gameResult = 'ኮይን መድበህ አሽከርክርና ዕድልህን ሞክር!';
  bool isSpinning = false;

  void playSpin() async {
    if (widget.userCoins < 500) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ለማሽከርከር ቢያንስ 500 ኮይን ያስፈልጋል!')));
      return;
    }
    setState(() {
      isSpinning = true;
      gameResult = 'በማሽከርከር ላይ...';
    });
    widget.onSpinDeduct(500);

    await Future.delayed(const Duration(seconds: 2));

    final rewards = [0, 200, 500, 1000, 2500, 5000];
    final won = rewards[Random().nextInt(rewards.length)];

    if (won > 0) {
      widget.onSpinWin(won);
      setState(() {
        isSpinning = false;
        gameResult = 'እንኳን ደስ አለዎት! $won ኮይን አሸንፈዋል! 🎉';
      });
    } else {
      setState(() {
        isSpinning = false;
        gameResult = 'አላሸነፉም! እንደገና ይሞክሩ።';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lucky Island Wheel')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedRotation(
                turns: isSpinning ? 5 : 0,
                duration: const Duration(seconds: 2),
                child: const Icon(Icons.casino, size: 100, color: Colors.green),
              ),
              const SizedBox(height: 20),
              Text(gameResult, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text('ቀሪ ሂሳብ: ${widget.userCoins} Coins', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(200, 48),
                ),
                onPressed: isSpinning ? null : playSpin,
                child: const Text('በ 500 ኮይን አሽክርክር (Spin)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 7. Daily Task Screen (Claim ማድረጊያ)
class TaskScreen extends StatefulWidget {
  final Function(int) onClaimReward;
  const TaskScreen({super.key, required this.onClaimReward});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final List<Map<String, dynamic>> tasks = [
    {'title': 'በቀጥታ ድምፅ ክፍል 10 ደቂቃ መቆየት', 'reward': 100, 'claimed': false},
    {'title': '1 ስጦታ ለጓደኛ መላክ', 'reward': 200, 'claimed': false},
    {'title': 'አፑን ለጓደኞች ማጋራት', 'reward': 500, 'claimed': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Tasks')),
      body: ListView.builder(

padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final t = tasks[index];
          final claimed = t['claimed'] as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('+${t['reward']} Coins', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: claimed ? Colors.grey : const Color(0xFF00B0FF),
                  ),
                  onPressed: claimed
                      ? null
                      : () {
                          setState(() => t['claimed'] = true);
                          widget.onClaimReward(t['reward'] as int);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${t['reward']} ኮይን ተቀብለዋል!')),
                          );
                        },
                  child: Text(claimed ? 'ተወስዷል' : 'Claim'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// 8. Coin Seller Screen (ወኪል መሆንና መሸጥ)
class CoinSellerScreen extends StatelessWidget {
  final int userCoins;
  const CoinSellerScreen({super.key, required this.userCoins});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coin Seller Center')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  const Text('የእርስዎ የሽያጭ ኮይን ቀሪ', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text('$userCoins Coins', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber)),
                  const Divider(height: 24),
                  const Text('10,000 Coins = 130 ETB (በቴሌብር ይላካል)', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ACC1),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('የሽያጭ ማመልከቻዎ ለዋናው ሲስተም ቀርቧል!')));
              },
              child: const Text('የኮይን መሸጫ ጥያቄ ላክ (Submit Offer)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// 9. Support Screen (የእርዳታ መልእክት መላኪያ)
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController msgController = TextEditingController();

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support & Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: msgController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'ያጋጠመዎትን ችግር ወይም አስተያየት እዚህ ይጻፉ...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B0FF),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                if (msgController.text.isNotEmpty) {
                  msgController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('መልእክትዎ ደርሶናል፤ በፍጥነት ምላሽ እንሰጣለን!')));
                }
              },
              child: const Text('መልእክት ላክ (Send Message)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// 10. About Screen (ስለ አፑ መረጃ)
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic, size: 70, color: Color(0xFF00B0FF)),
            const SizedBox(height: 10),
            const Text('Voice App Pro', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('Version 1.0.2 (2026)', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('አፕሊኬሽኑ በቅርብ ጊዜው ስሪት (Latest Version) ላይ ይገኛል!')));
              },
              child: const Text('ዝማኔዎችን ፈትሽ (Check for Updates)'),
            ),
          ],
        ),
      ),
    );
  }
}

// 11. Settings Screen
class SettingsScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const SettingsScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(leading: Icon(Icons.notifications), title: Text('የመልእክት ማሳወቂያዎች (Notifications)')),
          const ListTile(leading: Icon(Icons.lock), title: Text('የአካውንት ደህንነት እና ፓስወርድ')),
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

// 12. Network Line Screen (የሰርቨር መስመር መምረጫ)
class NetworkLineScreen extends StatefulWidget {
  const NetworkLineScreen({super.key});

  @override
  State<NetworkLineScreen> createState() => _NetworkLineScreenState();
}

class _NetworkLineScreenState extends State<NetworkLineScreen> {
  int selected = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Line')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RadioListTile<int>(

value: 1,
            groupValue: selected,
            title: const Text('Line 1 (Auto Fast - Ethiopia Local)'),
            subtitle: const Text('Ping: 38 ms (Excellent)', style: TextStyle(color: Colors.green)),
            onChanged: (v) => setState(() => selected = v!),
          ),
          RadioListTile<int>(
            value: 2,
            groupValue: selected,
            title: const Text('Line 2 (East Africa Server)'),
            subtitle: const Text('Ping: 65 ms (Good)', style: TextStyle(color: Colors.green)),
            onChanged: (v) => setState(() => selected = v!),
          ),
          RadioListTile<int>(
            value: 3,
            groupValue: selected,
            title: const Text('Line 3 (Global Backup)'),
            subtitle: const Text('Ping: 140 ms (Normal)', style: TextStyle(color: Colors.orange)),
            onChanged: (v) => setState(() => selected = v!),
          ),
        ],
      ),
    );
  }
}

// 13. Host Center Screen
class HostCenterScreen extends StatelessWidget {
  const HostCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host Center')),
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
                  Column(children: [Text('የዛሬ ስርጭት ሰዓት', style: TextStyle(color: Colors.black54)), Text('3h 15m', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                  Column(children: [Text('የተሰበሰበ ነጥብ', style: TextStyle(color: Colors.black54)), Text('23,902', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00B0FF)))]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 14. Level Screen (Wealth & Charm)
class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  int tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool isWealth = tabIndex == 0;
    return Scaffold(
      backgroundColor: isWealth ? const Color(0xFF0D2826) : const Color(0xFF200F29),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => setState(() => tabIndex = 0),
              child: Text('Wealth', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isWealth ? Colors.white : Colors.white38)),
            ),
            const SizedBox(width: 24),
            InkWell(
              onTap: () => setState(() => tabIndex = 1),
              child: Text('Charm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: !isWealth ? Colors.white : Colors.white38)),
            ),
          ],
        ),
        actions: const [SizedBox(width: 48)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isWealth ? [const Color(0xFF134E4A), const Color(0xFF065F46)] : [const Color(0xFF4A148C), const Color(0xFF311B92)],

),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isWealth ? 'Lv.18' : 'Lv.14', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(isWealth ? 'Current Wealth Value 2287851' : 'Current Charm Value 466150', style: const TextStyle(color: Color(0xFF80DEEA), fontSize: 13)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: isWealth ? 0.75 : 0.60, color: isWealth ? const Color(0xFF26C6DA) : Colors.pinkAccent, minHeight: 6),
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

// 15. Recharge Screen
class RechargeScreen extends StatefulWidget {
  final Function(int) onRechargeSuccess;
  const RechargeScreen({super.key, required this.onRechargeSuccess});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  int method = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recharge (ኮይን መሙያ)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildMethod(0, 'Epay (Telebirr/CBE)'),
                const SizedBox(width: 12),
                _buildMethod(1, 'USDT Crypto'),
              ],
            ),
            const SizedBox(height: 24),
            _buildBox('70,000 Coins', '100 ETB', 70000),
            _buildBox('210,000 Coins', '300 ETB', 210000),
            _buildBox('350,000 Coins', '500 ETB', 350000),
          ],
        ),
      ),
    );
  }

  Widget _buildMethod(int index, String title) {
    final isSelected = method == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => method = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF00B0FF) : Colors.black12, width: 2),
          ),
          child: Center(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _buildBox(String coins, String price, int amt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(coins, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B0FF)),
            onPressed: () {
              widget.onRechargeSuccess(amt);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$coins በተሳካ ሁኔታ ተሞልቷል!')));
            },
            child: Text(price, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// 16. Invitation Screen
class InvitationScreen extends StatelessWidget {
  final String userId;
  const InvitationScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {

return Scaffold(
      appBar: AppBar(title: const Text('Invitation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.share, size: 70, color: Color(0xFF00B0FF)),
              const SizedBox(height: 16),
              Text('የእርስዎ መጋበዣ ኮድ: $userId', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                icon: const Icon(Icons.copy, color: Colors.white),
                label: const Text('ኮድ ገልብጥ (Copy Code)', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B0FF)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: userId));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ኮድ ተገልብጧል!')));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 17. Badges Screen
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

// 18. Message Screen
class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  int tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            InkWell(
              onTap: () => setState(() => tabIndex = 0),
              child: Text('All', style: TextStyle(color: tabIndex == 0 ? Colors.black87 : Colors.black38)),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () => setState(() => tabIndex = 1),
              child: Text('Unread', style: TextStyle(color: tabIndex == 1 ? Colors.black87 : Colors.black38)),
            ),
          ],
        ),
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: CircleAvatar(backgroundColor: Color(0xFF00B0FF), child: Icon(Icons.chat, color: Colors.white)),
            title: Text('System Message'),
            subtitle: Text('Withdrawal received'),
          ),
          ListTile(
            leading: CircleAvatar(backgroundColor: Color(0xFF26A69A), child: Icon(Icons.notifications, color: Colors.white)),
            title: Text('Official Notification'),
            subtitle: Text('New event is live!'),
          ),
        ],
      ),
    );
  }
}

// 19. Retro Room Screen (Host Live Room)
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
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
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
        title: const Text('VIP Live Room', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: EdgeInsets.all(isMuted ? 4 : 4 + (_pulseController.value * 8)),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: isMuted ? [] : [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.6 * _pulseController.value), blurRadius: 20, spreadRadius: 6)],
                  ),
                  child: child,
                );
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0xFF26C6DA), Color(0xFF00838F)]),
                ),
                child: Center(
                  child: Icon(isMuted ? Icons.mic_off : Icons.mic, size: 50, color: isMuted ? Colors.redAccent : Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Host Active', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: const Color(0xFF1E1A29),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('የድምፅ ክፍል ክፍት ነው', style: TextStyle(color: Colors.white70)),
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
}
