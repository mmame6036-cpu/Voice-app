import 'package:flutter/material.dart';

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

class _GiftPanelState extends State<GiftPanel> {
  int _selectedGiftIndex = 0;
  String _selectedTarget = 'All Room';

  final List<Map<String, dynamic>> _gifts = const [
    {'name': 'Rose', 'price': 10, 'icon': Icons.local_florist, 'color': Colors.pinkAccent},
    {'name': 'Heart', 'price': 50, 'icon': Icons.favorite, 'color': Colors.redAccent},
    {'name': 'Crown', 'price': 500, 'icon': Icons.military_tech, 'color': Colors.amber},
    {'name': 'Rocket', 'price': 2000, 'icon': Icons.rocket_launch, 'color': Colors.purpleAccent},
    {'name': 'Diamond', 'price': 5000, 'icon': Icons.diamond, 'color': Colors.cyanAccent},
    {'name': 'Super Car', 'price': 10000, 'icon': Icons.directions_car, 'color': Colors.orangeAccent},
  ];

  @override
  Widget build(BuildContext context) {
    final activeUsers = widget.seats
        .where((s) => s['user'] != null && s['user'].toString().isNotEmpty)
        .map((s) => s['user'].toString())
        .toSet()
        .toList();

    final selectedGift = _gifts[_selectedGiftIndex];
    final int price = selectedGift['price'] as int;
    final bool canAfford = widget.userCoins >= price;

    return Container(
      height: 440,
      decoration: const BoxDecoration(
        color: Color(0xFF131826),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                    const SizedBox(width: 5),
                    Text(
                      '${widget.userCoins}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (activeUsers.isNotEmpty) ...[
            SizedBox(
              height: 34,
              child: ListView(

scrollDirection: Axis.horizontal,
                children: [
                  _buildTargetChip('All Room'),
                  ...activeUsers.map((u) => _buildTargetChip(u)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.95,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _gifts.length,
              itemBuilder: (context, index) {
                final gift = _gifts[index];
                final isSelected = _selectedGiftIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedGiftIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF261D4E) : const Color(0xFF1B2233),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF7B4DFF) : Colors.white10,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          gift['icon'] as IconData,
                          size: 38,
                          color: gift['color'] as Color,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          gift['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.amber, size: 12),
                            const SizedBox(width: 3),
                            Text(
                              '${gift['price']}',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford ? const Color(0xFF7B4DFF) : Colors.grey.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                elevation: 4,
              ),
              onPressed: canAfford
                  ? () {
                      Navigator.pop(context);
                      widget.onSendGift(
                        selectedGift['name'] as String,
                        price,
                      );
                    }
                  : null,
              child: Text(

canAfford ? 'Send ($price Coins)' : 'Insufficient Coins',
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
    );
  }

  Widget _buildTargetChip(String label) {
    final isSelected = _selectedTarget == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF7B4DFF),
        backgroundColor: const Color(0xFF1B2233),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        onSelected: (val) {
          if (val) setState(() => _selectedTarget = label);
        },
      ),
    );
  }
}
