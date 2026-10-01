import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'store_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HalaSuperApp());
}

// Global state for simple demonstration across devices
class AppData {
  static String currentUserId = "1000"; // ברירת מחדል: 1000 (Owner) ወይም 1001 (User)
  static String currentUserName = "KEDIR (Owner)";
  static int userCoins = 1500;
  static bool isSuperAdmin = true;
  static String selectedCountry = 'Global';
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
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({Key? key}) : super(key: key);

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  // የሚገኙ ክፍሎች ዝርዝር
  final List<Map<String, dynamic>> rooms = [
    {
      'id': 'room_101',
      'title': '👑 Habesha Lounge VIP',
      'host': 'KEDIR',
      'country': 'Ethiopia',
      'users': '12',
    },
    {
      'id': 'room_102',
      'title': '🎵 Arabic & Global Melody',
      'host': 'Amir',
      'country': 'Saudi Arabia',
      'users': '8',
    },
  ];

  void _switchUserRole(bool asOwner) {
    setState(() {
      if (asOwner) {
        AppData.currentUserId = "1000";
        AppData.currentUserName = "KEDIR (Owner)";
        AppData.userCoins = 50000;
        AppData.isSuperAdmin = true;
      } else {
        AppData.currentUserId = "1001";
        AppData.currentUserName = "Guest User";
        AppData.userCoins = 100; // ተጠቃሚው አነስተኛ ኮይን አለው
        AppData.isSuperAdmin = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to: ${AppData.currentUserName} (ID: ${AppData.currentUserId})'),
        backgroundColor: asOwner ? Colors.green : Colors.blueGrey,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F121C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.mic_external_on, color: Color(0xFF00E676)),
            const SizedBox(width: 8),
            Text(
              AppData.currentUserName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // ኮይን ባላንስ ማሳያ
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF232A3B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${AppData.userCoins}',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),

),
              ],
            ),
          ),
          // የመቀየሪያ ቁልፍ (በሁለቱ ስልኮች ሚና ለመቀያየር)
          PopupMenuButton<bool>(
            icon: const Icon(Icons.switch_account, color: Colors.white70),
            tooltip: 'Switch Account Role',
            onSelected: _switchUserRole,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: true,
                child: Text('Login as Owner (KEDIR)'),
              ),
              const PopupMenuItem(
                value: false,
                child: Text('Login as Regular User (Guest)'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. የስቶር (Store) ቁልፍ
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoreScreen(
                      userCoins: AppData.userCoins,
                      onCoinsUpdated: (newCoins) {
                        setState(() {
                          AppData.userCoins = newCoins;
                        });
                      },
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C9A7), Color(0xFF00897B)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C9A7).withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.storefront, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Open Hala Store 🛍️',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 2. የአድሚን ፖርታል ቁልፍ (ለ Owner ብቻ የሚፈቀድ)
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
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,

children: [
                      Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Master Admin Portal 👑',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // 3. የክፍሎች (Voice Rooms) ዝርዝር
            const Text(
              'Live Voice Rooms',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),

            ...rooms.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161A28),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF1E2433),
                      child: Icon(Icons.graphic_eq, color: Color(0xFF00E676)),
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
                        backgroundColor: const Color(0xFF00E676),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        // ወደ ክፍሉ መግባት
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VoiceRoomScreen(
                              channelName: r['id'],
                              roomTitle: r['title'],
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
      ),
    );
  }
}

// ==========================================
// 🎙️ የድምፅ ማስተላለፊያ ክፍል (Voice Room Screen)
// ==========================================
class VoiceRoomScreen extends StatefulWidget {
  final String channelName;
  final String roomTitle;

  const VoiceRoomScreen({
    Key? key,
    required this.channelName,
    required this.roomTitle,
  }) : super(key: key);

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> {
  late RtcEngine _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  final List<int> _remoteUsers = [];

  // አጎራ App ID (የራስህን ካለህ መተካት ትችላለህ)
  final String _appId = "aab8b8f3e2444379a1f28b4d82b3d888"; 

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    // 1. የማይክሮፎን ፈቃድ መጠየቅ
    await [Permission.microphone].request();

    // 2. Agora Engine ማስጀመር
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: _appId));

_engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _isJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUsers.add(remoteUid);
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() {
            _remoteUsers.remove(remoteUid);
          });
        },
      ),
    );

    // 3. ድምፅ እንዲያስተላልፍ Live Broadcasting ፕሮፋይል ማዘጋጀት
    await _engine.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableAudio();

    // 4. ወደ ቻናሉ መቀላቀል
    await _engine.joinChannel(
      token: '',
      channelId: widget.channelName,
      uid: Random().nextInt(900000) + 100000,
      options: const ChannelMediaOptions(
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine.muteLocalAudioStream(_isMuted);
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F121C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        title: Text(widget.roomTitle, style: const TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          // ሁኔታ ማሳያ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isJoined ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isJoined ? '● Connected to Voice Room' : 'Connecting...',
              style: TextStyle(
                color: _isJoined ? Colors.greenAccent : Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 30),

          // በማይክ ላይ ያሉ ተጠቃሚዎች መቀመጫ (Seats)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 8,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 14,
                mainAxisSpacing: 20,
              ),
              itemBuilder: (context, index) {
                bool isMe = index == 0;
                bool hasRemote = index == 1 && _remoteUsers.isNotEmpty;

                return Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: (isMe || hasRemote) ? const Color(0xFF00E676) : const Color(0xFF1E2433),
                      child: Icon(
                        (isMe || hasRemote) ? Icons.mic : Icons.lock_open,
                        color: (isMe || hasRemote) ? Colors.black : Colors.white30,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isMe ? 'You' : (hasRemote ? 'Speaker' : 'Seat ${index + 1}'),
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                );
              },
            ),
          ),

// የታችኛው የማይክ እና የመውጫ መቆጣጠሪያ
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF161B26),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _toggleMute,
                  iconSize: 32,
                  icon: Icon(
                    _isMuted ? Icons.mic_off : Icons.mic,
                    color: _isMuted ? Colors.red : const Color(0xFF00E676),
                  ),
                ),
                IconButton(
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
                          },
                        ),
                      ),
                    );
                  },
                  iconSize: 32,
                  icon: const Icon(Icons.card_giftcard, color: Colors.amber),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  iconSize: 32,
                  icon: const Icon(Icons.call_end, color: Colors.redAccent),
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
        SnackBar(content: Text("$amount Coins successfully minted!"), backgroundColor: Colors.green),
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
      backgroundColor: const Color(0xFF0F121C),
      appBar: AppBar(
        title: const Text('Super Owner Admin Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                          Text('Master System Reserve', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('${AppData.userCoins} Coins', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Admin / Owner ID: 1000', style: TextStyle(color: Colors.white60, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('1. Coin Minting Engine (Generate New Coins)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                const Text('2. Credit Coins to User Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
