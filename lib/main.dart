import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'store_screen.dart';
import 'invite_screen.dart';
import 'room_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NileVoiceApp());
}

// Global App State
class AppData {
  static String currentUserId = "1000";
  static String currentUserName = "KEDIR (Super Owner)";
  static int userCoins = 50000;
  static int userPoints = 0;
  static bool isSuperAdmin = true;
  static bool biometricVerified = true;
}

class NileVoiceApp extends StatelessWidget {
  const NileVoiceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nile Voice Global',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D111A),
        primaryColor: const Color(0xFF00C9A7),
        fontFamily: 'sans-serif',
      ),
      home: const NileMainScreen(),
    );
  }
}

class NileMainScreen extends StatefulWidget {
  const NileMainScreen({Key? key}) : super(key: key);

  @override
  State<NileMainScreen> createState() => _NileMainScreenState();
}

class _NileMainScreenState extends State<NileMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const NileRoomsPage(),
      NileProfileMePage(onCoinsUpdated: () => setState(() {})),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF161B26),
        selectedItemColor: const Color(0xFF00C9A7),
        unselectedItemColor: Colors.white54,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.waves),
            label: 'Rooms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 🌊 1. ROOMS PAGE (የክፍሎች ገጽ)
// ==========================================
class NileRoomsPage extends StatefulWidget {
  const NileRoomsPage({Key? key}) : super(key: key);

  @override
  State<NileRoomsPage> createState() => _NileRoomsPageState();
}

