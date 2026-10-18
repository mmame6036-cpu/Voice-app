import 'package:flutter/material.dart';

class GiftItem {
  final String id;
  final String name;
  final int price;
  final IconData icon;
  final Color color;
  final String? tag; // e.g., '4%', 'For You #1'

  const GiftItem({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    required this.color,
    this.tag,
  });
}

class GiftPanel extends StatefulWidget {
  final int userCoins;
  final List<Map<String, dynamic>> seats;
  final Function(String name, int price, int count, String targetUser, IconData icon, Color color) onSendGift;

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
    required Function(String name, int price, int count, String targetUser, IconData icon, Color color) onSendGift,
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
  GiftItem? _selectedGift;
  int _sendCount = 1;
  String _selectedTarget = 'All';

  // 1. Lucky Gifts
  final List<GiftItem> _luckyGifts = const [
    GiftItem(id: 'red_pack', name: 'Red Package', price: 10, icon: Icons.card_giftcard, color: Colors.pinkAccent),
    GiftItem(id: 'emerald', name: 'Emerald Brew', price: 100, icon: Icons.sports_bar, color: Colors.greenAccent),
    GiftItem(id: 'party_burst', name: 'Party Burst', price: 1000, icon: Icons.celebration, color: Colors.purpleAccent),
    GiftItem(id: 'falcon', name: 'Green Falcon', price: 10000, icon: Icons.flight, color: Colors.tealAccent),
    GiftItem(id: 'like', name: 'Like', price: 10, icon: Icons.thumb_up, color: Colors.blueAccent),
    GiftItem(id: 'cherry', name: 'Cherry', price: 20, icon: Icons.eco, color: Colors.redAccent),
    GiftItem(id: 'beer', name: 'Beer', price: 20, icon: Icons.local_drink, color: Colors.amber),
    GiftItem(id: 'balloon', name: 'Balloon', price: 100, icon: Icons.bubble_chart, color: Colors.pink, tag: '4%'),
    GiftItem(id: 'donut', name: 'Donut', price: 1000, icon: Icons.donut_large, color: Colors.deepPurpleAccent, tag: '4%'),
    GiftItem(id: 'crown', name: 'Crown', price: 100, icon: Icons.military_tech, color: Colors.amberAccent, tag: '4%'),
    GiftItem(id: 'unicorn', name: 'Royal Unicorn', price: 5000, icon: Icons.pets, color: Colors.orangeAccent),
    GiftItem(id: 'flower', name: 'Flower', price: 50, icon: Icons.local_florist, color: Colors.pinkAccent),
  ];

  // 2. Box Gifts
  final List<GiftItem> _boxGifts = const [
    GiftItem(id: 'neon_orbit', name: 'Neon Orbit', price: 1000, icon: Icons.album, color: Colors.cyanAccent),
    GiftItem(id: 'dream_jelly', name: 'Dream Jelly', price: 10000, icon: Icons.bubble_chart, color: Colors.pinkAccent),
    GiftItem(id: 'soul_blade', name: 'Soul Blade', price: 50000, icon: Icons.hardware, color: Colors.purpleAccent),
    GiftItem(id: 'star_racer', name: 'Star Racer', price: 100000, icon: Icons.directions_car, color: Colors.blueAccent),
    GiftItem(id: 'divine_gate', name: 'Divine Gate', price: 200000, icon: Icons.door_sliding, color: Colors.amber),
    GiftItem(id: 'flame_phoenix', name: 'Flame Phoenix', price: 500000, icon: Icons.whatshot, color: Colors.orangeAccent),
  ];

  // 3. Flag Gifts
  final List<GiftItem> _flagGifts = const [
    GiftItem(id: 'et_flag', name: 'ET Flag', price: 100000, icon: Icons.flag, color: Colors.green),

GiftItem(id: 'eg_flag', name: 'EG Flag', price: 100000, icon: Icons.flag, color: Colors.redAccent),
    GiftItem(id: 'de_flag', name: 'DE Flag', price: 100000, icon: Icons.flag, color: Colors.amber),
    GiftItem(id: 'br_flag', name: 'BR Flag', price: 100000, icon: Icons.flag, color: Colors.yellow),
  ];

