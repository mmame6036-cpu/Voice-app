import 'dart:math';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const HalaSuperApp());
}

class HalaSuperApp extends StatelessWidget {
  const HalaSuperApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hala Voice Global',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F121C),
        primaryColor: const Color(0xFF00E676),
        fontFamily: 'sans-serif',
      ),
      home: const SplashScreen(),
    );
  }
}

// ==========================================
// Central App State & Database
// ==========================================
class AppData {
  static const String agoraAppId = "fd2d8b50393b495dab38eb5cf267b393";
  static String userName = "ከድር ኡመር";
  static String userId = "1753925";
  static int followedCount = 3118;
  static int followingCount = 519;
  static int friendsCount = 104;
  static int coins = 1500;
  static double points = 23903.91;
  static String selectedCountry = "All";

  static const List<String> countries = [
    'All', 'Ethiopia 🇪🇹', 'Philippines 🇵🇭', 'Angola 🇦🇴', 
    'Benin 🇧🇯', 'United Kingdom 🇬🇧', 'Ghana 🇬🇭', 'Kenya 🇰🇪', 'Malawi 🇲🇼', 'Rwanda 🇷🇼', 'Burma 🇲🇲'
  ];

  static List<Map<String, dynamic>> rooms = [
    {
      'id': 'room_1042',
      'title': '🇪🇹 ኢትዮጵያ ቮይስ ፓርቲ እና ஃப்ሪ ኮይን',
      'host': 'ከድር ኡመር',
      'category': 'FRIENDS',
      'type': 'Public',
      'users': '4.58k',
      'country': 'Ethiopia 🇪🇹',
    },
    {
      'id': 'room_1043',
      'title': '👑 ቪአይፒ ዳይመንድ ሉኪ ሩም',
      'host': 'ሰላም ሊቭ',
      'category': 'EMOTION',
      'type': 'Public',
      'users': '2.34k',
      'country': 'Philippines 🇵🇭',
    },
  ];

  static List<Map<String, dynamic>> gifts = [
    {'name': 'ሮዝ 🌹', 'price': 50},
    {'name': 'ቡና ☕', 'price': 200},
    {'name': 'ልብ 💖', 'price': 500},
    {'name': 'ስፖርት መኪና 🏎️', 'price': 2500},
    {'name': 'ንግሥና አክሊል 👑', 'price': 10000},
  ];
}

// ==========================================
// 1. Splash Screen
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationHub()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F121C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFF00E676),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, size: 60, color: Colors.black),
            ),
            const SizedBox(height: 20),
            const Text('Hala Voice Global', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. Main Navigation Hub
// ==========================================
class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({Key? key}) : super(key: key);

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _tabIndex = 0;

@override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const PartyHomeScreen(),
      const DiscoverScreen(),
      const MessageHubScreen(),
      const MeProfileScreen(),
    ];

    return Scaffold(
      body: pages[_tabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        backgroundColor: const Color(0xFF131722),
        selectedItemColor: const Color(0xFF00E676),
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Room'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
        ],
      ),
    );
  }
}

// ==========================================
// 3. Party Home Screen
// ==========================================
class PartyHomeScreen extends StatefulWidget {
  const PartyHomeScreen({Key? key}) : super(key: key);

  @override
  State<PartyHomeScreen> createState() => _PartyHomeScreenState();
}

