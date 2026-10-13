import 'package:flutter/material.dart';

class GiftPanel extends StatelessWidget {
  final int userCoins;
  final Function(String name, int price) onSendGift;

  const GiftPanel({
    Key? key,
    required this.userCoins,
    required this.onSendGift,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required int userCoins,
    required Function(String name, int price) onSendGift,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GiftPanel(
        userCoins: userCoins,
        onSendGift: onSendGift,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gifts = [
      {'name': 'Rose', 'price': 10, 'icon': Icons.local_florist, 'color': Colors.pinkAccent},
      {'name': 'Heart', 'price': 50, 'icon': Icons.favorite, 'color': Colors.redAccent},
      {'name': 'Crown', 'price': 500, 'icon': Icons.military_tech, 'color': Colors.amber},
      {'name': 'Rocket', 'price': 2000, 'icon': Icons.rocket_launch, 'color': Colors.purpleAccent},
      {'name': 'Diamond', 'price': 5000, 'icon': Icons.diamond, 'color': Colors.cyanAccent},
      {'name': 'Super Car', 'price': 10000, 'icon': Icons.directions_car, 'color': Colors.orangeAccent},
    ];

    return Container(
      height: 380,
      decoration: const BoxDecoration(
        color: Color(0xFF161C2B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Send Gift',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$userCoins',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.95,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: gifts.length,
              itemBuilder: (context, index) {
                final gift = gifts[index];
                final name = gift['name'] as String;
                final price = gift['price'] as int;

                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onSendGift(name, price);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF222C3D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          gift['icon'] as IconData,
                          size: 36,
                          color: gift['color'] as Color,

),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$price Coins',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
