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
      title: 'Voice Live App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MainDashboardScreen(),
    );
  }
}

class AppState {
  static int userCoins = 50000;
  static int hostPoints = 120000;
  static List<Map<String, dynamic>> requests = [];
}

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
        title: const Text('Live Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminApprovalScreen(onUpdated: _refresh)),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.deepPurple.shade900,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Coins: ${AppState.userCoins} 🪙', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Points: ${AppState.hostPoints} 💎', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            tileColor: Colors.white10,
            leading: const Icon(Icons.mic, color: Colors.purpleAccent),
            title: const Text('የድምፅ ክፍል (Voice Room)'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VoiceRoomScreen(onUpdated: _refresh)),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.white10,
            leading: const Icon(Icons.videogame_asset, color: Colors.indigoAccent),
            title: const Text('ሚኒ ጌም (Mini Game)'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PyramidGameScreen(onUpdated: _refresh)),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.white10,
            leading: const Icon(Icons.payments, color: Colors.greenAccent),
            title: const Text('ገንዘብ ማውጫ (Host Cashout)'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HostCashoutScreen(onUpdated: _refresh)),
            ),
          ),
        ],
      ),
    );
  }
}

class VoiceRoomScreen extends StatelessWidget {
  final VoidCallback onUpdated;
  const VoiceRoomScreen({Key? key, required this.onUpdated}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Room')),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.card_giftcard),
          label: const Text('ስጦታ ላክ (1,000 Coins)'),
          onPressed: () {
            if (AppState.userCoins >= 1000) {

AppState.userCoins -= 1000;
              AppState.hostPoints += 1000;
              onUpdated();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ስጦታው ተልኳል! ሆስቱ 1000 ፖይንት አገኘ።')),
              );
            }
          },
        ),
      ),
    );
  }
}

class PyramidGameScreen extends StatefulWidget {
  final VoidCallback onUpdated;
  const PyramidGameScreen({Key? key, required this.onUpdated}) : super(key: key);

  @override
  State<PyramidGameScreen> createState() => _PyramidGameScreenState();
}

class _PyramidGameScreenState extends State<PyramidGameScreen> {
  final Random _rnd = Random();

  void _play() {
    if (AppState.userCoins < 500) return;
    setState(() {
      AppState.userCoins -= 500;
      bool won = _rnd.nextBool();
      if (won) {
        AppState.userCoins += 900;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 አሸነፉ! 900 ሳንቲም አገኙ።')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('💥 ተበልቷል!')));
      }
    });
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mini Game')),
      body: Center(
        child: ElevatedButton(
          onPressed: _play,
          child: const Text('በ 500 ሳንቲም ተጫወት'),
        ),
      ),
    );
  }
}

class HostCashoutScreen extends StatefulWidget {
  final VoidCallback onUpdated;
  const HostCashoutScreen({Key? key, required this.onUpdated}) : super(key: key);

  @override
  State<HostCashoutScreen> createState() => _HostCashoutScreenState();
}

class _HostCashoutScreenState extends State<HostCashoutScreen> {
  final _controller = TextEditingController();

  void _submit() {
    int pts = int.tryParse(_controller.text) ?? 0;
    if (pts >= 100000 && pts <= AppState.hostPoints) {
      AppState.requests.add({
        'points': pts,
        'amount': (pts / 100000) * 1667,
      });
      Navigator.pop(context);
      widget.onUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cashout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'የፖይንት መጠን (ምሳሌ፦ 100000)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('ጥያቄውን ላክ'),
            )
          ],
        ),
      ),
    );
  }
}

class AdminApprovalScreen extends StatelessWidget {
  final VoidCallback onUpdated;
  const AdminApprovalScreen({Key? key, required this.onUpdated}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: AppState.requests.isEmpty
          ? const Center(child: Text('ምንም ጥያቄ የለም።'))
          : ListView.builder(
              itemCount: AppState.requests.length,
              itemBuilder: (context, i) {
                final req = AppState.requests[i];
                return ListTile(
                  title: Text('${req['amount']} ETB'),
                  subtitle: Text('${req['points']} Points'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      AppState.hostPoints -= (req['points'] as int);
                      AppState.requests.removeAt(i);
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
