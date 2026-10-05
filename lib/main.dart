import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'store_screen.dart';
import 'coin_seller_screen.dart';
import 'agency_screen.dart';
import 'room_screen.dart';
import 'face_and_room_screen.dart';
import 'host_center_screen.dart';
import 'settings_screen.dart';
import 'level_screen.dart';
import 'support_screen.dart';
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
      title: 'Nile Voice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00C9A7),
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        fontFamily: 'Roboto',
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

  void _updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      RoomsHomeScreen(onCoinsUpdated: _updateState),
      const MessagesScreen(),
      ProfileScreen(onCoinsUpdated: _updateState),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF161B26),
        selectedItemColor: const Color(0xFF00C9A7),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
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

// ============================================================================
// 1. ROOMS HOME SCREEN
// ============================================================================
class RoomsHomeScreen extends StatelessWidget {
  final VoidCallback onCoinsUpdated;

  const RoomsHomeScreen({Key? key, required this.onCoinsUpdated}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> rooms = [
      {
        'id': '101',
        'title': '🇪🇹 Ethio Nile Coffee Club',
        'host': 'Mimi',
        'users': 48,
        'tag': 'Chat & Music',
        'color': const Color(0xFF1E2638),
      },
      {
        'id': '102',
        'title': '🎤 Golden Voices Lounge',
        'host': 'Yared',
        'users': 32,
        'tag': 'Live Singing',
        'color': const Color(0xFF261E38),
      },
      {
        'id': '103',
        'title': '🎉 Night Party & Games',
        'host': 'Sara',
        'users': 85,
        'tag': 'Gaming',
        'color': const Color(0xFF1E382E),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        title: const Text('Nile Voice 🎙️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),

IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final r = rooms[index];
          return Card(
            color: r['color'],
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
               Navigator.push(
                  context,
                 MaterialPageRoute(
                   builder: (context) => FaceAndRoomScreen(
                     userId: AppData.currentUserId,
                     baseUrl: 'http://localhost:3000/api',
                   ),
                  ),
                 );
                },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF00C9A7),
                      child: Text(
                        r['host'][0],
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('Host: ${r['host']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(r['tag'], style: const TextStyle(color: Color(0xFF00C9A7), fontSize: 10)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.volume_up, color: Color(0xFF00C9A7), size: 16),
                        const SizedBox(width: 4),
                        Text('${r['users']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00C9A7),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveVoiceRoomScreen(
                roomId: '999',
                roomTitle: '${AppData.currentUserName}\'s Room',
                hostName: AppData.currentUserName,
                onCoinsUpdated: onCoinsUpdated,
              ),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
    );
  }
}

// ============================================================================
// 2. ACTIVE VOICE ROOM SCREEN
// ============================================================================
class ActiveVoiceRoomScreen extends StatelessWidget {
  final String roomId;
  final String roomTitle;
  final String hostName;
  final VoidCallback onCoinsUpdated;

  const ActiveVoiceRoomScreen({
    Key? key,
    required this.roomId,
    required this.roomTitle,
    required this.hostName,
    required this.onCoinsUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(roomTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF00C9A7),
                  child: const Icon(Icons.mic, size: 40, color: Colors.black),
                ),
                const SizedBox(height: 10),
                Text(hostName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('Active Speaker', style: TextStyle(fontSize: 12, color: Color(0xFF00C9A7))),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF161B26),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(icon: const Icon(Icons.mic_off, color: Colors.white70), onPressed: () {}),
                IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.amber), onPressed: () {}),
                IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.white70), onPressed: () {}),
                IconButton(icon: const Icon(Icons.share, color: Colors.white70), onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. MESSAGES SCREEN
// ============================================================================
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 12),
            Text('No new messages', style: TextStyle(color: Colors.white54, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 4. PROFILE SCREEN (ME)
// ============================================================================
class ProfileScreen extends StatefulWidget {
  final VoidCallback onCoinsUpdated;

  const ProfileScreen({Key? key, required this.onCoinsUpdated}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: Color(0xFF00C9A7),
                        child: Icon(Icons.person, color: Colors.black, size: 38),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppData.currentUserName,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text('ID: ${AppData.currentUserId}', style: const TextStyle(fontSize: 13, color: Colors.white54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 28),
                  
                  // Balance Row with Recharge Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Coins', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text('${AppData.userCoins}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
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
                        icon: const Icon(Icons.add_circle, color: Colors.black, size: 16),

label: const Text('Recharge', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C9A7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        ),
                      ),
                      Column(
                        children: [
                          const Text('Diamonds', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.diamond, color: Colors.cyanAccent, size: 18),
                              const SizedBox(width: 4),
                              Text('${AppData.userPoints}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Coin Seller & Store Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CoinSellerScreen(
                            initialCoins: AppData.userCoins,
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
                    icon: const Icon(Icons.account_balance_wallet, color: Colors.black, size: 18),
                    label: const Text('Coin Seller 🪙', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),

const SizedBox(height: 14),

            // Agency Center Dashboard Button
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E1B0).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.business_center, color: Color(0xFF00E1B0)),
                ),
                title: const Text('Agency Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('Host & Commission Dashboard', style: TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AgencyScreen(
                        agencyName: "Nile Agency Leader",
                        agencyId: "1000",
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
              // 1. Host Center Button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A2BE2), Color(0xFF4A0E4E)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic_external_on, color: Colors.white),
                  ),
                  title: const Text('Host Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Live duration & Host earnings', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HostCenterScreen()),
                    );
                  },
                ),
              ),
            const SizedBox(height: 14),
              // Level (Wealth & Charm) Button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161B26),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.military_tech, color: Colors.amber),
                  ),
                  title: const Text('Level (Wealth & Charm)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Badges, Medals & Upgrades', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LevelScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              // 2. Settings Button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161B26),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings, color: Colors.white70),
                  ),
                  title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              // Support (Help & Feedback) Button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161B26),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.help_outline, color: Colors.purpleAccent),
                  ),
                  title: const Text('Support (Help & Feedback)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('FAQs, Host rules & Ticket support', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SupportScreen()),
                    );
                  },
                ),
              ),
            // Super Admin Portal
            if (AppData.isSuperAdmin)
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE50914), Color(0xFFB80000)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                  title: const Text('Master Admin Portal 👑', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SuperOwnerAdminPortal(),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 5. SUPER OWNER ADMIN PORTAL
// ============================================================================
class SuperOwnerAdminPortal extends StatelessWidget {
  const SuperOwnerAdminPortal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        title: const Text('Master Admin Console', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('👑 Nile Voice Master Authority', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),

SizedBox(height: 6),
                Text('Owner ID: 1000 (Full Root Access Granted)', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: const Color(0xFF161B26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: const Icon(Icons.group, color: Color(0xFF00C9A7)),
            title: const Text('Manage All Users & Hosts', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
            onTap: () {},
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: const Color(0xFF161B26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: const Icon(Icons.monetization_on, color: Colors.amber),
            title: const Text('System Coin Minting & Audit', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
            onTap: () {},
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: const Color(0xFF161B26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: const Icon(Icons.security, color: Colors.blueAccent),
            title: const Text('Security & Server Logs', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
