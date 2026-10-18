import 'package:flutter/material.dart';

class GiftItem {
  final String id;
  final String name;
  final int price;
  final IconData icon;
  final Color color;
  final String? tag;

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
  GiftItem? _selectedGift;
  int _sendCount = 1;
  String _selectedTarget = 'All';

  final List<GiftItem> _luckyGifts = const [
    GiftItem(id: 'red_pack', name: 'Red Package', price: 10, icon: Icons.card_giftcard, color: Color(0xFFFF3366)),
    GiftItem(id: 'emerald', name: 'Emerald Brew', price: 100, icon: Icons.local_drink, color: Color(0xFF00E676)),
    GiftItem(id: 'party_burst', name: 'Party Burst', price: 1000, icon: Icons.celebration, color: Color(0xFFFFD700)),
    GiftItem(id: 'falcon', name: 'Green Falcon', price: 10000, icon: Icons.flight, color: Color(0xFF00F5D4)),
    GiftItem(id: 'like', name: 'Like', price: 10, icon: Icons.thumb_up, color: Color(0xFFE040FB)),
    GiftItem(id: 'cherry', name: 'Cherry', price: 20, icon: Icons.eco, color: Color(0xFFFF1744)),
    GiftItem(id: 'beer', name: 'Beer', price: 20, icon: Icons.sports_bar, color: Color(0xFFFFB300)),
    GiftItem(id: 'balloon', name: 'Balloon', price: 100, icon: Icons.bubble_chart, color: Color(0xFFFF4081), tag: '4%'),
    GiftItem(id: 'donut', name: 'Donut', price: 1000, icon: Icons.donut_large, color: Color(0xFFBA68C8), tag: '4%'),
    GiftItem(id: 'crown', name: 'Crown', price: 100, icon: Icons.military_tech, color: Color(0xFFFFD54F), tag: '4%'),
    GiftItem(id: 'unicorn', name: 'Royal Unicorn', price: 5000, icon: Icons.auto_awesome, color: Color(0xFFFFAB40)),
    GiftItem(id: 'flower', name: 'Flower', price: 50, icon: Icons.local_florist, color: Color(0xFFF06292)),
    GiftItem(id: 'star', name: 'Star', price: 50, icon: Icons.star, color: Color(0xFFFFEE58)),
    GiftItem(id: 'water_gun', name: 'Water Gun', price: 50, icon: Icons.opacity, color: Color(0xFF4FC3F7)),
    GiftItem(id: 'headset', name: 'Headset', price: 500, icon: Icons.headphones, color: Color(0xFFBA68C8)),
    GiftItem(id: 'ring', name: 'Ring', price: 500, icon: Icons.album, color: Color(0xFFE040FB)),
    GiftItem(id: 'music_box', name: 'Music Box', price: 1000, icon: Icons.music_note, color: Color(0xFFFFD700)),
    GiftItem(id: 'treasure', name: 'Treasure', price: 5000, icon: Icons.inventory_2, color: Color(0xFFFFB300)),
    GiftItem(id: 'hyper_car', name: 'Hyper Car', price: 50000, icon: Icons.directions_car, color: Color(0xFFFF9100)),
  ];

  final List<GiftItem> _boxGifts = const [
    GiftItem(id: 'neon_orbit', name: 'Neon Orbit', price: 1000, icon: Icons.blur_circular, color: Color(0xFF00E5FF)),
    GiftItem(id: 'dream_jelly', name: 'Dream Jelly', price: 10000, icon: Icons.bubble_chart, color: Color(0xFFFF4081)),

GiftItem(id: 'soul_blade', name: 'Soul Blade', price: 50000, icon: Icons.flash_on, color: Color(0xFF7C4DFF)),
    GiftItem(id: 'star_racer', name: 'Star Racer', price: 100000, icon: Icons.sports_motorsports, color: Color(0xFFFF5252)),
    GiftItem(id: 'divine_gate', name: 'Divine Gate', price: 200000, icon: Icons.door_front_door, color: Color(0xFFFFD700)),
    GiftItem(id: 'flame_phoenix', name: 'Flame Phoenix', price: 500000, icon: Icons.local_fire_department, color: Color(0xFFFF6E40)),
  ];

