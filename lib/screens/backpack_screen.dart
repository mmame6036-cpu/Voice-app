import 'package:flutter/material.dart';

class BackpackScreen extends StatefulWidget {
  const BackpackScreen({super.key});

  @override
  State<BackpackScreen> createState() => _BackpackScreenState();
}

class _BackpackScreenState extends State<BackpackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    "Frame",
    "Entry",
    "Theme",
    "Special ID",
    "Props",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Backpack",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF00C9A7),
          unselectedLabelColor: Colors.black45,
          indicatorColor: const Color(0xFF00C9A7),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) => _buildCategorySpace(tab)).toList(),
      ),
    );
  }

  // የእቃዎቹ ማስቀመጫ ባዶ ቦታ (Placeholder)
  Widget _buildCategorySpace(String categoryName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // እቃ በሚኖርበት ጊዜ የሚቀመጥበት የናሙና ካርድ ቦታ
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                // የእቃው ፎቶ ማስቀመጫ
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C9A7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.inventory_2_outlined, color: Color(0xFF00C9A7), size: 28),
                  ),
                ),
                const SizedBox(width: 14),
                // የእቃው ዝርዝር መረጃ ቦታ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$categoryName Item Slot",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Validity: 30 Days",
                        style: TextStyle(color: Colors.black45, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // የ Use / Wear ቁልፍ ቦታ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),

decoration: BoxDecoration(
                    color: const Color(0xFF00C9A7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    "Wear",
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // ባዶ ሲሆን የሚታይ ምልክት (Empty State)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.backpack_outlined,
                  size: 64,
                  color: Colors.black.withOpacity(0.15),
                ),
                const SizedBox(height: 12),
                Text(
                  "No $categoryName items available",
                  style: const TextStyle(color: Colors.black38, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
