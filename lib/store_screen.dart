import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/user_service.dart';

class StoreItem {
  final String id;
  final String name;
  final String category; // 'Popular', 'Frame', 'Entry', 'Special ID', 'Theme'
  final int price;
  final String imageUrl;
  final String badge; // 'HOT', 'NEW', or ''
  final Color? glowColor;

  StoreItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.badge = '',
    this.glowColor,
  });
}

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  final UserService _user = UserService();
  late TabController _tabController;

  final List<String> _tabs = ['Popular', 'Frame', 'Entry', 'Special ID', 'Theme'];

  late List<StoreItem> _allItems;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _initStoreData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initStoreData() {
    _allItems = [
      // 1. POPULAR / HOT
      StoreItem(
        id: 'p1',
        name: 'Galaxy Halo',
        category: 'Popular',
        price: 99999,
        imageUrl: 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=300&q=80',
        badge: 'HOT',
        glowColor: Colors.blueAccent,
      ),
      StoreItem(
        id: 'p2',
        name: 'Gilded Supercar',
        category: 'Popular',
        price: 999999,
        imageUrl: 'https://images.unsplash.com/photo-1544829099-b9a0c07fad1a?w=300&q=80',
        badge: 'HOT',
        glowColor: Colors.amberAccent,
      ),
      StoreItem(
        id: 'p3',
        name: 'ID 1166',
        category: 'Popular',
        price: 800000,
        imageUrl: '1166',
        badge: 'HOT',
        glowColor: Colors.purpleAccent,
      ),
      StoreItem(
        id: 'p4',
        name: 'Sunset Comet',
        category: 'Popular',
        price: 4200,
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=300&q=80',
        badge: 'HOT',
        glowColor: Colors.deepOrangeAccent,
      ),

      // 2. FRAMES
      StoreItem(
        id: 'f1',
        name: 'Galaxy Halo',
        category: 'Frame',
        price: 99999,
        imageUrl: 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=300&q=80',
        badge: 'HOT',
        glowColor: Colors.cyanAccent,
      ),
      StoreItem(
        id: 'f2',
        name: 'Summer Love',
        category: 'Frame',
        price: 99999,
        imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=300&q=80',
        badge: 'NEW',
        glowColor: Colors.pinkAccent,
      ),
      StoreItem(
        id: 'f3',
        name: 'Golden Glow',
        category: 'Frame',
        price: 99999,
        imageUrl: 'https://images.unsplash.com/photo-1533158307587-828f0a76ef96?w=300&q=80',
        badge: 'HOT',
        glowColor: Colors.amber,
      ),
      StoreItem(
        id: 'f4',
        name: 'Frostlight Stag',
        category: 'Frame',
        price: 99999,
        imageUrl: 'https://images.unsplash.com/photo-1518895949257-7621c3c786d7?w=300&q=80',
        badge: 'HOT',
        glowColor: Colors.lightBlueAccent,
      ),
      StoreItem(
        id: 'f5',
        name: 'Tomato Toss',
        category: 'Frame',
        price: 199999,
        imageUrl: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=300&q=80',
        badge: 'HOT',
        glowColor: Colors.redAccent,
      ),
      StoreItem(

id: 'f6',
        name: 'Mecha Spirit',
        category: 'Frame',
        price: 299999,
        imageUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=300&q=80',
        badge: 'NEW',
        glowColor: Colors.purpleAccent,
      ),
      StoreItem(
        id: 'f7',
        name: 'Blaze Ring',
        category: 'Frame',
        price: 299999,
        imageUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=300&q=80',
        badge: 'HOT',
        glowColor: Colors.orangeAccent,
      ),
      StoreItem(
        id: 'f8',
        name: 'Star of Fortune',
        category: 'Frame',
        price: 30000,
        imageUrl: 'https://images.unsplash.com/photo-1519751138087-5bf79df62d5b?w=300&q=80',
        badge: 'NEW',
        glowColor: Colors.tealAccent,
      ),

      // 3. ENTRY (Vehicles & Beasts)
      StoreItem(
        id: 'e1',
        name: 'Violet Phantom',
        category: 'Entry',
        price: 99999,
        imageUrl: 'https://images.unsplash.com/photo-1617814076367-b759c7d7e738?w=300&q=80',
        badge: 'HOT',
        glowColor: Colors.purpleAccent,
      ),
      StoreItem(
        id: 'e2',
        name: 'Golden Bike',
        category: 'Entry',
        price: 99999,
        imageUrl: 'https://images.unsplash.com/photo-1485965120184-e220f721d03e?w=300&q=80',
        badge: '',
        glowColor: Colors.amber,
      ),
      StoreItem(
        id: 'e3',
        name: 'Cyber Lion',
        category: 'Entry',
        price: 999999,
        imageUrl: 'https://images.unsplash.com/photo-1534188753412-3e26d0d618d6?w=300&q=80',
        badge: 'HOT',
        glowColor: Colors.cyanAccent,
      ),
      StoreItem(
        id: 'e4',
        name: 'Gilded Supercar',
        category: 'Entry',
        price: 999999,
        imageUrl: 'https://images.unsplash.com/photo-1544829099-b9a0c07fad1a?w=300&q=80',
        badge: 'HOT',
        glowColor: Colors.amberAccent,
      ),
      StoreItem(
        id: 'e5',
        name: 'Flame Racer',
        category: 'Entry',
        price: 9999999,
        imageUrl: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=300&q=80',
        badge: 'HOT',
        glowColor: Colors.redAccent,
      ),
      StoreItem(
        id: 'e6',
        name: 'Obsidian Jet',
        category: 'Entry',
        price: 9999999,
        imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=300&q=80',
        badge: 'NEW',
        glowColor: Colors.blueAccent,
      ),
      StoreItem(
        id: 'e7',
        name: 'Dragon-Kirin Gold',
        category: 'Entry',
        price: 450000,
        imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=300&q=80',
        badge: 'HOT',
        glowColor: Colors.amber,
      ),

      // 4. SPECIAL ID
      StoreItem(
        id: 's1',
        name: '1166',
        category: 'Special ID',
        price: 800000,
        imageUrl: '1166',
        badge: 'HOT',
        glowColor: Colors.purpleAccent,
      ),
      StoreItem(
        id: 's2',
        name: '1177',
        category: 'Special ID',
        price: 800000,
        imageUrl: '1177',
        badge: 'HOT',
        glowColor: Colors.purpleAccent,
      ),
      StoreItem(
        id: 's3',
        name: '1149',
        category: 'Special ID',
        price: 800000,
        imageUrl: '1149',
        badge: '',
        glowColor: Colors.blueAccent,
      ),
      StoreItem(
        id: 's4',
        name: '1138',
        category: 'Special ID',
        price: 800000,
        imageUrl: '1138',
        badge: '',
        glowColor: Colors.blueAccent,
      ),
      StoreItem(
        id: 's5',
        name: '5201',
        category: 'Special ID',
        price: 800000,
        imageUrl: '5201',
        badge: 'HOT',
        glowColor: Colors.amberAccent,
      ),
      StoreItem(
        id: 's6',
        name: '9876',
        category: 'Special ID',
        price: 800000,
        imageUrl: '9876',
        badge: 'HOT',
        glowColor: Colors.tealAccent,
      ),

// 5. THEME (Room Backgrounds)
      StoreItem(
        id: 't1',
        name: 'Cherry Blossom',
        category: 'Theme',
        price: 4200,
        imageUrl: 'https://images.unsplash.com/photo-1522383225653-ed111181a951?w=300&q=80',
        badge: 'HOT',
        glowColor: Colors.pinkAccent,
      ),
      StoreItem(
        id: 't2',
        name: 'Comet Sunset',
        category: 'Theme',
        price: 4200,
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=300&q=80',
        badge: 'HOT',
        glowColor: Colors.deepOrangeAccent,
      ),
      StoreItem(
        id: 't3',
        name: 'Fireworks Galaxy',
        category: 'Theme',
        price: 4200,
        imageUrl: 'https://images.unsplash.com/photo-1498931299472-f7a63a5a1cfa?w=300&q=80',
        badge: 'NEW',
        glowColor: Colors.purpleAccent,
      ),
      StoreItem(
        id: 't4',
        name: 'Snowy Night',
        category: 'Theme',
        price: 4200,
        imageUrl: 'https://images.unsplash.com/photo-1517299321909-50939c812a42?w=300&q=80',
        badge: '',
        glowColor: Colors.cyanAccent,
      ),
      StoreItem(
        id: 't5',
        name: 'Star Voyage',
        category: 'Theme',
        price: 8000,
        imageUrl: 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?w=300&q=80',
        badge: 'HOT',
        glowColor: Colors.blueAccent,
      ),
      StoreItem(
        id: 't6',
        name: 'Solar Stag',
        category: 'Theme',
        price: 8000,
        imageUrl: 'https://images.unsplash.com/photo-1518895949257-7621c3c786d7?w=300&q=80',
        badge: 'HOT',
        glowColor: Colors.amberAccent,
      ),
    ];
  }

  void _buyItem(StoreItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Purchase ${item.name}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black38,
                border: Border.all(color: item.glowColor ?? Colors.amber, width: 2),
              ),
              child: item.category == 'Special ID'
                  ? Center(
                      child: Text(
                        '💎 ${item.imageUrl}',
                        style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(item.imageUrl, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              'Price: ${item.price} Coins',
              style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Balance: ${_user.coins} Coins',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF904BE6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

),
            onPressed: () async {
              if (_user.coins < item.price) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Insufficient coins! Please recharge first.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              setState(() {
                _user.coins -= item.price;
              });

              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully purchased ${item.name}! Added to Backpack.'),
                  backgroundColor: const Color(0xFF00C9A7),
                ),
              );
            },
            child: const Text('Confirm Buy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0C1D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Store', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_user.coins}',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF904BE6),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Luxury Floating VIP Entry Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C1E57), Color(0xFF6C3483)],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF904BE6).withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(

