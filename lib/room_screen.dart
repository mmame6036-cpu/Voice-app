import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'room_chairs_grid.dart';
import 'room_gift_sheet.dart';
import 'room_games_sheet.dart';
import 'main.dart';

class RoomScreen extends StatefulWidget {
  final String roomTitle;
  final String hostName;
KEDER:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';

class RechargeScreen extends StatefulWidget {
  final dynamic socket;
  final VoidCallback onCoinsUpdated;

  const RechargeScreen({Key? key, this.socket, required this.onCoinsUpdated}) : super(key: key);

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // የሳንቲም ፓኬጆች
  final List<Map<String, dynamic>> packages = [
    {'coins': 1000, 'price': '50 ETB', 'bonus': 0},
    {'coins': 2500, 'price': '120 ETB', 'bonus': 100},
    {'coins': 5000, 'price': '240 ETB', 'bonus': 300},
    {'coins': 10000, 'price': '480 ETB', 'bonus': 800},
    {'coins': 25000, 'price': '1,150 ETB', 'bonus': 2500},
    {'coins': 50000, 'price': '2,200 ETB', 'bonus': 6000},
  ];

  // የዝውውር ፎርም መቆጣጠሪያዎች
  final TextEditingController _targetIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String transferStatus = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, dummy: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _targetIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _showPaymentInstructions(Map<String, dynamic> pkg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E143E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${pkg['coins']} ሳንቲም ለመግዛት',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('ዋጋ: ${pkg['price']}', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white12, height: 24),
            const Text('የክፍያ አማራጮች፦', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildBankTile('Telebirr', '09XXXXXXXX', Icons.phone_android, Colors.blue),
            _buildBankTile('CBE (ንግድ ባንክ)', '1000XXXXXXXXX', Icons.account_balance, Colors.purple),
            _buildBankTile('CBE Birr', '09XXXXXXXX', Icons.wallet, Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'ክፍያውን ከፈጸሙ በኋላ ደረሰኙን ለኤጀንቱ በቴሌግራም ወይም በዋትስአፕ በመላክ በ 2 ደቂቃ ውስጥ ሳንቲምዎን ያግኙ።',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ተረድቻለሁ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildBankTile(String name, String account, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(account, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white54, size: 16),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: account));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$name ቁጥር ተገልብጧል'), duration: const Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleTransfer() {
    final targetId = _targetIdController.text.trim();
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;

    if (targetId.isEmpty) {
      setState(() => transferStatus = 'እባክዎ የተጠቃሚውን ID ያስገቡ');
      return;
    }
    if (amount <= 0) {
      setState(() => transferStatus = 'ትክክለኛ የሳንቲም መጠን ያስገቡ');
      return;
    }
    if (AppData.userCoins < amount) {
      setState(() => transferStatus = 'በቂ ሳንቲም የለዎትም');
      return;
    }

    setState(() {
      AppData.userCoins -= amount;
      transferStatus = '✅ $amount ሳንቲም ለ ID: $targetId በተሳካ ሁኔታ ተላልፏል!';
      _amountController.clear();
      _targetIdController.clear();
    });
    widget.onCoinsUpdated();

    if (widget.socket != null) {
      widget.socket.emit('coin_transfer', {
        'from': AppData.currentUserName,
        'to_id': targetId,
        'amount': amount,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E143E),
        elevation: 0,
        title: const Text('Wallet & Recharge', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          tabs: const [
            Tab(text: 'Recharge (ግዢ)'),
            Tab(text: 'Agency Transfer (ማስተላለፊያ)'),
          ],
        ),
      ),
      body: Column(
        children: [
          // የሳንቲም ባላንስ ካርድ
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5E35B1), Color(0xFF311B92)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('የእርስዎ ሳንቲም (Balance)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          '${AppData.userCoins}',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                  ),
                  child: Text('ID: ${AppData.currentUserId}', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. የሳንቲም ግዢ ፓኬጆች
                GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: packages.length,
                  itemBuilder: (context, idx) {
                    final p = packages[idx];
                    return GestureDetector(
                      onTap: () => _showPaymentInstructions(p),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E143E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
                                const SizedBox(width: 6),
                                Text('${p['coins']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            if (p['bonus'] > 0)
                              Text('+${p['bonus']} Bonus', style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(8),
                              ),

child: Text(
                                p['price'],
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // 2. የኤጀንሲ ሳንቲም ማስተላለፊያ
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E143E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ሳንቲም ለተጠቃሚ ያስተላልፉ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _targetIdController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'የተጠቃሚ መለያ (Target User ID)',
                            labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                            prefixIcon: const Icon(Icons.person, color: Colors.white54),
                            filled: true,
                            fillColor: Colors.black26,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'የሳንቲም መጠን (Coins Amount)',
                            labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                            prefixIcon: const Icon(Icons.monetization_on, color: Color(0xFFFFD700)),
                            filled: true,
                            fillColor: Colors.black26,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (transferStatus.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              transferStatus,
                              style: TextStyle(
                                color: transferStatus.startsWith('✅') ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E676),
                              padding: const EdgeInsets.symmetric(vertical: 14),

shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _handleTransfer,
                            child: const Text('አስተላልፍ (Transfer)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
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
  const RoomScreen({
    Key? key,
    this.roomTitle = 'Ethio Nile Coffee Club',
    this.hostName = 'Kedir oumer',
  }) : super(key: key);

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  IO.Socket? socket;
  List<String> liveAnnouncements = [
    '✨ VIP5 🌟 STAR entered room',
    '🎁 User sent Star x18 and won prizes!',
  ];
  List<String> chatMessages = [
    'System: Please protect your privacy and stay safe.',
  ];
  Map<int, String> occupiedChairs = {};
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _connectSocket();

    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          liveAnnouncements.add('🔥 Room activity active now!');
          if (liveAnnouncements.length > 5) liveAnnouncements.removeAt(0);
        });
      }
    });
  }

  void _connectSocket() {
    try {
      socket = IO.io(
        AppData.serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      socket?.connect();

      socket?.onConnect((_) {
        socket?.emit('join_room', {
          'room': widget.roomTitle,
          'user': AppData.currentUserName,
        });
      });

      socket?.on('chair_action', (data) {
        if (mounted) {
          setState(() {
            int chair = data['chairNum'];
            String user = data['userName'];
            String action = data['action'];

            if (action == 'join') {
              occupiedChairs.removeWhere((k, v) => v == user);
              occupiedChairs[chair] = user;
              chatMessages.add('$user entered chair #$chair');
            } else {
              occupiedChairs.remove(chair);
              chatMessages.add('$user left chair #$chair');
            }
          });
        }
      });

      socket?.on('gift_sent', (data) {
        if (mounted) {
          setState(() {
            liveAnnouncements.add('🎁 ${data['sender']} sent ${data['giftName']}!');
            chatMessages.add('${data['sender']} sent ${data['giftName']}');
          });
        }
      });

      socket?.on('game_win', (data) {
        if (mounted) {
          setState(() {
            liveAnnouncements.add('🎉 ${data['winner']} won ${data['amount']} in ${data['game']}!');
          });
        }
      });
    } catch (e) {
      debugPrint('Socket error: $e');
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B18),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF090D1C),
                  Color(0xFF02040A),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 1. የላይኛው ራስጌ (Header)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [

CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.teal,
                        child: Text(
                          widget.hostName.isNotEmpty ? widget.hostName[0] : 'U',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.hostName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'ID: 1410685',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // 2. የቀጥታ ባነር (Live Announcement Banner)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF880E4F), Color(0xFF4A148C)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          liveAnnouncements.isNotEmpty ? liveAnnouncements.last : '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // 3. ወንበሮች እና ቻት ዝርዝር
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        RoomChairsGrid(
                          socket: socket,
                          onChairTap: (chair) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 90,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(

color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.builder(
                            itemCount: chatMessages.length,
                            itemBuilder: (context, idx) => Text(
                              chatMessages[idx],
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. የታችኛው የመቆጣጠሪያ ባር (Bottom Control Bar)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.black.withOpacity(0.6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // የቻት መጻፊያ ሳጥን
                      Expanded(
                        child: Container(
                          height: 38,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(19),
                          ),
                          child: TextField(
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: const InputDecoration(
                              hintText: 'Say Hello...',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            onSubmitted: (text) {
                              if (text.trim().isNotEmpty && socket != null) {
                                socket?.emit('chat_message', {
                                  'sender': AppData.currentUserName,
                                  'text': text.trim(),
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      // የጌም እና የስጦታ ቁልፎች
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.sports_esports_rounded,
                              color: Colors.amberAccent,
                              size: 26,
                            ),
                            onPressed: () {
                              RoomGamesSheet.show(
                                context,
                                socket: socket,
                                onCoinsChanged: () => setState(() {}),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.card_giftcard_rounded,
                              color: Color(0xFFFFD700),
                              size: 26,
                            ),
                            onPressed: () {
                              RoomGiftSheet.show(
                                context,
                                socket: socket,
                                onGiftSent: () => setState(() {}),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
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
