KEDER:
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const SafeVoiceLiveApp());
}

class SafeVoiceLiveApp extends StatelessWidget {
  const SafeVoiceLiveApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Live & Economy Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF0F0C20),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const MainDashboardScreen(),
    );
  }
}

// ==========================================
// 1. ሞዴሎች እና የጋራ ዳታ (State Models)
// ==========================================
class AppState {
  static int userCoins = 50000; // ተጠቃሚው የሚገዛው/ያለው ኮይን
  static int hostPoints = 120000; // ሆስቱ ከስጦታ የሚሰበስበው ፖይንት
  static List<WithdrawalRequest> requests = [];
}

class WithdrawalRequest {
  final String id;
  final String hostName;
  final int points;
  final double amountETB;
  final String paymentMethod;
  final String accountNumber;
  String status; // 'Pending' ወይም 'Approved'

  WithdrawalRequest({
    required this.id,
    required this.hostName,
    required this.points,
    required this.amountETB,
    required this.paymentMethod,
    required this.accountNumber,
    this.status = 'Pending',
  });
}

// ==========================================
// 2. ዋናው ዳሽቦርድ (Main Navigation Dashboard)
// ==========================================
class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Hub & Economy'),
        backgroundColor: const Color(0xFF1E1742),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
            tooltip: 'Admin Panel',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminApprovalScreen(onUpdated: _refresh),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // የዋሌት ማሳያ ካርድ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B247A), Color(0xFF1B1B62)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('የእርስዎ ሳንቲም (Coins)', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text(
                        '${AppState.userCoins} 🪙',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                      ),
                    ],
                  ),
                  Container(height: 40, width: 1, color: Colors.white24),
                  Column(
                    children: [
                      const Text('የሆስት ፖይንት (Points)', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),

Text(
                        '${AppState.hostPoints} 💎',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // አሰሳዎች (Menu Cards)
            _buildNavCard(
              icon: Icons.mic,
              title: 'ድምፅ ክፍል (Voice Room)',
              subtitle: 'ይግቡ፣ ስጦታዎችን ይላኩ እና ፖይንት ያመንጩ',
              color: Colors.deepPurpleAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VoiceRoomScreen(onUpdated: _refresh)),
              ),
            ),
            _buildNavCard(
              icon: Icons.videogame_asset,
              title: 'ፒራሚድ ማይኒንግ (Safe Mini-Game)',
              subtitle: 'ከደህንነት ገደብ (RTP & Max Win) ጋር የተሰራ',
              color: Colors.indigoAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PyramidGameScreen(onUpdated: _refresh)),
              ),
            ),
            _buildNavCard(
              icon: Icons.shopping_bag,
              title: 'ኮይን ግዢ (Manual Store)',
              subtitle: 'በቴሌብር ወይም በባንክ ኮይን የሚሞላበት',
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CoinPurchaseScreen(onUpdated: _refresh)),
              ),
            ),
            _buildNavCard(
              icon: Icons.payments,
              title: 'ፖይንት ወደ ብር ማውጫ (Host Cashout)',
              subtitle: '100,000 Pts = 1,667 ብር ተመን',
              color: Colors.orangeAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HostCashoutScreen(onUpdated: _refresh)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1B1638),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white30),
        onTap: onTap,
      ),
    );
  }
}

// ==========================================
// 3. የድምፅ ክፍል እና ስጦታ (Voice Room)
// ==========================================
class VoiceRoomScreen extends StatelessWidget {
  final VoidCallback onUpdated;
  const VoiceRoomScreen({Key? key, required this.onUpdated}) : super(key: key);

