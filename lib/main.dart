import 'dart:math';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const FullVoiceApp());
}

class FullVoiceApp extends StatelessWidget {
  const FullVoiceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Live & Agency Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0B18),
        primaryColor: const Color(0xFF7B2CBF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161228),
          elevation: 0,
        ),
      ),
      home: const MainHomeScreen(),
    );
  }
}

// ==========================================
// 1. የዳታ ማዕከል (Global State)
// ==========================================
class AppData {
  static const String agoraAppId = "fd2d8b50393b495dab38eb5cf267b393";
  static const String channelName = "room_1042";

  static int userCoins = 50000;
  static int hostPoints = 120000;
  static List<Map<String, dynamic>> cashoutRequests = [];
  static List<Map<String, dynamic>> agencyHosts = [
    {'name': 'Sara Voice', 'id': '10021', 'points': 45000, 'status': 'Active'},
    {'name': 'Abebe Live', 'id': '10045', 'points': 75000, 'status': 'Active'},
    {'name': 'Mahi Music', 'id': '10089', 'points': 20000, 'status': 'Pending'},
  ];
}

// ==========================================
// 2. ዋናው ማውጫ (Home Navigation)
// ==========================================
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({Key? key}) : super(key: key);

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardView(onUpdated: _refresh),
      VoiceRoomView(onUpdated: _refresh),
      const AgencyManagementView(),
      ProfileWalletView(onUpdated: _refresh),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF140F26),
        selectedItemColor: const Color(0xFF9D4EDD),
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'ዳሽቦርድ'),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'ሩም'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'ኤጀንሲ'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'ዋሌት'),
        ],
      ),
    );
  }
}

// ==========================================
// 3. የዳሽቦርድ ገጽ (Dashboard View)
// ==========================================
class DashboardView extends StatelessWidget {
  final VoidCallback onUpdated;
  const DashboardView({Key? key, required this.onUpdated}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Voice Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
            tooltip: 'Admin Panel',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminPanelScreen(onUpdated: onUpdated)),
            ),
          ),
        ],
      ),

body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5A189A), Color(0xFF240046)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('የእርስዎ ሳንቲም', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('${AppData.userCoins} 🪙', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    ],
                  ),
                  Container(width: 1, height: 45, color: Colors.white24),
                  Column(
                    children: [
                      const Text('የሆስት ፖይንት', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('${AppData.hostPoints} 💎', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('ተወዳጅ ክፍሎችና ጨዋታዎች', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 14),
            _buildActionCard(
              context,
              title: 'የቀጥታ ድምፅ ክፍል (Live Room)',
              desc: 'ይግቡ፣ ማይክ ይያዙ፣ በቀጥታ ይናገሩ',
              icon: Icons.record_voice_over,
              gradient: [const Color(0xFF7209B7), const Color(0xFF3F37C9)],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VoiceRoomView(onUpdated: onUpdated)),
              ),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              title: 'ፒራሚድ ማይኒንግ (Safe Mini Game)',
              desc: 'ዕድልዎን ይፈትሹ (ከነ RTP እና የማሸነፊያ ገደብ)',
              icon: Icons.casino,
              gradient: [const Color(0xFFF72585), const Color(0xFF7209B7)],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PyramidMiniGame(onUpdated: onUpdated)),
              ),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              title: 'የኤጀንሲ አስተዳዳሪ (Agency Manager)',
              desc: 'የሆስቶችን ገቢ እና እንቅስቃሴ ይቆጣጠሩ',
              icon: Icons.shield,
              gradient: [const Color(0xFF1E3C72), const Color(0xFF2A5298)],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AgencyManagementView()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String desc, required IconData icon, required List<Color> gradient, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),

decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.white24, radius: 26, child: Icon(icon, color: Colors.white, size: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. እውነተኛው የአጎራ ድምፅ ክፍል (Agora Voice Room)
// ==========================================
class VoiceRoomView extends StatefulWidget {
  final VoidCallback onUpdated;
  const VoiceRoomView({Key? key, required this.onUpdated}) : super(key: key);

  @override
  State<VoiceRoomView> createState() => _VoiceRoomViewState();
}

class _VoiceRoomViewState extends State<VoiceRoomView> {
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  final Set<int> _remoteUids = {};

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
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() => _remoteUids.add(remoteUid));
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() => _remoteUids.remove(remoteUid));
        },
      ),
    );

    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.enableAudio();
    await _engine!.joinChannel(
      token: '',
      channelId: AppData.channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine?.muteLocalAudioStream(_isMuted);
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  void _sendGift(int cost, String giftName) {
    if (AppData.userCoins < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('በቂ ሳንቲም የለዎትም!')));
      return;
    }
    setState(() {
      AppData.userCoins -= cost;
      AppData.hostPoints += cost;
    });
    widget.onUpdated();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$giftName ተላከ! ሆስቱ $cost ፖይንት አገኘ።'), backgroundColor: Colors.purple),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isJoined ? 'ክፍል፦ #1042 (ቀጥታ ተገናኝቷል 🟢)' : 'ድምፅ በማገናኘት ላይ... ⏳'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,

mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 0.8,
              ),
              itemCount: 8,
              itemBuilder: (context, i) {
                bool isMe = (i == 0);
                return Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: isMe ? Colors.purpleAccent : const Color(0xFF221A3D),
                          child: Icon(isMe ? Icons.person : Icons.mic_none, color: Colors.white70),
                        ),
                        CircleAvatar(
                          radius: 9,
                          backgroundColor: (isMe && !_isMuted) ? Colors.green : Colors.red,
                          child: Icon((isMe && !_isMuted) ? Icons.volume_up : Icons.mic_off, size: 10, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isMe ? 'እርስዎ (ሆስት)' : 'ተጠቃሚ ${i + 1}',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF161228),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: _isMuted ? Colors.red : Colors.greenAccent),
                  onPressed: _toggleMute,
                ),
                ElevatedButton.icon(
                  onPressed: () => _sendGift(1000, '🌹 ጽጌረዳ'),
                  icon: const Icon(Icons.favorite, color: Colors.pinkAccent, size: 18),
                  label: const Text('ጽጌረዳ (1k)'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A1F4C)),
                ),
                ElevatedButton.icon(
                  onPressed: () => _sendGift(10000, '🏎️ መኪና'),
                  icon: const Icon(Icons.speed, color: Colors.amberAccent, size: 18),
                  label: const Text('መኪና (10k)'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A1F4C)),
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
// 5. ሚኒ ጌም (Pyramid Safe Game)
// ==========================================
class PyramidMiniGame extends StatefulWidget {
  final VoidCallback onUpdated;
  const PyramidMiniGame({Key? key, required this.onUpdated}) : super(key: key);

  @override
  State<PyramidMiniGame> createState() => _PyramidMiniGameState();
}

class _PyramidMiniGameState extends State<PyramidMiniGame> {
  final int bet = 500;
  int step = 0;
  bool active = false;
  double mult = 1.0;
  final Random _rnd = Random();

  void _start() {
    if (AppData.userCoins < bet) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('በቂ ሳንቲም የለዎትም!')));
      return;
    }
    setState(() {
      AppData.userCoins -= bet;
      active = true;
      step = 0;
      mult = 1.0;
    });
    widget.onUpdated();
  }

  void _choose() {
    if (!active) return;
    int chance = 75 - (step * 20);
    if (_rnd.nextInt(100) < chance && step < 3) {
      setState(() {
        step++;
        mult += 0.8;
      });
      if (step == 3) _takeWin();
    } else {
      setState(() => active = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('💥 ቦምብ ፈነዳ! ተበልተዋል።'), backgroundColor: Colors.red));
    }
  }

void _takeWin() {
    if (!active) return;
    int won = (bet * mult).round();
    if (won > 2500) won = 2500;

    setState(() {
      AppData.userCoins += won;
      active = false;
    });
    widget.onUpdated();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🎉 $won ሳንቲም አሸነፉ!'), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ፒራሚድ ማይኒንግ')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(active ? 'ደረጃ፦ $step | ማባዣ፦ x${mult.toStringAsFixed(1)}' : 'ለመጫወት ይጫኑ', style: const TextStyle(fontSize: 20, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            if (active)
              ElevatedButton(
                onPressed: _choose,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), backgroundColor: Colors.purple),
                child: const Text('ቀጣዩን ደረጃ ምረጥ ⛏️', style: TextStyle(fontSize: 16)),
              ),
            const SizedBox(height: 30),
            active
                ? ElevatedButton(onPressed: _takeWin, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade900), child: Text('ያሸነፉትን ውሰዱ (${(bet * mult).round()} Coins)'))
                : ElevatedButton(onPressed: _start, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: Text('በ $bet ሳንቲም ጀምር')),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. ኤጀንሲ (Agency Management View)