gradient: const LinearGradient(colors: [Colors.amber, Colors.orangeAccent]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('VIP 6', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '👑 Golden Phoenix entered the room',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.stars, color: Colors.amberAccent, size: 18),
              ],
            ),
          ),

          // Items Grid View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final list = _allItems.where((i) => i.category == tab).toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.84,
                  ),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return GestureDetector(
                      onTap: () => _buyItem(item),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF17162E),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: item.glowColor?.withOpacity(0.3) ?? Colors.white12,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: item.glowColor?.withOpacity(0.12) ?? Colors.black26,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Main content
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: item.category == 'Special ID'
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFF3A1C71), Color(0xFFD76D77)],
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.purpleAccent.withOpacity(0.4),
                                                    blurRadius: 8,

),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.diamond, color: Colors.cyanAccent, size: 16),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    item.imageUrl,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                shape: item.category == 'Frame' ? BoxShape.circle : BoxShape.rectangle,
                                                borderRadius: item.category != 'Frame' ? BorderRadius.circular(12) : null,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: item.glowColor?.withOpacity(0.35) ?? Colors.transparent,
                                                    blurRadius: 16,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(item.category == 'Frame' ? 100 : 12),
                                                child: Image.network(
                                                  item.imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: 86,
                                                  height: 86,
                                                  errorBuilder: (_, , _) => const Icon(Icons.stars, color: Colors.amber, size: 50),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.monetization_on, color: Colors.amber, size: 14),

const SizedBox(width: 4),
                                      Text(
                                        '${item.price}',
                                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Badge
                            if (item.badge.isNotEmpty)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: item.badge == 'HOT' ? Colors.redAccent : Colors.greenAccent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.badge,
                                    style: TextStyle(
                                      color: item.badge == 'HOT' ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