  void _sendGift(BuildContext context, int giftCost, String giftName) {
    if (AppState.userCoins < giftCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('በቂ ኮይን የለዎትም! እባክዎ ኮይን ይግዙ።')),
      );
      return;
    }
    AppState.userCoins -= giftCost;
    AppState.hostPoints += giftCost; // ኮይኑ ወደ ሆስት ፖይንት ይዞራል
    onUpdated();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$giftName በ $giftCost ሳንቲም ተላከ! ሆስቱ $giftCost ፖይንት አገኘ።')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('የድምፅ ክፍል (Room #101)'), backgroundColor: const Color(0xFF1E1742)),

body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
              itemCount: 6,
              itemBuilder: (context, i) {
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: i == 0 ? Colors.purple : Colors.white12,
                      child: Icon(i == 0 ? Icons.mic : Icons.mic_off, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(i == 0 ? 'ዋና ሆስት' : 'ወንበር ${i + 1}', style: const TextStyle(fontSize: 12)),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E1742),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _sendGift(context, 1000, '🌹 ጽጌረዳ'),
                  icon: const Icon(Icons.favorite, color: Colors.pinkAccent),
                  label: const Text('ጽጌረዳ (1k)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                ),
                ElevatedButton.icon(
                  onPressed: () => _sendGift(context, 10000, '🚗 ስፖርት መኪና'),
                  icon: const Icon(Icons.directions_car, color: Colors.amberAccent),
                  label: const Text('መኪና (10k)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 4. የፒራሚድ ማይኒንግ ጨዋታ (Safe Game Engine)
// ==========================================
class PyramidGameScreen extends StatefulWidget {
  final VoidCallback onUpdated;
  const PyramidGameScreen({Key? key, required this.onUpdated}) : super(key: key);

  @override
  State<PyramidGameScreen> createState() => _PyramidGameScreenState();
}

class _PyramidGameScreenState extends State<PyramidGameScreen> {
  final int betAmount = 500;
  int currentLevel = 0;
  bool isPlaying = false;
  double multiplier = 1.0;
  final Random _random = Random();

  void _startGame() {
    if (AppState.userCoins < betAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ለመጫወት ቢያንስ 500 ሳንቲም ያስፈልጋል!')),
      );
      return;
    }
    setState(() {
      AppState.userCoins -= betAmount;
      isPlaying = true;
      currentLevel = 0;
      multiplier = 1.0;
    });
    widget.onUpdated();
  }

  void _pickStep(int choice) {
    if (!isPlaying) return;

    // የደህንነት ቀመር: ደረጃው ከፍ ባለ ቁጥር የመሸነፍ እድሉ ይጨምራል (House Edge)
    // ደረጃ 1: 80% የማሸነፍ እድል, ደረጃ 2: 60%, ደረጃ 3: 40%
    int safeTarget = 80 - (currentLevel * 20);
    bool isSafe = _random.nextInt(100) < safeTarget;

    if (isSafe && currentLevel < 3) {
      setState(() {
        currentLevel++;
        multiplier += 0.8; // ማባዣው ይጨምራል
      });
      if (currentLevel == 3) {
        _cashoutGame(); // ከፍተኛውን ደረጃ ሲያጠናቅቅ በራስ-ሰር ይወስዳል
      }
    } else {
      // ተሸንፏል (ቦምብ ፈንድቷል)
      setState(() {
        isPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('💥 ቦምብ ፈነዳ! ያስያዙት ሳንቲም ተበልቷል።'), backgroundColor: Colors.red),
      );
    }
  }

  void _cashoutGame() {
    if (!isPlaying) return;
    int wonCoins = (betAmount * multiplier).round();

    // Max Win Cap: በአንድ ዙር ከ 2,500 ሳንቲም በላይ ማሸነፍ እንዳይቻል መገደብ
    if (wonCoins > 2500) wonCoins = 2500;

    setState(() {
      AppState.userCoins += wonCoins;
      isPlaying = false;
    });
    widget.onUpdated();

ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🎉 እንኳን ደስ አለዎት! $wonCoins ሳንቲም አሸነፉ።'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ፒራሚድ ማይኒንግ (Safe Engine)'), backgroundColor: const Color(0xFF1E1742)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isPlaying ? 'ደረጃ፦ $currentLevel | ማባዣ፦ x${multiplier.toStringAsFixed(1)}' : 'ጨዋታ ለመጀመር አስይዝ',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent),
              ),
              const SizedBox(height: 30),
              if (isPlaying)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (index) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24),
                        backgroundColor: Colors.deepPurple,
                      ),
                      onPressed: () => _pickStep(index),
                      child: const Text('?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    );
                  }),
                ),
              const SizedBox(height: 40),
              if (!isPlaying)
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  ),
                  child: Text('በ $betAmount ሳንቲም ጀምር'),
                )
              else
                ElevatedButton(
                  onPressed: _cashoutGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  ),
                  child: Text('ያሸነፉትን ውሰዱ (${(betAmount * multiplier).round()} Coins)'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. ኮይን መግዣ (Coin Purchase Store)
// ==========================================
class CoinPurchaseScreen extends StatelessWidget {
  final VoidCallback onUpdated;
  const CoinPurchaseScreen({Key? key, required this.onUpdated}) : super(key: key);

  void _manualBuy(BuildContext context, int coins, int priceETB) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1742),
        title: const Text('ኮይን መግዣ መመሪያ', style: TextStyle(color: Colors.white)),
        content: Text(
          '$coins ሳንቲም ለመግዛት $priceETB ብር ወደሚከተለው የቴሌብር ቁጥር ያስገቡ፦\n\n'
          '📱 ቴሌብር፦ 09xxxxxxxx\n'
          '👤 ስም፦ የድርጅቱ ስም\n\n'
          'ብር እንደላኩ ደረሰኙን ለዋናው አስተዳዳሪ ሲልኩ ወዲያውኑ ኮይኑ ይሞላልዎታል።',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('እሺ')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ኮይን መግዣ ሱቅ'), backgroundColor: const Color(0xFF1E1742)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPackage(context, 50000, 1000),
          _buildPackage(context, 100000, 2000),
          _buildPackage(context, 300000, 5800),
        ],
      ),
    );
  }

