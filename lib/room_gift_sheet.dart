import 'package:flutter/material.dart';
import 'main.dart';

class RoomGiftSheet extends StatefulWidget {
  final dynamic socket;
  final VoidCallback onGiftSent;

  const RoomGiftSheet({Key? key, this.socket, required this.onGiftSent}) : super(key: key);

  static void show(BuildContext context, {dynamic socket, required VoidCallback onGiftSent}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RoomGiftSheet(socket: socket, onGiftSent: onGiftSent),
    );
  }

  @override
  State<RoomGiftSheet> createState() => _RoomGiftSheetState();
}

class _RoomGiftSheetState extends State<RoomGiftSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int selectedIndex = 0;

  final List<Map<String, dynamic>> luckyGifts = [
    {'name': 'Star', 'coins': 50, 'icon': Icons.star_rounded, 'color': Colors.amber},
    {'name': 'Beer', 'coins': 20, 'icon': Icons.sports_bar_rounded, 'color': Colors.amberAccent},
    {'name': 'Cherry', 'coins': 20, 'icon': Icons.circle, 'color': Colors.redAccent},
    {'name': 'Like', 'coins': 10, 'icon': Icons.thumb_up_rounded, 'color': Colors.pinkAccent},
    {'name': 'Balloon', 'coins': 10, 'icon': Icons.air_rounded, 'color': Colors.purpleAccent},
    {'name': 'Donut', 'coins': 100, 'icon': Icons.donut_large_rounded, 'color': Colors.brown},
    {'name': 'Crown', 'coins': 1000, 'icon': Icons.military_tech_rounded, 'color': Color(0xFFFFD700)},
    {'name': 'Unicorn', 'coins': 5000, 'icon': Icons.pets_rounded, 'color': Colors.lightBlueAccent},
  ];

  final List<Map<String, dynamic>> boxGifts = [
    {'name': 'Neon Orbit', 'coins': 1000, 'icon': Icons.album_rounded, 'color': Colors.cyanAccent},
    {'name': 'Dream Jelly', 'coins': 10000, 'icon': Icons.bubble_chart_rounded, 'color': Colors.pinkAccent},
    {'name': 'Soul Blade', 'coins': 50000, 'icon': Icons.colorize_rounded, 'color': Colors.blueAccent},
    {'name': 'Flame Phoenix', 'coins': 500000, 'icon': Icons.local_fire_department_rounded, 'color': Colors.deepOrangeAccent},
  ];

  final List<Map<String, dynamic>> classicGifts = [
    {'name': 'Sweet Crush', 'coins': 100, 'icon': Icons.favorite_rounded, 'color': Colors.pink},
    {'name': 'Love Band', 'coins': 200, 'icon': Icons.ring_volume_rounded, 'color': Colors.tealAccent},
    {'name': 'Rose Bouquet', 'coins': 6600, 'icon': Icons.local_florist_rounded, 'color': Colors.red},
    {'name': 'Fairy Wings', 'coins': 1000, 'icon': Icons.flutter_dash_rounded, 'color': Colors.lightBlue},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _sendGift(Map<String, dynamic> gift) {
    if (AppData.userCoins < gift['coins']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('በቂ ሳንቲም የለዎትም!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      AppData.userCoins -= (gift['coins'] as int);
    });

    if (widget.socket != null) {
      widget.socket.emit('gift_sent', {
        'sender': AppData.currentUserName,
        'giftName': gift['name'],
        'coins': gift['coins'],
      });
    }

    widget.onGiftSent();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${gift['name']} ስጦታ ተልኳል! 🎉'),
        backgroundColor: const Color(0xFFFFD700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 490,
      decoration: const BoxDecoration(
        color: Color(0xFF101322),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),

width: 36,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: const Color(0xFFFFD700),
                  labelColor: const Color(0xFFFFD700),
                  unselectedLabelColor: Colors.white54,
                  tabs: const [Tab(text: 'Lucky'), Tab(text: 'Box'), Tab(text: 'Classic')],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${AppData.userCoins}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGiftList(luckyGifts),
                _buildGiftList(boxGifts),
                _buildGiftList(classicGifts),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftList(List<Map<String, dynamic>> list) {
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final g = list[i];
        final bool isSel = selectedIndex == i;

        return GestureDetector(
          onTap: () {
            setState(() => selectedIndex = i);
            _sendGift(g);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSel ? const Color(0xFFFFD700).withOpacity(0.12) : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSel ? const Color(0xFFFFD700) : Colors.white12,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(g['icon'], color: g['color'], size: 30),
                const SizedBox(height: 6),
                Text(
                  g['name'],
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 10),
                    const SizedBox(width: 2),
                    Text(
                      '${g['coins']}',
                      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