class _PartyHomeScreenState extends State<PartyHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final filteredRooms = AppData.selectedCountry == 'All' 
        ? AppData.rooms 
        : AppData.rooms.where((r) => r['country'] == AppData.selectedCountry).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F121C),
        elevation: 0,
        title: Row(
          children: const [
            Text('Party', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: AppData.countries.length,
              itemBuilder: (context, index) {
                String country = AppData.countries[index];
                bool isSelected = AppData.selectedCountry == country;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(country, style: TextStyle(fontSize: 12, color: isSelected ? Colors.black : Colors.white)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF00E676),
                    backgroundColor: const Color(0xFF161A28),
                    onSelected: (bool selected) {
                      setState(() {
                        AppData.selectedCountry = country;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          ...filteredRooms.map((r) => Card(
            color: const Color(0xFF161A28),
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1E2433),
                child: Icon(Icons.graphic_eq, color: Color(0xFF00E676)),
              ),
              title: Text(r['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('Host: ${r['host']} • ${r['country']}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
              trailing: Text(r['users'], style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),

onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VoiceRoomScreen(roomId: r['id'], title: r['title'])),
                );
              },
            ),
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00E676),
        icon: const Icon(Icons.mic, color: Colors.black),
        label: const Text('Start Room', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VoiceRoomScreen(roomId: 'room_1042', title: 'Live Voice Party')),
          );
        },
      ),
    );
  }
}

// ==========================================
// 4. Voice Room Screen
// ==========================================
class VoiceRoomScreen extends StatefulWidget {
  final String roomId;
  final String title;
  const VoiceRoomScreen({Key? key, required this.roomId, required this.title}) : super(key: key);

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> {
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMicMuted = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: AppData.agoraAppId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _isJoined = true);
        },
      ),
    );
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.enableAudio();
    await _engine!.joinChannel(
      token: '',
      channelId: widget.roomId,
      uid: Random().nextInt(900000) + 100000,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text(_isJoined ? '🟢 Agora Voice Online' : 'Connecting...', style: const TextStyle(color: Colors.white54)),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              padding: const EdgeInsets.all(16),
              children: List.generate(8, (index) {
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: index == 0 ? Colors.amber : const Color(0xFF1E2433),
                      child: Text(index == 0 ? '👑' : '${index + 1}'),
                    ),
                    const SizedBox(height: 4),
                    Text(index == 0 ? 'Host' : 'Seat ${index + 1}', style: const TextStyle(fontSize: 10)),
                  ],
                );
              }),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF131722),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(_isMicMuted ? Icons.mic_off : Icons.mic, color: _isMicMuted ? Colors.red : const Color(0xFF00E676)),

onPressed: () {
                    setState(() => _isMicMuted = !_isMicMuted);
                    _engine?.muteLocalAudioStream(_isMicMuted);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.card_giftcard, color: Colors.amber),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. Discover & Message Screens
// ==========================================
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: const Center(child: Text('Moments and Posts')),
    );
  }
}

class MessageHubScreen extends StatelessWidget {
  const MessageHubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message')),
      body: const Center(child: Text('System and User Messages')),
    );
  }
}

// ==========================================
// 6. Me Profile Screen with Coin Minting & Recharge
// ==========================================
class MeProfileScreen extends StatefulWidget {
  const MeProfileScreen({Key? key}) : super(key: key);

  @override
  State<MeProfileScreen> createState() => _MeProfileScreenState();
}