Widget _buildPackage(BuildContext context, int coins, int etb) {
    return Card(
      color: const Color(0xFF1B1638),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.monetization_on, color: Colors.amber, size: 36),
        title: Text('$coins Coins', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text('ዋጋ፦ $etb የኢትዮጵያ ብር', style: const TextStyle(color: Colors.greenAccent)),
        trailing: ElevatedButton(
          onPressed: () => _manualBuy(context, coins, etb),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          child: const Text('ግዛ'),
        ),
      ),
    );
  }
}

// ==========================================
// 6. የሆስት ገንዘብ ማውጫ (Host Cashout Screen)
// ==========================================
class HostCashoutScreen extends StatefulWidget {
  final VoidCallback onUpdated;
  const HostCashoutScreen({Key? key, required this.onUpdated}) : super(key: key);

  @override
  State<HostCashoutScreen> createState() => _HostCashoutScreenState();
}

class _HostCashoutScreenState extends State<HostCashoutScreen> {
  final _pointsCtrl = TextEditingController();
  final _accCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _method = 'Telebirr';
  double _etbAmount = 0.0;

  void _calculate(String val) {
    int pts = int.tryParse(val) ?? 0;
    setState(() {
      _etbAmount = (pts / 100000) * 1667;
    });
  }

  void _submit() {
    int pts = int.tryParse(_pointsCtrl.text) ?? 0;
    if (pts < 100000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ዝቅተኛው የማውጫ መጠን 100,000 ፖይንት ነው!')),
      );
      return;
    }
    if (pts > AppState.hostPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('በቂ ፖይንት የለዎትም!')),
      );
      return;
    }

    AppState.requests.add(WithdrawalRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      hostName: _nameCtrl.text.trim(),
      points: pts,
      amountETB: _etbAmount,
      paymentMethod: _method,
      accountNumber: _accCtrl.text.trim(),
    ));

    Navigator.pop(context);
    widget.onUpdated();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('የማውጣት ጥያቄው ለአስተዳዳሪው ደርሷል!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ገንዘብ ማውጫ (Withdraw)'), backgroundColor: const Color(0xFF1E1742)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _pointsCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'የሚያወጡት ፖይንት መጠን (ምሳሌ: 100000)',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
              onChanged: _calculate,
            ),
            const SizedBox(height: 10),
            Text(
              'የሚደርስዎት፦ ${_etbAmount.toStringAsFixed(2)} ETB',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'ሙሉ ስም',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

TextField(
              controller: _accCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'የቴሌብር ስልክ ቁጥር ወይም የባንክ ሂሳብ',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const dynamic.fromMilliseconds(50),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: const Text('ጥያቄውን ላክ'),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. የአስተዳዳሪ ማጽደቂያ ገጽ (Admin Panel)
// ==========================================
class AdminApprovalScreen extends StatefulWidget {
  final VoidCallback onUpdated;
  const AdminApprovalScreen({Key? key, required this.onUpdated}) : super(key: key);

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  void _approve(WithdrawalRequest req) {
    setState(() {
      req.status = 'Approved';
      AppState.hostPoints -= req.points; // ፖይንቱ በቋሚነት ይቀነሳል
    });
    widget.onUpdated();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ክፍያው ጸድቋል! ፖይንቱ ተቀንሷል።')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = AppState.requests.where((r) => r.status == 'Pending').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('የአስተዳዳሪ ማጽደቂያ (Admin)'), backgroundColor: Colors.amber.shade900),
      body: pending.isEmpty
          ? const Center(child: Text('ምንም አዲስ የክፍያ ጥያቄ የለም።', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              itemCount: pending.length,
              itemBuilder: (context, index) {
                final req = pending[index];
                return Card(
                  color: const Color(0xFF1B1638),
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    title: Text('${req.hostName} - ${req.amountETB.toStringAsFixed(2)} ETB',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text('ፖይንት: ${req.points}\nመረጃ: ${req.paymentMethod} (${req.accountNumber})',
                        style: const TextStyle(color: Colors.white70)),
                    trailing: ElevatedButton(
                      onPressed: () => _approve(req),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('አጽድቅ'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
