import 'package:flutter/material.dart';

class StoreScreen extends StatefulWidget {
  final int userCoins;
  final Function(int) onCoinsDeducted;

  const StoreScreen({
    super.key,
    required this.userCoins,
    required this.onCoinsDeducted,
  });

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  // የተመረጠው ምድብ መለያ (Default: Popular)
  int _selectedCategoryIndex = 0;

  // 8ቱ ዋና ዋና ምድቦች
  final List> _categories = [
    {"name": "Popular", "icon": Icons.local_fire_department, "color": Colors.orangeAccent},
    {"name": "Frame", "icon": Icons.motion_photos_on, "color": const Color(0xFF00C9A7)},
    {"name": "Entry", "icon": Icons.rocket_launch, "color": Colors.redAccent},
    {"name": "Special ID", "icon": Icons.badge, "color": Colors.amber},
    {"name": "Theme", "icon": Icons.wallpaper, "color": Colors.purpleAccent},
    {"name": "Room Card", "icon": Icons.credit_card, "color": Colors.deepPurpleAccent},
    {"name": "Room Frame", "icon": Icons.palette, "color": Colors.blueAccent},
    {"name": "Profile Card", "icon": Icons.style, "color": Colors.teal},
  ];

  @override
  Widget build(BuildContext context) {
    final currentCategory = _categories[_selectedCategoryIndex]["name"] as String;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C9A7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Store",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Backpack")),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. የላይኛው የ 8ቱ ምድቦች መምረጫ ሳጥን (Header Container)
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 6,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                final isSelected = _selectedCategoryIndex == idx;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = idx;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(

color: (cat["color"] as Color).withOpacity(isSelected ? 0.25 : 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF00C9A7) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          cat["icon"] as IconData,
                          color: cat["color"] as Color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat["name"] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF00C9A7) : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 2. የተመረጠው ምድብ ርዕስ ባነር
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentCategory,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "Total items: 0",
                  style: const TextStyle(fontSize: 12, color: Colors.black38),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 3. ከስር እቃዎቹ የሚጫኑበት ዝግጁ ባዶ ቦታ (Functional Empty Body Placeholder)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12, style: BorderStyle.solid),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _categories[_selectedCategoryIndex]["icon"] as IconData,
                      size: 56,
                      color: (_categories[_selectedCategoryIndex]["color"] as Color).withOpacity(0.5),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "$currentCategory Section",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "ምንም እቃ አልተጫነም፤ እቃዎችን ለመጫን ዝግጁ ነው።",
                      style: const TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