// ==========================================
class AgencyManagementView extends StatelessWidget {
  const AgencyManagementView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('የኤጀንሲ አስተዳዳሪ (Agency)')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: AppData.agencyHosts.length,
        itemBuilder: (context, i) {
          final host = AppData.agencyHosts[i];
          return Card(
            color: const Color(0xFF1B1638),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.deepPurple, child: Icon(Icons.person, color: Colors.white)),
              title: Text(host['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Text('ID: ${host['id']} | የተሰበሰበ ፖይንት: ${host['points']} 💎', style: const TextStyle(color: Colors.white70)),
              trailing: Chip(
                label: Text(host['status'], style: const TextStyle(fontSize: 11)),
                backgroundColor: host['status'] == 'Active' ? Colors.green.shade900 : Colors.orange.shade900,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 7. ዋሌትና ካሽአውት (Wallet & Cashout)
// ==========================================
class ProfileWalletView extends StatefulWidget {
  final VoidCallback onUpdated;
  const ProfileWalletView({Key? key, required this.onUpdated}) : super(key: key);

  @override
  State<ProfileWalletView> createState() => _ProfileWalletViewState();
}

class _ProfileWalletViewState extends State<ProfileWalletView> {
  final _ptsCtrl = TextEditingController();
  final _accCtrl = TextEditingController();

  void _submitCashout() {
    int pts = int.tryParse(_ptsCtrl.text) ?? 0;
    if (pts < 100000 || pts > AppData.hostPoints) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ትክክለኛ መጠን ያስገቡ (ቢያንስ 100,000)!')));
      return;
    }
    AppData.cashoutRequests.add({
      'points': pts,
      'amount': (pts / 100000) * 1667,
      'acc': _accCtrl.text.trim(),
    });
    widget.onUpdated();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ጥያቄዎ ደርሷል!')));
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('የኪስ ቦርሳ (Wallet)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF1E1742), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text('ያለዎት ፖይንት፦ ${AppData.hostPoints} 💎', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                const SizedBox(height: 8),
                const Text('የምንዛሬ ተመን፦ 100,000 Pts = 1,667 ብር', style: TextStyle(color: Colors.greenAccent)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, padding: const EdgeInsets.all(14)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: const Color(0xFF140F26),
                builder: (_) => Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: _ptsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'የሚያወጡት ፖይንት')),
                      const SizedBox(height: 12),
                      TextField(controller: _accCtrl, decoration: const InputDecoration(labelText: 'የቴሌብር ወይም የባንክ ቁጥር')),
                      const SizedBox(height: 20),
                      ElevatedButton(onPressed: _submitCashout, child: const Text('ገንዘብ አውጣ')),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
            child: const Text('ፖይንት ወደ ብር ቀይር (Cashout)'),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 8. አስተዳዳሪ (Admin Panel)
// ==========================================
class AdminPanelScreen extends StatelessWidget {
  final VoidCallback onUpdated;
  const AdminPanelScreen({Key? key, required this.onUpdated}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('የአስተዳዳሪ ማጽደቂያ (Admin)'), backgroundColor: Colors.amber.shade900),
      body: AppData.cashoutRequests.isEmpty
          ? const Center(child: Text('ምንም የክፍያ ጥያቄ የለም።'))
          : ListView.builder(
              itemCount: AppData.cashoutRequests.length,
              itemBuilder: (context, i) {
                final r = AppData.cashoutRequests[i];
                return ListTile(
                  title: Text('${r['amount']} ETB - ${r['acc']}'),
                  subtitle: Text('${r['points']} Points'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      AppData.hostPoints -= (r['points'] as int);
                      AppData.cashoutRequests.removeAt(i);
                      onUpdated();
                      Navigator.pop(context);
                    },
                    child: const Text('አጽድቅ'),
                  ),
                );
              },
            ),
    );
  }
}
