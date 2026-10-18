import 'package:flutter/material.dart';

class GiftItem {
  final String id;
  final String name;
  final int price;
  final String iconUrl;
  final String? badge;

  const GiftItem({
    required this.id,
    required this.name,
    required this.price,
    required this.iconUrl,
    this.badge,
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

  // 1. Hot Gifts
  final List<GiftItem> _hotGifts = const [
    GiftItem(id: 'lucky_bag', name: 'Lucky Bag', price: 10, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2614/2614635.png', badge: '20倍'),
    GiftItem(id: 'hala_elephant', name: 'HalaElephant', price: 100, iconUrl: 'https://cdn-icons-png.flaticon.com/512/375/375103.png', badge: '310倍'),
    GiftItem(id: 'hi', name: 'Hi', price: 100, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1077/1077035.png'),
    GiftItem(id: 'heart', name: 'Heart', price: 100, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2107/2107845.png'),
    GiftItem(id: 'azure_melody', name: 'Azure Melody', price: 100, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3844/3844724.png', badge: '25倍'),
    GiftItem(id: 'light_stick', name: 'Light Stick', price: 100, iconUrl: 'https://cdn-icons-png.flaticon.com/512/824/824239.png'),
    GiftItem(id: 'beverage', name: 'Beverage', price: 100, iconUrl: 'https://cdn-icons-png.flaticon.com/512/924/924514.png'),
    GiftItem(id: 'ice_cream', name: 'Ice Cream', price: 500, iconUrl: 'https://cdn-icons-png.flaticon.com/512/931/931949.png'),
    GiftItem(id: 'pendant', name: 'Pendant', price: 750, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1257/1257140.png'),
    GiftItem(id: 'drum', name: 'Drum', price: 1000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2972/2972118.png'),
    GiftItem(id: 'balloon_kitty', name: 'BalloonKitty', price: 1000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2682/2682446.png'),
    GiftItem(id: 'lipstick', name: 'Lipstick', price: 3500, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3655/3655610.png'),
    GiftItem(id: 'magic_carpet', name: 'Magic Carpet', price: 4500, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1162/1162499.png'),
    GiftItem(id: 'bouncy_pony', name: 'Bouncy Pony', price: 5000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3468/3468306.png'),
    GiftItem(id: 'swan_cake', name: 'Swan Cake', price: 10000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3081/3081974.png'),
    GiftItem(id: 'crown', name: 'Crown', price: 10000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/263/263059.png'),
    GiftItem(id: 'candy_cannon', name: 'Candy Cannon', price: 15000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/4213/4213653.png'),
    GiftItem(id: 'dreamcatcher', name: 'Dreamcatcher', price: 20000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2972/2972531.png'),
    GiftItem(id: 'crystal_hammer', name: 'Crystal Hammer', price: 20000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3468/3468379.png'),

GiftItem(id: 'cp_teacup', name: 'CP teacup', price: 20000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3655/3655580.png'),
    GiftItem(id: 'money_gun', name: 'Money Gun', price: 30000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2614/2614631.png'),
    GiftItem(id: 'fortune_pi_xiu', name: 'Fortune Pi Xiu', price: 38888, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1418/1418301.png'),
    GiftItem(id: 'sweetheart_choco', name: 'Sweetheart Choco', price: 40000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3014/3014524.png'),
    GiftItem(id: 'birthday_cake', name: 'Birthday Cake', price: 45000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2682/2682446.png'),
    GiftItem(id: 'castle_feast', name: 'Castle Feast', price: 100000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2271/2271068.png'),
  ];

  // 2. Lucky Gifts
  final List<GiftItem> _luckyGifts = const [
    GiftItem(id: 'lollipop', name: 'Lollipop', price: 10, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3081/3081974.png'),
    GiftItem(id: 'capiz', name: 'Capiz', price: 30, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3590/3590212.png'),
    GiftItem(id: 'diamond', name: 'Diamond', price: 100, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1828/1828884.png'),
    GiftItem(id: 'gold_bar', name: 'Gold bar', price: 100, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2614/2614631.png'),
    GiftItem(id: 'cola', name: 'Cola', price: 10, iconUrl: 'https://cdn-icons-png.flaticon.com/512/924/924514.png'),
    GiftItem(id: 'trumpet', name: 'Trumpet', price: 10, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2972/2972118.png'),
    GiftItem(id: 'hala_champagne', name: 'Hala Champagne', price: 20, iconUrl: 'https://cdn-icons-png.flaticon.com/512/924/924514.png'),
    GiftItem(id: 'lucky_clover', name: 'Lucky Clover', price: 20, iconUrl: 'https://cdn-icons-png.flaticon.com/512/869/869869.png'),
    GiftItem(id: 'teddy_bear', name: 'Teddy Bear', price: 20, iconUrl: 'https://cdn-icons-png.flaticon.com/512/375/375103.png'),
    GiftItem(id: 'dice', name: 'Dice', price: 20, iconUrl: 'https://cdn-icons-png.flaticon.com/512/808/808439.png'),
    GiftItem(id: 'star', name: 'Star', price: 50, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1828/1828884.png'),
    GiftItem(id: 'beer', name: 'Beer', price: 20, iconUrl: 'https://cdn-icons-png.flaticon.com/512/931/931949.png'),
    GiftItem(id: 'macaron', name: 'Macaron', price: 50, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3014/3014524.png'),
    GiftItem(id: 'mango', name: 'Mango', price: 25, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1135/1135249.png'),
    GiftItem(id: 'grape', name: 'Grape', price: 20, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1135/1135249.png'),
    GiftItem(id: 'banana', name: 'Banana', price: 70, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1135/1135249.png'),
    GiftItem(id: 'watermelon', name: 'Watermelon', price: 20, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1135/1135249.png'),
    GiftItem(id: 'magic_lamp', name: 'Magic Lamp', price: 500, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3844/3844724.png'),
    GiftItem(id: 'rose', name: 'Rose', price: 2000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/744/744922.png'),
    GiftItem(id: 'crystal_shoes', name: 'Crystal Shoes', price: 2000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3655/3655610.png'),
    GiftItem(id: 'headphones', name: 'Headphones', price: 2000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/870/870132.png'),
  ];

  // 3. Luxury Gifts
  final List<GiftItem> _luxuryGifts = const [
    GiftItem(id: 'titanic', name: 'Titanic', price: 1000000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2945/2945517.png'),
    GiftItem(id: 'sky_romance', name: 'Sky Romance', price: 1200000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1356/1356479.png'),

GiftItem(id: 'sweet_confession', name: 'Sweet Confession', price: 1699999, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2107/2107845.png'),
    GiftItem(id: 'aircraft_carrier', name: 'Aircraft Carrier', price: 2000000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2945/2945517.png'),
    GiftItem(id: 'golden_throne_king', name: 'Golden Throne King', price: 4000000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/263/263059.png'),
    GiftItem(id: 'dream_castle', name: 'Dream Castle', price: 4000000, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2271/2271068.png'),
    GiftItem(id: 'astro_heart', name: 'Astro-Heart', price: 4999999, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3242/3242257.png'),
  ];

  // 4. Intimacy Gifts
  final List<GiftItem> _intimacyGifts = const [
    GiftItem(id: 'intimate_heart', name: 'Intimate Heart', price: 188, iconUrl: 'https://cdn-icons-png.flaticon.com/512/2107/2107845.png', badge: 'Intimacy Lv.1'),
    GiftItem(id: 'intimate_rose', name: 'Intimate Rose', price: 28888, iconUrl: 'https://cdn-icons-png.flaticon.com/512/744/744922.png', badge: 'Intimacy Lv.2'),
    GiftItem(id: 'intimate_cable', name: 'Intimate Cable', price: 188888, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3655/3655580.png', badge: 'Intimacy Lv.3'),
    GiftItem(id: 'cp_bird', name: 'CP Bird', price: 19999, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3468/3468306.png', badge: 'Intimacy'),
    GiftItem(id: 'cp_ring', name: 'CP Ring', price: 99999, iconUrl: 'https://cdn-icons-png.flaticon.com/512/1257/1257140.png', badge: 'Intimacy'),
    GiftItem(id: 'cp_global', name: 'CP Global', price: 999999, iconUrl: 'https://cdn-icons-png.flaticon.com/512/3844/3844724.png', badge: 'Intimacy'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedGift = _hotGifts.first;
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
      backgroundColor: const Color(0xFF131722),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: counts.map((c) {
            return ListTile(
              title: Text('x$c', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: _sendCount == c ? const Icon(Icons.check, color: Color(0xFF00C9A7)) : null,
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
      backgroundColor: const Color(0xFF131722),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('All (Entire Room)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: _selectedTarget == 'All' ? const Icon(Icons.check, color: Color(0xFF00C9A7)) : null,
              onTap: () {
                setState(() => _selectedTarget = 'All');
                Navigator.pop(ctx);
              },
            ),
            ...activeUsers.map((u) {
              return ListTile(

title: Text(u, style: const TextStyle(color: Colors.white)),
                trailing: _selectedTarget == u ? const Icon(Icons.check, color: Color(0xFF00C9A7)) : null,
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
      height: MediaQuery.of(context).size.height * 0.58,
      decoration: const BoxDecoration(
        color: Color(0xFF10131B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          // 1. Header (Hot, Lucky, Luxury, Intimacy + Target + Coins + Backpack)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 0),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
                    onTap: (_) => setState(() {}),
                    tabs: const [
                      Tab(text: 'Hot'),
                      Tab(text: 'Lucky'),
                      Tab(text: 'Luxury'),
                      Tab(text: 'Intimacy'),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _showTargetPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2230),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF00C9A7).withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Text(_selectedTarget, style: const TextStyle(color: Color(0xFF00C9A7), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_drop_down, color: Color(0xFF00C9A7), size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.backpack_outlined, color: Colors.white70, size: 22),
              ],
            ),
          ),

          // 2. የስጦታዎች ዝርዝር ግሪድ
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGiftGrid(_hotGifts),
                _buildGiftGrid(_luckyGifts),
                _buildGiftGrid(_luxuryGifts),
                _buildGiftGrid(_intimacyGifts),
              ],
            ),
          ),

          // 3. የታችኛው የመላኪያ ባር (የሳንቲም መጠን + x1 መምረጫ + Send ቁልፍ)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF141924),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(

children: [
                // የሳንቲም ባጅ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222B3D),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.userCoins}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.add_circle, color: Color(0xFF00C9A7), size: 16),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _showCountPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222B3D),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text('$_sendCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
                          ? const LinearGradient(colors: [Color(0xFF00C9A7), Color(0xFF00E676)])
                          : LinearGradient(colors: [Colors.grey.shade800, Colors.grey.shade700]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: canAfford
                          ? [BoxShadow(color: const Color(0xFF00C9A7).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))]
                          : [],
                    ),
                    child: Text(
                      canAfford ? 'Send' : 'No Coins',
                      style: TextStyle(
                        color: canAfford ? Colors.black : Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
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
                  color: const Color(0xFF161C28),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00C9A7) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        item.iconUrl,
                        width: 42,
                        height: 42,
                        fit: BoxFit.contain,
                        errorBuilder: (_, , _) => const Icon(Icons.card_giftcard, size: 36, color: Colors.pinkAccent),
                      ),
                      const SizedBox(height: 5),
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
                          const Icon(Icons.monetization_on, color: Colors.amber, size: 10),
                          const SizedBox(width: 3),
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
              if (item.badge != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFFFF3366), Color(0xFFFF5252)]),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      item.badge!,
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