  final List<GiftItem> _flagGifts = const [
    GiftItem(id: 'et_flag', name: 'ET Flag', price: 100000, icon: Icons.flag, color: Color(0xFF00E676)),
    GiftItem(id: 'eg_flag', name: 'EG Flag', price: 100000, icon: Icons.flag, color: Color(0xFFFF1744)),
    GiftItem(id: 'de_flag', name: 'DE Flag', price: 100000, icon: Icons.flag, color: Color(0xFFFFD600)),
    GiftItem(id: 'br_flag', name: 'BR Flag', price: 100000, icon: Icons.flag, color: Color(0xFF76FF03)),
  ];

  final List<GiftItem> _classicGifts = const [
    GiftItem(id: 'sweet_crush', name: 'Sweet Crush', price: 200, icon: Icons.favorite, color: Color(0xFFFF1744)),
    GiftItem(id: 'love_band', name: 'Love Band', price: 500, icon: Icons.radio_button_checked, color: Color(0xFFFF4081)),
    GiftItem(id: 'bread', name: 'Bread', price: 50, icon: Icons.bakery_dining, color: Color(0xFFFFB74D)),
    GiftItem(id: 'fairy_wings', name: 'Fairy Wings', price: 10000, icon: Icons.filter_vintage, color: Color(0xFF80D8FF)),
    GiftItem(id: 'panda_hero', name: 'Panda Hero', price: 2000, icon: Icons.cruelty_free, color: Colors.white),
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

@override
  Widget build(BuildContext context) {
    final int totalPrice = (_selectedGift?.price ?? 0) * _sendCount;
    final bool canAfford = widget.userCoins >= totalPrice;

    return Container(
      height: 520,
      decoration: const BoxDecoration(
        color: Color(0xFF0F121D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 1. የላይኛው ታቦች እና የሳንቲም ማሳያ
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 12, 0),
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
                        child: const Text('C', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
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

          // 2. የማስታወቂያ መስመር
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF161A2B),

borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.headset_mic_outlined, size: 14, color: Color(0xFF00E676)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Provided by the system for gifting experience.',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // 3. የስጦታዎች ዝርዝር
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

          // 4. ልክ እንደ ቪዲዮው የታችኛው የመላኪያ ክፍል
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF121524),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                if (_selectedGift != null) ...[
                  // አረንጓዴው ሳንቲም ባጅ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2438),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00E676).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle),
                          child: const Text('T', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${_selectedGift!.price}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: _showCountPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2438),
                      borderRadius: BorderRadius.circular(16),
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
                GestureDetector(
                  onTap: (_selectedGift != null && canAfford)
                      ? () {
                          Navigator.pop(context);
                          widget.onSendGift(
                            _sendCount > 1 ? '${_selectedGift!.name} x$_sendCount' : _selectedGift!.name,
                            totalPrice,
                          );

}
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: canAfford
                          ? const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)])
                          : LinearGradient(colors: [Colors.grey.shade800, Colors.grey.shade700]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: canAfford
                          ? [BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 3))]
                          : [],
                    ),
                    child: Text(
                      canAfford ? 'Send' : 'No Coins',
                      style: TextStyle(
                        color: canAfford ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.78,
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
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF221A4C) : const Color(0xFF151827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 36, color: item.color),
                      const SizedBox(height: 6),
                      Text(
                        item.name,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(color: Color(0xFFFFD700), shape: BoxShape.circle),
                            child: const Center(child: Text('T', style: TextStyle(color: Colors.black, fontSize: 7, fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${item.price}',
                            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFFFF4081), Color(0xFFFF79B0)]),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(10),
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