  // 4. Classic Gifts
  final List<GiftItem> _classicGifts = const [
    GiftItem(id: 'sweet_crush', name: 'Sweet Crush', price: 200, icon: Icons.favorite, color: Colors.redAccent),
    GiftItem(id: 'love_band', name: 'Love Band', price: 500, icon: Icons.panorama_fish_eye, color: Colors.pinkAccent),
    GiftItem(id: 'bread', name: 'Bread', price: 50, icon: Icons.breakfast_dining, color: Colors.brown),
    GiftItem(id: 'fairy_wings', name: 'Fairy Wings', price: 10000, icon: Icons.air, color: Colors.cyanAccent),
    GiftItem(id: 'panda_hero', name: 'Panda Hero', price: 2000, icon: Icons.pets, color: Colors.white),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedGift = _luckyGifts.first;
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
      backgroundColor: const Color(0xFF161C2B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: counts.map((c) {
            return ListTile(
              title: Text('x$c', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: _sendCount == c ? const Icon(Icons.check, color: Color(0xFF7B4DFF)) : null,
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
      backgroundColor: const Color(0xFF161C2B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('All (Entire Room)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: _selectedTarget == 'All' ? const Icon(Icons.check, color: Color(0xFF7B4DFF)) : null,
              onTap: () {
                setState(() => _selectedTarget = 'All');
                Navigator.pop(ctx);
              },
            ),
            ...activeUsers.map((u) {
              return ListTile(
                title: Text(u, style: const TextStyle(color: Colors.white)),
                trailing: _selectedTarget == u ? const Icon(Icons.check, color: Color(0xFF7B4DFF)) : null,
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

  @override
  Widget build(BuildContext context) {
    final int totalPrice = (_selectedGift?.price ?? 0) * _sendCount;
    final bool canAfford = widget.userCoins >= totalPrice;

    return Container(
      height: 480,
      decoration: const BoxDecoration(
        color: Color(0xFF121524),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(

children: [
          // 1. Header (Tabs + Target + Coins)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: const Color(0xFF7B4DFF),
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2538),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_selectedTarget, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 15),
                    const SizedBox(width: 3),
                    Text(
                      '${widget.userCoins}',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white54, size: 16),
                  ],
                ),
              ],
            ),
          ),

          // 2. Banner info / Subtext
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFF181D2E),
            child: const Row(
              children: [
                Icon(Icons.volunteer_activism_outlined, size: 14, color: Colors.greenAccent),
                SizedBox(width: 6),
                Text(
                  'Provided by the system for gifting experience.',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),

          // 3. Grid View for each Tab
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

          // 4. Bottom Send Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF161A2B),
              border: Border(top: BorderSide(color: Colors.white10)),

),
            child: Row(
              children: [
                if (_selectedGift != null) ...[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _selectedGift!.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_selectedGift!.icon, color: _selectedGift!.color, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedGift!.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '$totalPrice',
                            style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: _showCountPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22283D),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Text('x$_sendCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAfford ? const Color(0xFF7B4DFF) : Colors.grey.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  ),
                  onPressed: (_selectedGift != null && canAfford)
                      ? () {
                          Navigator.pop(context);
                          widget.onSendGift(
                            _selectedGift!.name,
                            _selectedGift!.price,
                            _sendCount,
                            _selectedTarget,
                            _selectedGift!.icon,
                            _selectedGift!.color,
                          );
                        }
                      : null,
                  child: Text(
                    canAfford ? 'Send' : 'No Coins',
                    style: TextStyle(
                      color: canAfford ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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

  Widget _buildGiftGrid(List<GiftItem> list) {

return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.82,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final isSelected = _selectedGift?.id == item.id;

        return GestureDetector(
          onTap: () => setState(() => _selectedGift = item),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2A2054) : const Color(0xFF181E2F),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF7B4DFF) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 30, color: item.color),
                      const SizedBox(height: 5),
                      Text(
                        item.name,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.amber, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            '${item.price}',
                            style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (item.tag != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE91E63),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(14),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      item.tag!,
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
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