class _NileRoomsPageState extends State<NileRoomsPage> {
  final List<Map<String, dynamic>> rooms = [
    {
      'id': 'nile_room_1',
      'title': '🌊 Nile VIP Grand Lounge',
      'host': 'KEDIR',
      'country': 'Ethiopia',
      'users': '24',
    },
    {
      'id': 'nile_room_2',
      'title': '🎵 Nile Melody & Chat',
      'host': 'Amir',
      'country': 'Global',
      'users': '15',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.waves, color: Color(0xFF00C9A7)),
            SizedBox(width: 8),
            Text(
              'Nile Voice',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Explore Live Rooms',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ...rooms.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 12),

decoration: BoxDecoration(
                  color: const Color(0xFF161B26),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF222938),
                    child: Icon(Icons.mic, color: Color(0xFF00C9A7)),
                  ),
                  title: Text(
                    r['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                  subtitle: Text(
                    'Host: ${r['host']} • ${r['country']}',
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C9A7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VoiceRoomScreen(
                            channelName: r['id'],
                            roomTitle: r['title'],
                            isOwner: AppData.isSuperAdmin,
                          ),
                        ),
                      );
                    },
                    child: const Text('Join', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ==========================================
// 👤 2. "ME" PROFILE PAGE (Store, Recharge & Invite)
// ==========================================
class NileProfileMePage extends StatefulWidget {
  final VoidCallback onCoinsUpdated;
  const NileProfileMePage({Key? key, required this.onCoinsUpdated}) : super(key: key);

  @override
  State<NileProfileMePage> createState() => _NileProfileMePageState();
}

class _NileProfileMePageState extends State<NileProfileMePage> {
  void _switchUserRole(bool asOwner) {
    setState(() {
      if (asOwner) {
        AppData.currentUserId = "1000";
        AppData.currentUserName = "KEDIR (Super Owner)";
        AppData.userCoins = 50000;
        AppData.isSuperAdmin = true;
        AppData.biometricVerified = true;
      } else {
        AppData.currentUserId = "1001";
        AppData.currentUserName = "Guest User";
        AppData.userCoins = 100;
        AppData.isSuperAdmin = false;
        AppData.biometricVerified = false;
      }
    });
    widget.onCoinsUpdated();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to: ${AppData.currentUserName}'),
        backgroundColor: asOwner ? Colors.green : Colors.blueGrey,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        title: const Text('My Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<bool>(
            icon: const Icon(Icons.switch_account, color: Colors.white70),
            tooltip: 'Switch Account Role',
            onSelected: _switchUserRole,
            itemBuilder: (context) => [
              const PopupMenuItem(value: true, child: Text('Login as Owner (KEDIR)')),

const PopupMenuItem(value: false, child: Text('Login as Guest User')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFF00C9A7),
                    child: Text(
                      AppData.currentUserName[0],
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppData.currentUserName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${AppData.currentUserId}',
                          style: const TextStyle(fontSize: 13, color: Colors.white54),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              AppData.biometricVerified ? Icons.verified_user : Icons.gpp_maybe,
                              size: 14,
                              color: AppData.biometricVerified ? Colors.greenAccent : Colors.orangeAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppData.biometricVerified ? 'Identity Verified' : 'Unverified Biometrics',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppData.biometricVerified ? Colors.greenAccent : Colors.orangeAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Wallet Balance Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E2838), Color(0xFF141A24)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Coins Balance', style: TextStyle(color: Colors.white54, fontSize: 13)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                              const SizedBox(width: 6),

Text(
                                '${AppData.userCoins}',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Earnings Points', style: TextStyle(color: Colors.white54, fontSize: 13)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.diamond, color: Colors.cyanAccent, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                '${AppData.userPoints}',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Recharge Gateway (Telebirr / CBE) coming next!')),
                            );
                          },
                          icon: const Icon(Icons.account_balance_wallet, color: Colors.black, size: 18),
                          label: const Text('Recharge', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StoreScreen(
                                  userCoins: AppData.userCoins,
                                  onCoinsUpdated: (newCoins) {
                                    setState(() {
                                      AppData.userCoins = newCoins;
                                    });
                                    widget.onCoinsUpdated();
                                  },
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.storefront, color: Colors.white, size: 18),
                          label: const Text('Store 🛍️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C9A7),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

// 🎁 Invite Friends & Earn Banner
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InviteScreen(
                      userId: AppData.currentUserId,
                      userName: AppData.currentUserName,
                      onRewardClaimed: (bonus) {
                        setState(() {
                          AppData.userCoins += bonus;
                        });
                        widget.onCoinsUpdated();
                      },
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00897B), Color(0xFF004D40)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00897B).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.card_giftcard, color: Colors.amber, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invite Friends & Earn Coins 🎁',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'ለእያንዳንዱ ግብዣ 500 Coins ቦነስ ያግኙ',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 👑 Admin Portal Button
            if (AppData.isSuperAdmin)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SuperOwnerAdminPortal()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE50914), Color(0xFF8B0000)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Master Admin Portal 👑',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 👑 Super Owner Admin Portal
// ==========================================
class SuperOwnerAdminPortal extends StatefulWidget {
  const SuperOwnerAdminPortal({Key? key}) : super(key: key);

  @override
  State<SuperOwnerAdminPortal> createState() => _SuperOwnerAdminPortalState();
}

class _SuperOwnerAdminPortalState extends State<SuperOwnerAdminPortal> {
  final TextEditingController _mintController = TextEditingController();
  final TextEditingController _targetIdController = TextEditingController();
  final TextEditingController _transferAmountController = TextEditingController();

  void _mintCoins() {
    int? amount = int.tryParse(_mintController.text.trim());
    if (amount != null && amount > 0) {
      setState(() {
        AppData.userCoins += amount;
      });
      _mintController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$amount Nile Coins minted!"), backgroundColor: Colors.green),
      );
    }
  }

  void _transferCoins() {
    String targetId = _targetIdController.text.trim();
    int? amount = int.tryParse(_transferAmountController.text.trim());

    if (amount == null || amount <= 0) return;
    if (amount > AppData.userCoins) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient reserve balance!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      AppData.userCoins -= amount;
    });

    _targetIdController.clear();
    _transferAmountController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Transferred $amount coins to ID: $targetId"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D111A),
      appBar: AppBar(
        title: const Text('Nile Master Admin Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF161B26),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE50914), Color(0xFF8B0000)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Nile System Reserve', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('${AppData.userCoins} Coins', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Super Owner ID: 1000', style: TextStyle(color: Colors.white60, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Coin Minting Engine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mintController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),

decoration: InputDecoration(
                          hintText: 'Enter amount to mint',
                          filled: true,
                          fillColor: const Color(0xFF1E2433),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _mintCoins,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
                      child: const Text('Mint', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Transfer Coins to User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _targetIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Target User ID (e.g. 1001)',
                    filled: true,
                    fillColor: const Color(0xFF1E2433),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _transferAmountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Coin Amount',
                    filled: true,
                    fillColor: const Color(0xFF1E2433),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _transferCoins,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Transfer to User', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
