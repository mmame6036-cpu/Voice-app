import 'package:flutter/material.dart';

class StoreItem {
  final String id;
  final String title;
  final int price;
  final String category;
  final String? badge; // 'HOT' or 'NEW'
  final IconData icon;
  final Color accentColor;

  StoreItem({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    this.badge,
    required this.icon,
    required this.accentColor,
  });
}

class StoreScreen extends StatefulWidget {
  final int userCoins;
  final Function(int) onCoinsUpdated;

  const StoreScreen({
    Key? key,
    required this.userCoins,
    required this.onCoinsUpdated,
  }) : super(key: key);

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  int _selectedCategoryIndex = 3; // በዲፎልት 'Special ID' ላይ ይከፈታል
  late int _currentCoins;

  final List<String> categories = [
    'Popular',
    'Frame',
    'Entry',
    'Special ID',
    'Theme',
    'Room Card',
    'Room Frame',
    'Profile Card',
    'ChatBubble',
  ];

  late List<StoreItem> allStoreItems;

  @override
  void initState() {
    super.initState();
    _currentCoins = widget.userCoins;
    _initStoreData();
  }

  void _initStoreData() {
    allStoreItems = [
      // 1. Popular
      StoreItem(id: 'pop_1', title: 'Iron Claw', price: 300000, category: 'Popular', badge: 'HOT', icon: Icons.pets, accentColor: Colors.cyan),
      StoreItem(id: 'pop_2', title: 'Stellaphant', price: 300000, category: 'Popular', badge: 'HOT', icon: Icons.bubble_chart, accentColor: Colors.blueAccent),
      StoreItem(id: 'pop_3', title: 'Metropolis Lord', price: 21000, category: 'Popular', badge: 'HOT', icon: Icons.brightness_7, accentColor: Colors.amber),
      StoreItem(id: 'pop_4', title: 'Fighter', price: 21000, category: 'Popular', badge: 'HOT', icon: Icons.local_fire_department, accentColor: Colors.deepOrange),

      // 2. Frame
      StoreItem(id: 'frame_1', title: 'Star of Fortune', price: 30000, category: 'Frame', badge: 'NEW', icon: Icons.stars, accentColor: Colors.purpleAccent),
      StoreItem(id: 'frame_2', title: 'Lucky Bless', price: 30000, category: 'Frame', badge: 'NEW', icon: Icons.auto_awesome, accentColor: Colors.lightBlue),
      StoreItem(id: 'frame_3', title: 'Metropolis Lord', price: 21000, category: 'Frame', badge: 'HOT', icon: Icons.brightness_high, accentColor: Colors.amber),
      StoreItem(id: 'frame_4', title: 'Fighter', price: 21000, category: 'Frame', badge: 'HOT', icon: Icons.shield, accentColor: Colors.orange),

      // 3. Entry
      StoreItem(id: 'ent_1', title: 'Shark Moto', price: 300000, category: 'Entry', icon: Icons.two_wheeler, accentColor: Colors.purple),
      StoreItem(id: 'ent_2', title: 'Ice-Fire Soul', price: 400000, category: 'Entry', icon: Icons.water_drop, accentColor: Colors.lightBlueAccent),
      StoreItem(id: 'ent_3', title: 'Dragon-Kirin Gold', price: 450000, category: 'Entry', badge: 'NEW', icon: Icons.directions_car, accentColor: Colors.amber),
      StoreItem(id: 'ent_4', title: 'Iron Claw', price: 300000, category: 'Entry', badge: 'HOT', icon: Icons.electric_bolt, accentColor: Colors.blue),
      StoreItem(id: 'ent_5', title: 'Stellaphant', price: 300000, category: 'Entry', badge: 'HOT', icon: Icons.dark_mode, accentColor: Colors.indigo),
      StoreItem(id: 'ent_6', title: 'Spaceship', price: 450000, category: 'Entry', badge: 'HOT', icon: Icons.rocket_launch, accentColor: Colors.deepOrangeAccent),

      // 4. Special ID
      StoreItem(id: 'id_1166', title: '1166', price: 800000, category: 'Special ID', badge: 'HOT', icon: Icons.badge, accentColor: Colors.deepPurpleAccent),
      StoreItem(id: 'id_1177', title: '1177', price: 800000, category: 'Special ID', badge: 'HOT', icon: Icons.badge, accentColor: Colors.deepPurpleAccent),

StoreItem(id: 'id_1149', title: '1149', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1138', title: '1138', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1139', title: '1139', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1140', title: '1140', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1141', title: '1141', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1142', title: '1142', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1143', title: '1143', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1145', title: '1145', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1146', title: '1146', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1147', title: '1147', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1148', title: '1148', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1137', title: '1137', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1150', title: '1150', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1151', title: '1151', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1152', title: '1152', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1153', title: '1153', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1154', title: '1154', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1156', title: '1156', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1125', title: '1125', price: 800000, category: 'Special ID', icon: Icons.diamond, accentColor: Colors.blue),
      StoreItem(id: 'id_1100', title: '1100', price: 800000, category: 'Special ID', badge: 'HOT', icon: Icons.badge, accentColor: Colors.deepPurpleAccent),

      // 5. Theme
      StoreItem(id: 'th_1', title: 'Ocean World', price: 4200, category: 'Theme', icon: Icons.waves, accentColor: Colors.cyan),
      StoreItem(id: 'th_2', title: 'Red Rose', price: 4200, category: 'Theme', icon: Icons.local_florist, accentColor: Colors.red),
      StoreItem(id: 'th_3', title: 'Bar', price: 4200, category: 'Theme', badge: 'NEW', icon: Icons.nightlife, accentColor: Colors.purple),
      StoreItem(id: 'th_4', title: 'Gramophone', price: 4200, category: 'Theme', badge: 'NEW', icon: Icons.album, accentColor: Colors.amber),
      StoreItem(id: 'th_5', title: 'Purple Love', price: 4200, category: 'Theme', badge: 'NEW', icon: Icons.favorite, accentColor: Colors.pinkAccent),
      StoreItem(id: 'th_6', title: 'Emerald Realm', price: 3500, category: 'Theme', badge: 'HOT', icon: Icons.castle, accentColor: Colors.teal),
      StoreItem(id: 'th_7', title: 'Golden Vortex', price: 2800, category: 'Theme', badge: 'HOT', icon: Icons.cyclone, accentColor: Colors.orange),
      StoreItem(id: 'th_8', title: 'Lunar Cascade', price: 2100, category: 'Theme', badge: 'HOT', icon: Icons.waterfall_chart, accentColor: Colors.blueAccent),

// 6. Room Card
      StoreItem(id: 'rc_1', title: 'Emerald Realm', price: 7000, category: 'Room Card', icon: Icons.crop_portrait, accentColor: Colors.green),
      StoreItem(id: 'rc_2', title: 'Golden Vortex', price: 7000, category: 'Room Card', icon: Icons.crop_portrait, accentColor: Colors.amber),
      StoreItem(id: 'rc_3', title: 'Lunar Cascade', price: 7000, category: 'Room Card', icon: Icons.crop_portrait, accentColor: Colors.blue),
      StoreItem(id: 'rc_4', title: 'Fun Suit', price: 7000, category: 'Room Card', icon: Icons.celebration, accentColor: Colors.deepOrange),

      // 7. Room Frame
      StoreItem(id: 'rf_1', title: 'Ocean World', price: 4000, category: 'Room Frame', icon: Icons.panorama_horizontal, accentColor: Colors.blue),
      StoreItem(id: 'rf_2', title: 'Red Rose', price: 4000, category: 'Room Frame', icon: Icons.panorama_horizontal, accentColor: Colors.pink),
      StoreItem(id: 'rf_3', title: 'Bar', price: 4000, category: 'Room Frame', badge: 'NEW', icon: Icons.panorama_horizontal, accentColor: Colors.purple),
      StoreItem(id: 'rf_4', title: 'Gramophone', price: 4000, category: 'Room Frame', badge: 'NEW', icon: Icons.panorama_horizontal, accentColor: Colors.orange),
      StoreItem(id: 'rf_5', title: 'Purple Lover', price: 4000, category: 'Room Frame', badge: 'NEW', icon: Icons.panorama_horizontal, accentColor: Colors.purpleAccent),
      StoreItem(id: 'rf_6', title: 'Emerald Realm', price: 2000, category: 'Room Frame', badge: 'HOT', icon: Icons.panorama_horizontal, accentColor: Colors.teal),
      StoreItem(id: 'rf_7', title: 'Golden Vortex', price: 2000, category: 'Room Frame', badge: 'HOT', icon: Icons.panorama_horizontal, accentColor: Colors.amber),
      StoreItem(id: 'rf_8', title: 'Lunar Cascade', price: 2000, category: 'Room Frame', badge: 'HOT', icon: Icons.panorama_horizontal, accentColor: Colors.blueAccent),

      // 8. Profile Card
      StoreItem(id: 'pc_1', title: 'Emerald Realm', price: 7000, category: 'Profile Card', icon: Icons.credit_card, accentColor: Colors.green),
      StoreItem(id: 'pc_2', title: 'Golden Vortex', price: 7000, category: 'Profile Card', icon: Icons.credit_card, accentColor: Colors.amber),
      StoreItem(id: 'pc_3', title: 'Lunar Cascade', price: 7000, category: 'Profile Card', icon: Icons.credit_card, accentColor: Colors.blue),
      StoreItem(id: 'pc_4', title: 'Fun Suit', price: 7000, category: 'Profile Card', icon: Icons.credit_card, accentColor: Colors.orange),

      // 9. ChatBubble
      StoreItem(id: 'cb_1', title: 'Fun Faces', price: 10000, category: 'ChatBubble', icon: Icons.chat_bubble_outline, accentColor: Colors.amber),
      StoreItem(id: 'cb_2', title: 'Pink Affection', price: 10000, category: 'ChatBubble', icon: Icons.chat_bubble_outline, accentColor: Colors.pinkAccent),
      StoreItem(id: 'cb_3', title: 'Gemstone Glory', price: 14000, category: 'ChatBubble', icon: Icons.chat_bubble_outline, accentColor: Colors.orange),
      StoreItem(id: 'cb_4', title: 'Pumpkin Phantom', price: 10000, category: 'ChatBubble', icon: Icons.chat_bubble_outline, accentColor: Colors.purple),
      StoreItem(id: 'cb_5', title: 'Radiant Gold', price: 14000, category: 'ChatBubble', icon: Icons.chat_bubble_outline, accentColor: Colors.amberAccent),
      StoreItem(id: 'cb_6', title: 'Sunny Cactus', price: 7000, category: 'ChatBubble', icon: Icons.chat_bubble_outline, accentColor: Colors.green),
      StoreItem(id: 'cb_7', title: 'Tiger Glow', price: 10000, category: 'ChatBubble', icon: Icons.chat_bubble_outline, accentColor: Colors.amber),
      StoreItem(id: 'cb_8', title: 'Santa Claus Suit', price: 7000, category: 'ChatBubble', badge: 'HOT', icon: Icons.chat_bubble_outline, accentColor: Colors.redAccent),
      StoreItem(id: 'cb_9', title: 'Fun Suit', price: 7000, category: 'ChatBubble', icon: Icons.chat_bubble_outline, accentColor: Colors.red),
      StoreItem(id: 'cb_10', title: '1stAnniversary', price: 14000, category: 'ChatBubble', icon: Icons.chat_bubble_outline, accentColor: Colors.greenAccent),
    ];
  }

void _purchaseItem(StoreItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Purchase ${item.title}?', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item: ${item.title}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Price: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text('${item.price}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Your Balance: $_currentCoins Coins', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C9A7)),
            onPressed: () {
              Navigator.pop(ctx);
              if (_currentCoins >= item.price) {
                setState(() {
                  _currentCoins -= item.price;
                });
                widget.onCoinsUpdated(_currentCoins);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully purchased ${item.title}! Added to your backpack.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Insufficient Coins! Please recharge in Admin or Wallet.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCategory = categories[_selectedCategoryIndex];
    final currentItems = allStoreItems.where((i) => i.category == activeCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF00C9A7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C9A7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Store', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.backpack_outlined, color: Colors.white, size: 26),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backpack opened! Purchased items are ready.')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. ወደ ጎን የሚንሸራተት የታብ ባር (Horizontal Tab Bar)
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,

padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        categories[index],
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF00C9A7) : Colors.white.withOpacity(0.9),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. ወደ ታች እና ወደ ላይ የሚንቀሳቀስ የእቃዎች ግሪድ (Vertical Scrolling Grid)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF7FBFB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: currentItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final item = currentItems[index];
                    return _buildStoreCard(item);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(StoreItem item) {
    return GestureDetector(
      onTap: () => _purchaseItem(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ካርዱ ውስጥ ያለው ይዘት
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // እቃው የሚታይበት ዲዛይን (ስፔሻል አይዲ ወይም ምስል)
                  if (item.category == 'Special ID')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [item.accentColor, const Color(0xFF5D5FEF)],

),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: item.accentColor.withOpacity(0.3), blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.diamond, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            item.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: item.accentColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, size: 38, color: item.accentColor),
                    ),
                  const Spacer(),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        '${item.price}',
                        style: const TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ባጅ (HOT ወይም NEW)
            if (item.badge != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.badge == 'HOT' ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.badge!,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
