import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/user_service.dart';

class GiftItem {
  final String id;
  final String name;
  final int price;
  final String imageUrl;
  final String? badge;

  const GiftItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
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
  late int _coins;
  String _selectedGiftId = 'lucky_bag';
  int _sendCount = 1;
  String _selectedTarget = 'All';

  final List<GiftItem> _hotGifts = const [
    GiftItem(
      id: 'lucky_bag',
      name: 'Lucky Bag',
      price: 10,
      imageUrl: 'https://images.vexels.com/media/users/3/242241/isolated/preview/261899e4f5aa1a547fae3ef24ec441ba-chinese-new-year-lucky-bag-3d.png',
      badge: '20倍',
    ),
    GiftItem(
      id: 'crown',
      name: 'Crown',
      price: 100,
      imageUrl: 'https://images.vexels.com/media/users/3/242232/isolated/preview/a1f592231ff61a6c0c538cb986161a0f-golden-crown-3d-icon.png',
      badge: '310倍',
    ),
    GiftItem(
      id: 'sports_car',
      name: 'Super Car',
      price: 500,
      imageUrl: 'https://images.vexels.com/media/users/3/242240/isolated/preview/30d2ae15f62f3a61f51390ea0687399a-futuristic-sports-car-3d.png',
    ),
    GiftItem(
      id: 'rocket',
      name: 'Gold Rocket',
      price: 1000,
      imageUrl: 'https://images.vexels.com/media/users/3/242236/isolated/preview/fa9b24da4ec6c6563604f14188f6ba02-space-rocket-launch-3d.png',
      badge: '25倍',
    ),
    GiftItem(
      id: 'diamond_ring',
      name: 'CP Ring',
      price: 2000,
      imageUrl: 'https://images.vexels.com/media/users/3/242233/isolated/preview/e1d5e3c66f6be985ef437dae6c6023e8-diamond-gemstone-ring-3d.png',
    ),
    GiftItem(
      id: 'treasure_chest',
      name: 'Treasure',
      price: 5000,
      imageUrl: 'https://images.vexels.com/media/users/3/242234/isolated/preview/b9dfb273d6bb6c4ae234ffce6f809988-treasure-chest-coins-3d.png',
    ),
    GiftItem(
      id: 'heart_balloon',
      name: 'Love Heart',
      price: 50,
      imageUrl: 'https://images.vexels.com/media/users/3/242238/isolated/preview/79dae133c91a0980b67bf919323c21c8-glowing-heart-gem-3d.png',
    ),
    GiftItem(
      id: 'magic_castle',
      name: 'Dream Castle',
      price: 10000,
      imageUrl: 'https://images.vexels.com/media/users/3/242237/isolated/preview/b7f14170327be63e3d489ae991e44f80-fantasy-floating-castle-3d.png',
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

  void _showRechargeSheet() {
    final amounts = [1000, 5000, 10000, 50000];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131724),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Recharge Coins',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: amounts.length,
                itemBuilder: (context, i) {
                  final amt = amounts[i];
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      setState(() {
                        _coins += amt;
                        UserService().coins += amt;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('+$amt ሳንቲም ተሞልቷል! 🪙'), backgroundColor: const Color(0xFF00C9A7)),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2436),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF00C9A7).withOpacity(0.4)),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                            const SizedBox(width: 6),
                            Text('+$amt', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override

Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.60,
      decoration: const BoxDecoration(
        color: Color(0xFF0C0F1D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 0),
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
                      Tab(text: 'Hot'),
                      Tab(text: 'Lucky'),
                      Tab(text: 'Luxury'),
                      Tab(text: 'Intimacy'),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _showRechargeSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2230),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$_coins',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.add_circle, color: Color(0xFF00C9A7), size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.backpack_outlined, color: Colors.white70, size: 22),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF151928),
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
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGiftGrid(_hotGifts),
                _buildGiftGrid(_hotGifts),
                _buildGiftGrid(_hotGifts),
                _buildGiftGrid(_hotGifts),
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
        final bool canAfford = _coins >= totalPrice;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedGiftId = item.id;
            });
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1C1738) : const Color(0xFF131724),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00C9A7) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.card_giftcard,
                            size: 40,
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 11,
                            height: 11,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00E676),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('T', style: TextStyle(color: Colors.black, fontSize: 7, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.price}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (isSelected)
                      GestureDetector(
                        onTap: () {
                          if (canAfford) {
                            setState(() {
                              _coins -= totalPrice;
                              UserService().coins = _coins;
                            });
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
                              colors: [Color(0xFF00C9A7), Color(0xFF00E676)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Send',
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          item.name,
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
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
                          gradient: const LinearGradient(colors: [Color(0xFFFF3366), Color(0xFFFF5252)]),
                          borderRadius: BorderRadius.circular(10),
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
            ],
          ),
        );
      },
    );
  }
}
