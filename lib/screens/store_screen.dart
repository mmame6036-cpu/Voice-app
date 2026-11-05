KEDER:
import 'package:flutter/material.dart';

class StoreItem {
  final String id;
  final String name;
  final String category;
  final String icon;
  final int price;

  const StoreItem({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.price,
  });
}

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  int _selectedCategoryIndex = 0;

  final List<String> _categories = const [
    'All',
    'Badges',
    'Rockets',
    'Gifts',
  ];

  final List<StoreItem> _allItems = const [
    StoreItem(id: '1', name: 'Lollipop', category: 'Gifts', icon: '🍭', price: 5),
    StoreItem(id: '2', name: 'Rose', category: 'Gifts', icon: '🌹', price: 10),
    StoreItem(id: '3', name: 'Diamond', category: 'Gifts', icon: '💎', price: 1000),
    StoreItem(id: '4', name: 'Rocket Lv1', category: 'Rockets', icon: '🚀', price: 2000),
    StoreItem(id: '5', name: 'Charm Badge', category: 'Badges', icon: '🏅', price: 500),
    StoreItem(id: '6', name: 'Wealth Badge', category: 'Badges', icon: '👑', price: 1500),
  ];

  List<StoreItem> get _filteredItems {
    if (_selectedCategoryIndex == 0) {
      return _allItems;
    }
    final category = _categories[_selectedCategoryIndex];
    return _allItems.where((item) => item.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171524),
      appBar: AppBar(
        title: const Text('Store', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: ChoiceChip(
                    label: Text(_categories[index]),
                    selected: isSelected,
                    selectedColor: const Color(0xFFFFD700),
                    backgroundColor: const Color(0xFF1E1B2E),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategoryIndex = index);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,

children: [
                      Text(item.icon, style: const TextStyle(fontSize: 36)),
                      const SizedBox(height: 8),
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '🪙 ${item.price}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
