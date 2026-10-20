import 'package:flutter/material.dart';
import 'services/user_service.dart';

class BackpackItem {
  final String id;
  final String name;
  final String category; // 'Frame', 'Vehicle', 'Card', 'Bubble'
  final IconData icon;
  final Color accentColor;
  final int daysRemaining;
  bool isEquipped;

  BackpackItem({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.accentColor,
    required this.daysRemaining,
    this.isEquipped = false,
  });
}

class BackpackScreen extends StatefulWidget {
  const BackpackScreen({Key? key}) : super(key: key);

  @override
  State<BackpackScreen> createState() => _BackpackScreenState();
}

class _BackpackScreenState extends State<BackpackScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  late TabController _tabController;

  final List<String> _tabs = ['All', 'Frames', 'Vehicles', 'Cards', 'Bubbles'];

  // Default User Inventory
  final List<BackpackItem> _myItems = [
    BackpackItem(
      id: 'frame_1',
      name: 'Star of Fortune',
      category: 'Frames',
      icon: Icons.stars,
      accentColor: Colors.purpleAccent,
      daysRemaining: 28,
      isEquipped: true,
    ),
    BackpackItem(
      id: 'frame_3',
      name: 'Metropolis Lord',
      category: 'Frames',
      icon: Icons.brightness_high,
      accentColor: Colors.amber,
      daysRemaining: 14,
      isEquipped: false,
    ),
    BackpackItem(
      id: 'ent_1',
      name: 'Shark Moto',
      category: 'Vehicles',
      icon: Icons.two_wheeler,
      accentColor: Colors.purple,
      daysRemaining: 30,
      isEquipped: true,
    ),
    BackpackItem(
      id: 'ent_6',
      name: 'Spaceship',
      category: 'Vehicles',
      icon: Icons.rocket_launch,
      accentColor: Colors.deepOrangeAccent,
      daysRemaining: 7,
      isEquipped: false,
    ),
    BackpackItem(
      id: 'rc_1',
      name: 'Emerald Room Card',
      category: 'Cards',
      icon: Icons.crop_portrait,
      accentColor: Colors.green,
      daysRemaining: 15,
      isEquipped: false,
    ),
    BackpackItem(
      id: 'cb_1',
      name: 'Fun Faces Bubble',
      category: 'Bubbles',
      icon: Icons.chat_bubble_outline,
      accentColor: Colors.amber,
      daysRemaining: 21,
      isEquipped: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleEquipItem(BackpackItem item) {
    setState(() {
      if (item.isEquipped) {
        item.isEquipped = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unequipped ${item.name}'),
            backgroundColor: Colors.white24,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Unequip others in the same category
        for (var other in _myItems) {
          if (other.category == item.category && other.id != item.id) {
            other.isEquipped = false;
          }
        }
        item.isEquipped = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Equipped ${item.name}!'),
            backgroundColor: const Color(0xFF00C9A7),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D101D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131728),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),

onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Backpack',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF00C9A7),
          labelColor: const Color(0xFF00C9A7),
          unselectedLabelColor: Colors.white54,
          indicatorWeight: 3,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) => _buildInventoryGrid(tab)).toList(),
      ),
    );
  }

  Widget _buildInventoryGrid(String category) {
    final filtered = category == 'All'
        ? _myItems
        : _myItems.where((i) => i.category == category).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inventory_2_outlined, color: Colors.white24, size: 64),
            SizedBox(height: 12),
            Text(
              'No items in this category',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(BackpackItem item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isEquipped ? const Color(0xFF00C9A7) : Colors.white10,
          width: item.isEquipped ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: item.accentColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, size: 34, color: item.accentColor),
                ),
                const SizedBox(height: 10),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.daysRemaining} days left',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.isEquipped ? Colors.white12 : const Color(0xFF00C9A7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.zero,

),
                    onPressed: () => _toggleEquipItem(item),
                    child: Text(
                      item.isEquipped ? 'In Use' : 'Equip',
                      style: TextStyle(
                        color: item.isEquipped ? Colors.white70 : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (item.isEquipped)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C9A7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
