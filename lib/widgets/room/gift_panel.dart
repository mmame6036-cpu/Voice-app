import 'package:flutter/material.dart';
import '../../services/user_service.dart';

class GiftItem {
  final String id;
  final String name;
  final int price;
  final String imageUrl;
  final String? badge;
  final bool isLucky;

  const GiftItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.badge,
    this.isLucky = false,
  });
}

class GiftPanel extends StatefulWidget {
  final int userCoins;
  final List<Map<String, dynamic>> seats;
  final Function(String name, int price, int count, bool isLucky) onSendGift;

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
    required Function(String name, int price, int count, bool isLucky) onSendGift,
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
  late int _coins;
  String _selectedGiftId = 'lollipop';
  int _sendCount = 1;

  final List<int> _presetCounts = const [500, 200, 100, 77, 33, 10, 1];

  final List<GiftItem> _gifts = const [
    GiftItem(
      id: 'lollipop',
      name: 'Lollipop',
      price: 10,
      imageUrl: 'assets/gifts/3d-lollipop.png',
      badge: '+LUCKY',
      isLucky: true,
    ),
    GiftItem(
      id: 'rocket',
      name: 'Gold Rocket',
      price: 1000,
      imageUrl: 'assets/gifts/icons8-rocket-94.png',
      badge: '25倍',
      isLucky: true,
    ),
    GiftItem(
      id: 'sports_car',
      name: 'Super Car',
      price: 500,
      imageUrl: 'assets/gifts/3d-car.png',
      badge: 'Hot',
      isLucky: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _coins = widget.userCoins;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCountMenu(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xFF131724),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'የስጦታ ብዛት ምረጥ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              ..._presetCounts.map((c) {
                final isSel = _sendCount == c;
                return ListTile(
                  title: Text(
                    'x$c',
                    style: TextStyle(
                      color: isSel ? const Color(0xFF00C9A7) : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  trailing: isSel
                      ? const Icon(Icons.check_circle, color: Color(0xFF00C9A7))
                      : null,
                  onTap: () {
                    setState(() => _sendCount = c);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

@override
  Widget build(BuildContext context) {
    final selectedGift = _gifts.firstWhere(
      (g) => g.id == _selectedGiftId,
      orElse: () => _gifts.first,
    );
    final totalPrice = selectedGift.price * _sendCount;
    final canAfford = _coins >= totalPrice;

    return Container(
      height: MediaQuery.of(context).size.height * 0.58,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1322),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: const Color(0xFF00C9A7),
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    tabs: const [
                      Tab(text: 'Hot'),
                      Tab(text: 'Lucky'),
                      Tab(text: 'Luxury'),
                      Tab(text: 'Intimacy'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2230),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$_coins',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGiftGrid(_gifts),
                _buildGiftGrid(_gifts.where((g) => g.isLucky).toList()),
                _buildGiftGrid(_gifts.where((g) => !g.isLucky).toList()),
                _buildGiftGrid(_gifts),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0A0D18),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                const Spacer(),
                GestureDetector(
                  onTap: () => _showCountMenu(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2638),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '$_sendCount',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 4),

const Icon(Icons.arrow_drop_up, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    if (canAfford) {
                      setState(() {
                        _coins -= totalPrice;
                        UserService().coins = _coins;
                      });
                      Navigator.pop(context);
                      widget.onSendGift(
                        selectedGift.name,
                        selectedGift.price,
                        _sendCount,
                        selectedGift.isLucky,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ሳንቲም አልበቃም!'), duration: Duration(seconds: 1)),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C9A7), Color(0xFF00E676)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Send',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.78,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final isSelected = _selectedGiftId == item.id;

        return GestureDetector(
          onTap: () => setState(() => _selectedGiftId = item.id),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E1B3A) : const Color(0xFF141929),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFF00C9A7) : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Image.asset(
                      item.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.card_giftcard,
                        size: 38,
                        color: Colors.amberAccent,
                      ),
                    ),
                  ),
                ),
                Text(
                  item.name,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 11),

const SizedBox(width: 3),
                    Text(
                      '${item.price}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }
}
