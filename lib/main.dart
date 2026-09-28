import 'dart:async';
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

// ==================== 1. LOG IN SCREEN ====================
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
                const Text('እንኳን ደህና መጡ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
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

// ==================== 2. MAIN NAVIGATION SCREEN ====================
class MainNavigationScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const MainNavigationScreen({super.key, required this.onLogout});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 3;

  int userCoins = 50000;
  double userPoints = 23902.29;
  String currentUserName = 'KEDIR ,,,,';

  void addCoins(int amount) => setState(() => userCoins += amount);
  void deductCoins(int amount) => setState(() => userCoins -= amount);
  void addPoints(double amount) => setState(() => userPoints += amount);

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      RetroRoomScreen(
        userName: currentUserName,
        coins: userCoins,
        points: userPoints,
        onMinePoints: (mined) => addPoints(mined),
        onSendGift: (cost, pointsGained) {
          deductCoins(cost);
          addPoints(pointsGained);
        },
      ),
      const Scaffold(body: Center(child: Text('Moment Screen', style: TextStyle(fontSize: 18)))),
      const MessageScreen(),
      MeProfileScreen(
        coins: userCoins,
        points: userPoints,
        userName: currentUserName,
        onAddCoins: addCoins,
        onDeductCoins: deductCoins,
        onAddPoints: addPoints,
        onLogout: widget.onLogout,
      ),
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

// ==================== 3. ME PROFILE SCREEN ====================
class MeProfileScreen extends StatefulWidget {
  final int coins;
  final double points;
  final String userName;
  final Function(int) onAddCoins;
  final Function(int) onDeductCoins;
  final Function(double) onAddPoints;
  final VoidCallback onLogout;

  const MeProfileScreen({
    super.key,
    required this.coins,
    required this.points,
    required this.userName,
    required this.onAddCoins,
    required this.onDeductCoins,
    required this.onAddPoints,
    required this.onLogout,
  });

  @override
  State<MeProfileScreen> createState() => _MeProfileScreenState();
}

class _MeProfileScreenState extends State<MeProfileScreen> {
  String userId = '1753925';

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

            // Header Profile
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
                      gradient: const RadialGradient(colors: [Color(0xFFFFE082), Color(0xFFFFB300)]),
                    ),
                    child: const Center(child: Icon(Icons.person, size: 50, color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                            Text('ID: $userId', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: userId));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID ተገልብጧል!')));
                              },
                              child: const Icon(Icons.copy, size: 14, color: Colors.black45),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

// VIP Club Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3E2723), Color(0xFF1B0000)]),
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
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC80)),
                      onPressed: () {
                        widget.onAddCoins(10000);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('10,000 ነፃ VIP ኮይን ተመርቷል!')));
                      },
                      child: const Text('Get VIP', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Coins & Points Bar
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
                        onTap: () => _openPage(RechargeScreen(onRechargeSuccess: widget.onAddCoins)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Coins', style: TextStyle(color: Colors.black54, fontSize: 13)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.monetization_on, color: Colors.amber, size: 22),
                                const SizedBox(width: 6),
                                Text('${widget.coins}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(height: 38, width: 1, color: Colors.black12),
                    const SizedBox(width: 20),
                    Expanded(
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
                              Text(widget.points.toStringAsFixed(1), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00B0FF))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ማምረቻ እና አስተዳደር
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildGridItem(Icons.account_balance_wallet, 'Recharge', Colors.amber, () {
                          _openPage(RechargeScreen(onRechargeSuccess: widget.onAddCoins));
                        }),
                        _buildGridItem(Icons.change_history, 'Pyramid Mine', Colors.orange, () {
                          _openPage(PyramidMiningGame(
                            coins: widget.coins,
                            onDeduct: widget.onDeductCoins,
                            onWin: widget.onAddCoins,
                          ));
                        }),
                        _buildGridItem(Icons.business_center, 'Agency', const Color(0xFF00B0FF), () {
                          _openPage(const AgencyCenterPage());
                        }),
                        _buildGridItem(Icons.settings, 'Setting', Colors.grey, widget.onLogout),
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

  Widget _buildGridItem(IconData icon, String label, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ==================== 4. RETRO ROOM SCREEN (ወንበር ላይ የመቀመጥ እና የመውረድ ስርዓት) ====================
class RetroRoomScreen extends StatefulWidget {
  final String userName;
  final int coins;
  final double points;
  final Function(double) onMinePoints;
  final Function(int cost, double pointsEarned) onSendGift;

const RetroRoomScreen({
    super.key,
    required this.userName,
    required this.coins,
    required this.points,
    required this.onMinePoints,
    required this.onSendGift,
  });

  @override
  State<RetroRoomScreen> createState() => _RetroRoomScreenState();
}

class _RetroRoomScreenState extends State<RetroRoomScreen> with SingleTickerProviderStateMixin {
  bool isMuted = false;
  late AnimationController _pulseController;
  Timer? _liveMiningTimer;
  double sessionMinedPoints = 0.0;

  // 8 ወንበሮች ሁኔታ (null ማለት ባዶ ነው፤ ስም ካለበት ሰው ተቀምጦበታል)
  List<String?> seatOccupants = List.generate(8, (index) => null);
  int? mySeatedIndex; // እኔ የተቀመጥኩበት ወንበር ቁጥር

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

    // በቀጥታ ስርጭት ውስጥ በቆየ ቁጥር በየ 3 ሰከንዱ 5 ፖይንት ይመረታል
    _liveMiningTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!isMuted && mySeatedIndex != null) {
        setState(() {
          sessionMinedPoints += 5.0;
        });
        widget.onMinePoints(5.0);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _liveMiningTimer?.cancel();
    super.dispose();
  }

  // ወንበር ላይ የመቀመጥ ወይም የመውረድ ዲያሎግ
  void _handleSeatTap(int index) {
    if (mySeatedIndex == index) {
      // እኔ የተቀመጥኩበት ወንበር ከሆነ => የመውረጃ አማራጭ
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1A29),
          title: Text('ወንበር ${index + 1}', style: const TextStyle(color: Colors.white)),
          content: const Text('ከዚህ ወንበር መውረድ ይፈልጋሉ?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ሰርዝ')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                setState(() {
                  seatOccupants[index] = null;
                  mySeatedIndex = null;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ከወንበር ${index + 1} ወርደዋል!')));
              },
              child: const Text('ከወንበር ውረድ (Leave)', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else if (seatOccupants[index] == null) {
      // ወንበሩ ባዶ ከሆነ => የመቀመጫ አማራጭ
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1A29),
          title: Text('ወንበር ${index + 1}', style: const TextStyle(color: Colors.white)),
          content: Text('በወንበር ${index + 1} ላይ ተቀምጠው ማይክ መክፈት ይፈልጋሉ?', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ተመለስ')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00ACC1)),
              onPressed: () {
                setState(() {
                  // በፊት ሌላ ወንበር ላይ ከነበረ ነፃ ያድርገው
                  if (mySeatedIndex != null) {
                    seatOccupants[mySeatedIndex!] = null;
                  }
                  seatOccupants[index] = widget.userName;
                  mySeatedIndex = index;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('በወንበር ${index + 1} ላይ ተቀምጠዋል! 🎉')));
              },
              child: const Text('ተቀመጥ (Take Seat)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      // ሌላ ሰው የተቀመጠበት ከሆነ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ወንበር ${index + 1} በ ${seatOccupants[index]} ተይዟል!')),
      );
    }
  }

void _openGiftSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1A29),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ስጦታ በመላክ ፖይንት አምርት', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('ኮይን: ${widget.coins}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildGift(ctx, 'ጽጌረዳ', 200, Icons.local_florist, Colors.pink),
                  _buildGift(ctx, 'አልማዝ', 1000, Icons.diamond, Colors.cyanAccent),
                  _buildGift(ctx, 'ሮኬት', 5000, Icons.rocket_launch, Colors.deepOrange),
                  _buildGift(ctx, 'መኪና', 20000, Icons.directions_car, Colors.amber),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGift(BuildContext ctx, String name, int cost, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        if (widget.coins >= cost) {
          Navigator.pop(ctx);
          double pointsGained = cost * 0.8;
          widget.onSendGift(cost, pointsGained);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name ተልኳል! ለሆስቱ $pointsGained Points ተመርቷል!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('በቂ ኮይን የለም! መጀመሪያ ያምርቱ ወይም ይሙሉ')),
          );
        }
      },
      child: Column(
        children: [
          CircleAvatar(radius: 26, backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color, size: 28)),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 11)),
          Text('$cost C', style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('VIP Live Room', style: TextStyle(color: Colors.white, fontSize: 16)),
            Text('የተመረተ ፖይንት: ${widget.points.toStringAsFixed(1)} (+$sessionMinedPoints)', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11)),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // ዋናው Retro Studio የማይክ ሆስት
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
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0xFF26C6DA), Color(0xFF00838F)]),
                ),
                child: Center(
                  child: Icon(isMuted ? Icons.mic_off : Icons.mic, size: 45, color: isMuted ? Colors.redAccent : Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Host Active (KEDIR)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),

          const SizedBox(height: 25),

          // 8 ወንበሮች (2 ረድፍ ባለ 4 መቀመጫ)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // ረድፍ 1 (ወንበር 1 - 4)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(4, (index) => _buildSeatItem(index)),
                ),
                const SizedBox(height: 18),
                // ረድፍ 2 (ወንበር 5 - 8)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(4, (index) => _buildSeatItem(index + 4)),
                ),
              ],
            ),
          ),

          const Spacer(),

          // የታችኛው መቆጣጠሪያ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: const Color(0xFF1E1A29),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => isMuted = !isMuted),
                  icon: CircleAvatar(
                    backgroundColor: isMuted ? Colors.redAccent : const Color(0xFF26C6DA),
                    child: Icon(isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                  onPressed: _openGiftSheet,
                  icon: const Icon(Icons.card_giftcard, color: Colors.white),
                  label: const Text('ስጦታ (Gift)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatItem(int index) {
    final String? occupant = seatOccupants[index];
    final bool isOccupied = occupant != null;
    final bool isMe = mySeatedIndex == index;

    return InkWell(
      onTap: () => _handleSeatTap(index),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOccupied ? const Color(0xFF00ACC1) : const Color(0xFF1E1A29),
              border: Border.all(
                color: isMe ? Colors.amberAccent : (isOccupied ? const Color(0xFF80DEEA) : Colors.white12),
                width: isMe ? 2.5 : 1.5,
              ),
              boxShadow: isMe
                  ? [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)]
                  : [],
            ),
            child: Center(
              child: isOccupied
                  ? const Icon(Icons.person, color: Colors.white, size: 34)
                  : const Icon(Icons.add, color: Colors.white38, size: 24),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 65,
            child: Text(

isOccupied ? (isMe ? 'እኔ' : occupant) : '${index + 1}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isMe ? Colors.amberAccent : (isOccupied ? Colors.white : Colors.white38),
                fontSize: 11,
                fontWeight: isOccupied ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 5. PYRAMID MINING GAME ====================
class PyramidMiningGame extends StatefulWidget {
  final int coins;
  final Function(int) onDeduct;
  final Function(int) onWin;
  const PyramidMiningGame({super.key, required this.coins, required this.onDeduct, required this.onWin});

  @override
  State<PyramidMiningGame> createState() => _PyramidMiningGameState();
}

class _PyramidMiningGameState extends State<PyramidMiningGame> {
  int currentFloor = 0;
  int accumulatedWin = 0;

  void startOrClimb(int boxIndex) {
    if (currentFloor == 0) {
      if (widget.coins < 500) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ለማምረት 500 ኮይን ያስፈልጋል!')));
        return;
      }
      widget.onDeduct(500);
      currentFloor = 1;
      accumulatedWin = 1000;
      setState(() {});
      return;
    }

    final bool safe = Random().nextDouble() < 0.75;
    if (safe) {
      setState(() {
        currentFloor++;
        accumulatedWin = (accumulatedWin * 2.5).toInt();
        if (currentFloor >= 3) {
          widget.onWin(accumulatedWin);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ጫፍ ደርሰዋል! $accumulatedWin ኮይን ተመርቷል! 🎉')),
          );
          currentFloor = 0;
          accumulatedWin = 0;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ቦምብ ፈነዳ! ማምረቻው ተቋረጠ።')));
      setState(() {
        currentFloor = 0;
        accumulatedWin = 0;
      });
    }
  }

  void cashOut() {
    if (accumulatedWin > 0) {
      widget.onWin(accumulatedWin);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$accumulatedWin ኮይን ተመርቶ ወደ ዋሌት ገብቷል!')));
      setState(() {
        currentFloor = 0;
        accumulatedWin = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1326),
      appBar: AppBar(title: const Text('Pyramid Coin Rig', style: TextStyle(color: Colors.white)), backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white)),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text('ቀሪ ኮይን: ${widget.coins}', style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(currentFloor == 0 ? 'በ 500 ኮይን ጀምር' : 'የተመረተ ኮይን: $accumulatedWin', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          _buildPyramidRow(1, 3),
          const SizedBox(height: 16),
          _buildPyramidRow(2, 2),
          const SizedBox(height: 16),
          _buildPyramidRow(3, 1),
          const Spacer(),
          if (currentFloor > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
                onPressed: cashOut,
                child: Text('የተመረተውን ሰብስብ ($accumulatedWin Coins)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          if (currentFloor == 0)

Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 50)),
                onPressed: () => startOrClimb(0),
                child: const Text('ማምረት ጀምር (Start Mining)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPyramidRow(int boxCount, int floor) {
    final bool isActive = currentFloor == floor - 1;
    final bool isPassed = currentFloor >= floor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(boxCount, (idx) {
        return InkWell(
          onTap: isActive ? () => startOrClimb(idx) : null,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 70,
            height: 60,
            decoration: BoxDecoration(
              gradient: isPassed
                  ? const LinearGradient(colors: [Colors.green, Colors.teal])
                  : (isActive ? const LinearGradient(colors: [Colors.amber, Colors.orange]) : const LinearGradient(colors: [Color(0xFF372948), Color(0xFF251B37)])),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isActive ? Colors.yellowAccent : Colors.white12, width: 2),
            ),
            child: Center(
              child: Icon(isPassed ? Icons.check_circle : (isActive ? Icons.touch_app : Icons.lock), color: Colors.white, size: 28),
            ),
          ),
        );
      }),
    );
  }
}

// ==================== 6. RECHARGE SCREEN ====================
class RechargeScreen extends StatelessWidget {
  final Function(int) onRechargeSuccess;
  const RechargeScreen({super.key, required this.onRechargeSuccess});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recharge (ኮይን መሙያ)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBox(context, '70,000 Coins', '100 ETB (Telebirr)', 70000),
            _buildBox(context, '210,000 Coins', '300 ETB (Telebirr)', 210000),
            _buildBox(context, '350,000 Coins', '500 ETB (Telebirr)', 350000),
          ],
        ),
      ),
    );
  }

  Widget _buildBox(BuildContext context, String coins, String price, int amt) {
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
              onRechargeSuccess(amt);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$coins በተሳካ ሁኔታ ተሞልቷል!')));
            },
            child: Text(price, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ==================== 7. MESSAGE SCREEN ====================
class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: const Center(child: Text('System and Notification Messages')),
    );
  }
}
