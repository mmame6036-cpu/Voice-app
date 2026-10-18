import 'package:flutter/material.dart';

class GiftItem {
  final String id;
  final String name;
  final int price;
  final String iconUrl;
  final String? tag;

  const GiftItem({
    required this.id,
    required this.name,
    required this.price,
    required this.iconUrl,
    this.tag,
  });
}

class GiftPanel extends StatefulWidget {
  final int userCoins;
  final List<Map<String, dynamic>> seats;
  final Function(String name, int price) onSendGift;

  const GiftPanel({
    Key? key,
    required this.userCoins,
    this.seats = const [],
    required this.onSendGift,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required int userCoins,
    List<Map<String, dynamic>> seats = const [],
    required Function(String name, int price) onSendGift,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GiftPanel(
        userCoins: userCoins,
        seats: seats,
        onSendGift: onSendGift,
      ),
    );
  }

  @override
  State<GiftPanel> createState() => _GiftPanelState();
}

class _GiftPanelState extends State<GiftPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedGiftId = 'red_pack';
  int _sendCount = 1;
  String _selectedTarget = 'All';

  // 1. Lucky Gifts
  final List<GiftItem> _luckyGifts = const [
    GiftItem(id: 'red_pack', name: 'Red Package', price: 10, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2614/2614635.png'),
    GiftItem(id: 'emerald', name: 'Emerald Brew', price: 100, iconUrl: 'https://cdn-icons-png.flaticon.com/512/924/924514.png'),
    GiftItem(id: 'party_burst', name: 'Party Burst', price: 1000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/4213/4213653.png'),
    GiftItem(id: 'falcon', name: 'Green Falcon', price: 10000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2219/2219530.png'),
    GiftItem(id: 'like', name: 'Like', price: 10, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1077/1077035.png'),
    GiftItem(id: 'cherry', name: 'Cherry', price: 20, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1135/1135249.png'),
    GiftItem(id: 'beer', name: 'Beer', price: 20, iconUrl: 'https://cdn-icons-png.flaticon.com/512/931/931949.png'),
    GiftItem(id: 'balloon', name: 'Balloon', price: 100, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2682/2682446.png', tag: '4%'),
    GiftItem(id: 'donut', name: 'Donut', price: 1000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3081/3081974.png', tag: '4%'),
    GiftItem(id: 'crown', name: 'Crown', price: 100, iconUrl: 'https://cdn-icons-png.flaticon.com/512/263/263059.png', tag: '4%'),
    GiftItem(id: 'unicorn', name: 'Royal Unicorn', price: 5000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3468/3468306.png'),
    GiftItem(id: 'flower', name: 'Flower', price: 50, iconUrl: 'https://cdn-icons-png.flaticon.com/512/346/346167.png'),
    GiftItem(id: 'star', name: 'Star', price: 50, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1828/1828884.png'),
    GiftItem(id: 'water_gun', name: 'Water Gun', price: 50, iconUrl: 'https://cdn-icons-png.flaticon.com/512/824/824239.png'),
    GiftItem(id: 'headset', name: 'Headset', price: 500, iconUrl: 'https://cdn-icons-png.flaticon.com/512/870/870132.png'),
    GiftItem(id: 'ring', name: 'Ring', price: 500, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1257/1257140.png'),
    GiftItem(id: 'adey_bloom', name: 'Adey Bloom', price: 100, iconUrl: 'https://cdn-icons-png.flaticon.com/512/869/869869.png'),
    GiftItem(id: 'jewel_greet', name: 'Jewel Greeting', price: 1000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3655/3655577.png'),
    GiftItem(id: 'jewel_offer', name: 'Jewel Offering', price: 10000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2614/2614397.png'),

GiftItem(id: 'music_box', name: 'Music Box', price: 1000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3844/3844724.png'),
    GiftItem(id: 'treasure', name: 'Treasure', price: 5000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2614/2614631.png'),
    GiftItem(id: 'night_rider', name: 'Night Rider', price: 10000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3097/3097180.png'),
    GiftItem(id: 'hyper_car', name: 'Hyper Car', price: 50000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3202/3202926.png'),
    GiftItem(id: 'golden_yacht', name: 'Golden Yacht', price: 100000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2945/2945517.png'),
    GiftItem(id: 'sky_fighter', name: 'Sky Fighter', price: 200000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1356/1356479.png'),
  ];

  // 2. Box Gifts
  final List<GiftItem> _boxGifts = const [
    GiftItem(id: 'neon_orbit', name: 'Neon Orbit', price: 1000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3242/3242257.png'),
    GiftItem(id: 'dream_jelly', name: 'Dream Jelly', price: 10000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3590/3590212.png'),
    GiftItem(id: 'soul_blade', name: 'Soul Blade', price: 50000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3468/3468379.png'),
    GiftItem(id: 'star_racer', name: 'Star Racer', price: 100000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/808/808439.png'),
    GiftItem(id: 'divine_gate', name: 'Divine Gate', price: 200000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2271/2271068.png'),
    GiftItem(id: 'flame_phoenix', name: 'Flame Phoenix', price: 500000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/426/426833.png'),
    GiftItem(id: 'dragon_roar', name: 'Dragon Roar', price: 1000000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1418/1418301.png'),
  ];

  // 3. Flag Gifts
  final List<GiftItem> _flagGifts = const [
    GiftItem(id: 'ae_flag', name: 'AE Flag', price: 100000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/197/197569.png'),
    GiftItem(id: 'bd_flag', name: 'BD Flag', price: 100000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/197/197541.png'),
    GiftItem(id: 'bi_flag', name: 'BI Flag', price: 100000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/197/197588.png'),
    GiftItem(id: 'bj_flag', name: 'BJ Flag', price: 100000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/197/197576.png'),
    GiftItem(id: 'br_flag', name: 'BR Flag', price: 100000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/197/197386.png'),
    GiftItem(id: 'de_flag', name: 'DE Flag', price: 100000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/197/197571.png'),
    GiftItem(id: 'eg_flag', name: 'EG Flag', price: 100000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/197/197558.png'),
    GiftItem(id: 'et_flag', name: 'ET Flag', price: 100000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/197/197549.png'),
  ];

  // 4. Classic Gifts
  final List<GiftItem> _classicGifts = const [
    GiftItem(id: 'boost_room', name: 'Boost Room', price: 500000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1162/1162499.png', tag: 'For You #1'),
    GiftItem(id: 'sweet_crush', name: 'Sweet Crush', price: 100, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2107/2107845.png'),
    GiftItem(id: 'love_band', name: 'Love Band', price: 200, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3655/3655580.png'),
    GiftItem(id: 'bread', name: 'Bread', price: 500, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3014/3014524.png'),
    GiftItem(id: 'fairy_wings', name: 'Fairy Wings', price: 1000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2972/2972531.png'),
    GiftItem(id: 'panda_hero', name: 'Panda Hero', price: 2000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/375/375103.png'),
    GiftItem(id: 'three_pigs', name: 'Three Pigs', price: 5000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/235/235384.png'),

GiftItem(id: 'rose_bracelet', name: 'Rose Bracelet', price: 6600, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3655/3655610.png'),
    GiftItem(id: 'crystal_violin', name: 'Crystal Violin', price: 7700, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2972/2972118.png'),
    GiftItem(id: 'red_rose', name: 'Red Rose', price: 8800, iconUrl: 'https://cdn-icons-png.flaticon.com/512/744/744922.png'),
    GiftItem(id: 'summer_chill', name: 'Summer Chill', price: 9900, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2917/2917995.png'),
    GiftItem(id: 'money_gun', name: 'Money Gun', price: 10000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2614/2614631.png'),
    GiftItem(id: 'lucky_palm', name: 'Lucky Palm', price: 18000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1865/1865269.png'),
    GiftItem(id: 'champagne', name: 'Champagne Blast', price: 20000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/924/924514.png'),
    GiftItem(id: 'crystal_lute', name: 'Crystal Lute', price: 28000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3844/3844724.png'),
    GiftItem(id: 'golden_ring', name: 'Golden Ring', price: 30000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1257/1257140.png'),
    GiftItem(id: 'diamond_star', name: 'Diamond Star', price: 55000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1828/1828884.png'),
    GiftItem(id: 'fireworks', name: 'Fireworks', price: 66000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/4213/4213653.png'),
    GiftItem(id: 'iron_bloom', name: 'Iron Bloom', price: 77000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/869/869869.png'),
    GiftItem(id: 'love_hug', name: 'Love Hug', price: 88000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2107/2107845.png'),
    GiftItem(id: 'money_cake', name: 'Money Cake', price: 99000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2682/2682446.png'),
    GiftItem(id: 'golden_racer', name: 'Golden Racer', price: 100000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3202/3202926.png'),
    GiftItem(id: 'golden_finch', name: 'Golden Finch', price: 150000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3468/3468306.png'),
    GiftItem(id: 'soccer_babe', name: 'Soccer Babe', price: 180000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1165/1165187.png'),
    GiftItem(id: 'sky_gate', name: 'Sky Gate', price: 200000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2271/2271068.png'),
    GiftItem(id: 'golden_rose', name: 'Golden Rose', price: 280000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/744/744922.png'),
    GiftItem(id: 'diamond_bike', name: 'Diamond Bike', price: 380000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3097/3097180.png'),
    GiftItem(id: 'diamond_wheel', name: 'Diamond Wheel', price: 500000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3242/3242257.png'),
    GiftItem(id: 'deep_spirit', name: 'Deep Spirit', price: 550000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3590/3590212.png'),
    GiftItem(id: 'star_balloon', name: 'Star Balloon', price: 660000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2682/2682446.png'),
    GiftItem(id: 'diamond_balloon', name: 'Diamond Balloon', price: 770000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2682/2682446.png'),
    GiftItem(id: 'golden_throne', name: 'Golden Throne', price: 880000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/263/263059.png'),
    GiftItem(id: 'gold_rocket', name: 'Gold Rocket', price: 990000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1356/1356479.png'),
    GiftItem(id: 'world_champ', name: 'World Champion', price: 1000000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3112/3112946.png'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

void _showCountPicker() {
    final counts = [1, 10, 66, 99, 520, 1314];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131622),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: counts.map((c) {
            return ListTile(
              title: Text('x$c', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: _sendCount == c ? const Icon(Icons.check, color: Color(0xFF6C5CE7)) : null,
              onTap: () {
                setState(() => _sendCount = c);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showTargetPicker() {
    final activeUsers = widget.seats
        .where((s) => s['user'] != null && s['user'].toString().isNotEmpty)
        .map((s) => s['user'].toString())
        .toSet()
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131622),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('All (Entire Room)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: _selectedTarget == 'All' ? const Icon(Icons.check, color: Color(0xFF6C5CE7)) : null,
              onTap: () {
                setState(() => _selectedTarget = 'All');
                Navigator.pop(ctx);
              },
            ),
            ...activeUsers.map((u) {
              return ListTile(
                title: Text(u, style: const TextStyle(color: Colors.white)),
                trailing: _selectedTarget == u ? const Icon(Icons.check, color: Color(0xFF6C5CE7)) : null,
                onTap: () {
                  setState(() => _selectedTarget = u);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        );
      },
    );
  }

  String _getSubtext() {
    switch (_tabController.index) {
      case 1:
        return 'Open Box to get surprise lucky items.';
      case 2:
        return 'Host 60% Points.';
      case 3:
        return 'Host 50% Points. Push room to For You #1.';
      default:
        return 'Provided by the system for gifting experience.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.62,
      decoration: const BoxDecoration(
        color: Color(0xFF0C0F1D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          // 1. Header (Lucky, Box, Flag, Classic + All + Coins + Backpack)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
                    onTap: (_) => setState(() {}),
                    tabs: const [
                      Tab(text: 'Lucky'),
                      Tab(text: 'Box'),
                      Tab(text: 'Flag'),

Tab(text: 'Classic'),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _showTargetPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2235),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Text(_selectedTarget, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2235),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle),
                        child: const Text('T', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.userCoins}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white54, size: 14),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.backpack_outlined, color: Colors.white70, size: 20),
              ],
            ),
          ),

          // 2. Sub-Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF151928),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.headset_mic_outlined, size: 14, color: Color(0xFF00E676)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _getSubtext(),
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // 3. Box Tab Special Badge Bar
          if (_tabController.index == 1)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF151928),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(children: [Icon(Icons.auto_awesome, color: Color(0xFF80D8FF), size: 14), SizedBox(width: 4), Text('80', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))]),

Row(children: [Icon(Icons.auto_awesome, color: Color(0xFFE040FB), size: 14), SizedBox(width: 4), Text('100', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))]),
                  Row(children: [Icon(Icons.auto_awesome, color: Color(0xFFFF4081), size: 14), SizedBox(width: 4), Text('120', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))]),
                  Row(children: [Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 14), SizedBox(width: 4), Text('180', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))]),
                ],
              ),
            ),

          // 4. Gifts Grid with IN-CARD Send Button
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGiftGrid(_luckyGifts),
                _buildGiftGrid(_boxGifts),
                _buildGiftGrid(_flagGifts),
                _buildGiftGrid(_classicGifts),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftGrid(List<GiftItem> list) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.72,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final isSelected = _selectedGiftId == item.id;
        final int totalPrice = item.price * _sendCount;
        final bool canAfford = widget.userCoins >= totalPrice;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedGiftId != item.id) {
                _selectedGiftId = item.id;
              }
            });
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1F1A42) : const Color(0xFF131726),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Gift Image
                    Image.network(
                      item.iconUrl,
                      width: isSelected ? 34 : 38,
                      height: isSelected ? 34 : 38,
                      fit: BoxFit.contain,
                      errorBuilder: (_, , _) => const Icon(Icons.card_giftcard, size: 32, color: Colors.pinkAccent),
                    ),
                    const SizedBox(height: 3),

                    // Price Badge (Green 'T' pill)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle),

child: const Center(child: Text('T', style: TextStyle(color: Colors.black, fontSize: 7, fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${item.price}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),

                    // In-card Action: If Selected => Show 'Send' Button, Else => Show Gift Name
                    if (isSelected)
                      GestureDetector(
                        onTap: () {
                          if (canAfford) {
                            Navigator.pop(context);
                            widget.onSendGift(
                              _sendCount > 1 ? '${item.name} x$_sendCount' : item.name,
                              totalPrice,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Insufficient Coins!'), duration: Duration(seconds: 1)),
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C5CE7).withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Send',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        item.name,
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Multiplier Pill (x1 ∨) on Top when Selected
              if (isSelected)
                Positioned(
                  top: -6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _showCountPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFF3366), Color(0xFFFF6B8B)]),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: Row(

mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('x$_sendCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Top-Right Tag (e.g. 4%, For You #1)
              if (item.tag != null && !isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFFFF4081), Color(0xFFFF79B0)]),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(10),
                      ),
                    ),
                    child: Text(
                      item.tag!,
                      style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
