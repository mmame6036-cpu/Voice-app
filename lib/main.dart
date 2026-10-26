import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

// ማስታወሻ፡ ከ console.agora.io የምታገኘውን ነፃ App ID እዚህ አስገባ
const String agoraAppId = "21091aff01114a66b580ce15b0f1b642";
const String agoraToken = ""; 
const String channelName = "habesha_vip_room";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VoicePartyApp());
}

class VoicePartyApp extends StatelessWidget {
  const VoicePartyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice Party',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        primaryColor: const Color(0xFFFFD700),
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
  int _coins = 1250;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        coins: _coins,
        onCoinUpdate: (newCoins) => setState(() => _coins = newCoins),
      ),
      const Center(child: Text("Explore Rooms", style: TextStyle(color: Colors.white70))),
      const Center(child: Text("Messages", style: TextStyle(color: Colors.white70))),
      MeProfileScreen(coins: _coins),
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
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final int coins;
  final Function(int) onCoinUpdate;

  const HomeScreen({super.key, required this.coins, required this.onCoinUpdate});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFFFD700),
                  child: Icon(Icons.person, color: Colors.black),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Kedir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("Lv. 15 Master", style: TextStyle(color: Color(0xFFFFD700), fontSize: 11)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF23233E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD700), width: 1),

),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
                      const SizedBox(width: 6),
                      Text("$coins", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "Trending Voice Parties",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                RoomCard(
                  title: "Habesha VIP Chill & Music 🎵",
                  hostName: "Kedir Umer",
                  membersCount: 8,
                  onJoin: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VoicePartyRoomScreen(
                          roomTitle: "Habesha VIP Chill & Music 🎵",
                          initialCoins: coins,
                          onCoinUpdate: onCoinUpdate,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final String title;
  final String hostName;
  final int membersCount;
  final VoidCallback onJoin;

  const RoomCard({
    super.key,
    required this.title,
    required this.hostName,
    required this.membersCount,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onJoin,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF261D45), Color(0xFF16162A)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: Colors.purple,
              child: Icon(Icons.mic, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text("Host: $hostName", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black40,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.headset, color: Color(0xFFFFD700), size: 14),
                  const SizedBox(width: 4),
                  Text("$membersCount/8", style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class VoicePartyRoomScreen extends StatefulWidget {
  final String roomTitle;
  final int initialCoins;
  final Function(int) onCoinUpdate;

  const VoicePartyRoomScreen({
    super.key,
    required this.roomTitle,
    required this.initialCoins,
    required this.onCoinUpdate,
  });

  @override
  State<VoicePartyRoomScreen> createState() => _VoicePartyRoomScreenState();
}

class _VoicePartyRoomScreenState extends State<VoicePartyRoomScreen> {
  late int _currentCoins;
  bool _isMicMuted = false;
  int? _mySeatIndex;
  final List<String?> _seats = List.filled(8, null);
  final List<String> _chatMessages = ["Welcome to the party room! Keep it friendly."];
  final TextEditingController _msgController = TextEditingController();

  RtcEngine? _engine;
  bool _isEngineReady = false;

  @override
  void initState() {
    super.initState();
    _currentCoins = widget.initialCoins;
    _initVoiceEngine();
  }

  Future<void> _initVoiceEngine() async {
    // ማይክሮፎን ፈቃድ መጠየቅ
    await [Permission.microphone].request();

    if (agoraAppId != "YOUR_AGORA_APP_ID_HERE") {
      try {
        _engine = createAgoraRtcEngine();
        await _engine!.initialize(const RtcEngineContext(
          appId: agoraAppId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ));

        _engine!.registerEventHandler(
          RtcEngineEventHandler(
            onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
              setState(() {
                _chatMessages.add("Joined voice channel successfully.");
              });
            },
            onUserMuteAudio: (RtcConnection connection, int remoteUid, bool muted) {
              // Remote user mute handler
            },
          ),
        );

        await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
        await _engine!.enableAudio();
        await _engine!.joinChannel(
          token: agoraToken,
          channelId: channelName,
          uid: 0,
          options: const ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleAudience,
            autoSubscribeAudio: true,
          ),
        );

        setState(() {
          _isEngineReady = true;
        });
      } catch (e) {
        debugPrint("Agora Error: $e");
      }
    }
  }

  Future<void> _handleSeatTap(int index) async {
    setState(() {
      if (_seats[index] == null) {
        if (_mySeatIndex != null) _seats[_mySeatIndex!] = null;
        _seats[index] = "Kedir (Me)";
        _mySeatIndex = index;
        _updateBroadcasterRole(true);
      } else if (_mySeatIndex == index) {
        _seats[index] = null;
        _mySeatIndex = null;
        _updateBroadcasterRole(false);
      }
    });
  }

  Future<void> _updateBroadcasterRole(bool isSpeaker) async {
    if (_engine != null && _isEngineReady) {
      if (isSpeaker) {
        await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
        await _engine!.muteLocalAudioStream(_isMicMuted);
      } else {
        await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
      }
    }
  }

  Future<void> _toggleMic() async {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
    if (_engine != null && _isEngineReady && _mySeatIndex != null) {
      await _engine!.muteLocalAudioStream(_isMicMuted);
    }
  }

  void _sendGift(String giftName, int cost) {
    if (_currentCoins >= cost) {
      setState(() {
        _currentCoins -= cost;
        _chatMessages.add("🎁 Kedir sent a $giftName!");
      });
      widget.onCoinUpdate(_currentCoins);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient coins!")),
      );
    }
  }

  void _openGiftSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B38),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Send a Gift", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),

const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _giftItem("Rose", "🌹", 10),
                _giftItem("Crown", "👑", 100),
                _giftItem("Super Car", "🏎️", 500),
                _giftItem("Rocket", "🚀", 1000),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _giftItem(String name, String icon, int cost) {
    return GestureDetector(
      onTap: () => _sendGift(name, cost),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD700), width: 1),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text("$cost 🪙", style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.roomTitle, style: const TextStyle(fontSize: 16, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final isTaken = _seats[index] != null;
                return GestureDetector(
                  onTap: () => _handleSeatTap(index),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: isTaken ? Colors.amber : Colors.white12,
                        child: Icon(
                          isTaken ? Icons.mic : Icons.add,
                          color: isTaken ? Colors.black : Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTaken ? _seats[index]! : "Seat ${index + 1}",
                        style: TextStyle(
                          color: isTaken ? const Color(0xFFFFD700) : Colors.white54,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Spacer(),
          Container(
            height: 140,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),

child: Text(
                  _chatMessages[index],
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF16162A),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isMicMuted ? Icons.mic_off : Icons.mic,
                      color: _isMicMuted ? Colors.red : Colors.greenAccent),
                  onPressed: _toggleMic,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: "Say something...",
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          setState(() => _chatMessages.add("Kedir: $val"));
                          _msgController.clear();
                        }
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.card_giftcard, color: Color(0xFFFFD700)),
                  onPressed: _openGiftSheet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MeProfileScreen extends StatelessWidget {
  final int coins;
  const MeProfileScreen({super.key, required this.coins});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFFFD700),
              child: Icon(Icons.person, size: 50, color: Colors.black),
            ),
            const SizedBox(height: 12),
            const Text("Kedir Umer", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("ID: 9845210", style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B38),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statCol("Coins", "$coins 🪙"),
                  _statCol("Level", "Lv. 15"),
                  _statCol("Followers", "340"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCol(String title, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
