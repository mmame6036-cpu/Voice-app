import 'package:flutter/material.dart';

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _badgeCategories = [
    "Achievement",
    "Wealth",
    "Activity",
    "Honor",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _badgeCategories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141226),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B38),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Medals & Badges",
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. የባጅ ማጠቃለያ ባነር (Summary Header)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C224D), Color(0xFF1E1B38)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.military_tech, color: Color(0xFFFFD700), size: 30),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "My Badges Collection",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Unlocked: 0 / 16",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. የምድብ ታቦች (TabBar)
          Container(
            color: const Color(0xFF1E1B38),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFFFD700),
              indicatorWeight: 3,
              labelColor: const Color(0xFFFFD700),
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: _badgeCategories.map((cat) => Tab(text: cat)).toList(),
            ),
          ),

          // 3. የባጆች ማስቀመጫ ሰንጠረዥ (Grid Placeholder)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _badgeCategories.map((cat) => _buildBadgeGrid(cat)).toList(),
            ),
          ),
        ],
      ),
    );
  }

// የእያንዳንዱ ምድብ የባጅ ካርዶች ሰንጠረዥ
  Widget _buildBadgeGrid(String categoryName) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6, // በእያንዳንዱ ምድብ ስር ያሉ ባዶ የባጅ ቦታዎች
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, idx) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B38),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // የባጅ ምልክት ቦታ (መቆለፊያ ያለበት)
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield,
                      color: Colors.white24,
                      size: 34,
                    ),
                  ),
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: Icon(Icons.lock, color: Colors.white38, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // የባጁ ስም
              Text(
                "$categoryName #${idx + 1}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // መመሪያ
              const Text(
                "Condition locked",
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
              const SizedBox(height: 10),

              // የመልበሻ / ሁኔታ ቁልፍ ቦታ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Locked",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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