class _MeProfileScreenState extends State<MeProfileScreen> {
  // Admin Coin Minting Engine Dialog
  void _openAdminCoinEngine() {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161A28),
        title: const Text('🪙 Admin Coin Generation Engine', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('አስተዳዳሪ ሆይ! አዲስ ኮይን አምርተህ ወደ ሲስተሙ ለማስገባት መጠኑን ጻፍ፦', style: TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'የኮይን መጠን (ለምሳሌ 100000)',
                filled: true,
                fillColor: Color(0xFF0F121C),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
            onPressed: () {
              int? val = int.tryParse(amountController.text);
              if (val != null && val > 0) {
                setState(() => AppData.coins += val);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$val ኮይኖች በተሳካ ሁኔታ ተመርተዋል!')));
              }
            },
            child: const Text('አምርት (Generate)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 35, backgroundColor: Colors.amber, child: Text('👑', style: TextStyle(fontSize: 32))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppData.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

const SizedBox(height: 4),
                    Text('ID:${AppData.userId}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Coin & Minting Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF161A28), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _openAdminCoinEngine,
                    child: Column(
                      children: [
                        const Text('Coins (ኮይን ለማመንጨት ንካ)', style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${AppData.coins}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                      ],
                    ),
                  ),
                ),
                Container(height: 30, width: 1, color: Colors.white12),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Points', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text('${AppData.points}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Main Grids
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _gridMenu(context, Icons.account_balance_wallet, 'Recharge', Colors.amber, const RechargeScreen()),
              _gridMenu(context, Icons.store, 'Store', Colors.purpleAccent, const GenericScreen(title: 'Store')),
              _gridMenu(context, Icons.business_center, 'Agency', Colors.teal, const GenericScreen(title: 'Agency')),
              _gridMenu(context, Icons.precision_manufacturing, 'Coin Engine', Colors.greenAccent, null, onTap: _openAdminCoinEngine),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gridMenu(BuildContext context, IconData icon, String label, Color color, Widget? target, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => Navigator.push(context, MaterialPageRoute(builder: (_) => target!)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(radius: 22, backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color, size: 22)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }
}

// ==========================================
// 7. Recharge Screen (ID, Country, 20% Off, Epeay/USDT, Packages)
// ==========================================
class RechargeScreen extends StatefulWidget {
  const RechargeScreen({Key? key}) : super(key: key);

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final TextEditingController _idController = TextEditingController(text: AppData.userId);
  String _selectedCountry = 'All country';
  String _selectedPayment = 'USDT';
  int _selectedPackage = 0;

  final List<Map<String, dynamic>> _packages = [
    {'coins': 70000, 'price': 5},
    {'coins': 210000, 'price': 30},
    {'coins': 350000, 'price': 50},
  ];

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recharge Center')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 20% Off Official Agency Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00B0FF)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '% official Agency Recharge 20% off',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          // User ID Input
          const Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 6),
          TextField(
            controller: _idController,
            decoration: InputDecoration(
              hintText: 'Enter ID',
              filled: true,
              fillColor: const Color(0xFF161A28),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          // Country / Region
          const Text('Country / Region', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xFF161A28), borderRadius: BorderRadius.circular(10)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountry,
                dropdownColor: const Color(0xFF161A28),
                items: ['All country', 'Ethiopia 🇪🇹', 'Philippines 🇵🇭', 'Kenya 🇰🇪'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                onChanged: (val) => setState(() => _selectedCountry = val!),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Payment Options (Epeay / USDT)
          const Text('Recharge Gateway', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            children: [
              _payOption('Epeay'),
              const SizedBox(width: 12),
              _payOption('USDT'),
            ],
          ),
          const SizedBox(height: 16),
          // Packages (70000 Coins / 5$, 210000 Coins / 30$, 350000 Coins / 50$)
          const Text('Coin Packages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 8),
          Column(
            children: List.generate(_packages.length, (i) {
              var p = _packages[i];
              bool isSel = _selectedPackage == i;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF161A28),
                  border: Border.all(color: isSel ? const Color(0xFF00E676) : Colors.transparent, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.monetization_on, color: Colors.amber),
                  title: Text('${p['coins']} Coins', style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text('\$${p['price']}', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 16)),

onTap: () => setState(() => _selectedPackage = i),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Confirm Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              int added = _packages[_selectedPackage]['coins'];
              setState(() => AppData.coins += added);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ID ${_idController.text} ላይ $added Coins በተሳካ ሁኔታ ተሞልቷል!')),
              );
              Navigator.pop(context);
            },
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _payOption(String name) {
    bool isSel = _selectedPayment == name;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPayment = name),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF00E676).withOpacity(0.2) : const Color(0xFF161A28),
            border: Border.all(color: isSel ? const Color(0xFF00E676) : Colors.white12),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? const Color(0xFF00E676) : Colors.white)),
        ),
      ),
    );
  }
}

// ==========================================
// 8. Generic Screen
// ==========================================
class GenericScreen extends StatelessWidget {
  final String title;
  const GenericScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title Screen')),
    );
  }
}
