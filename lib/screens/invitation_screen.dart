import 'package:flutter/material.dart';

class InvitationScreen extends StatefulWidget {
  const InvitationScreen({super.key});

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      // 1. የላይኛው ራስጌ
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Hala Center",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        // 2. 3ቱ ታቦች (In Progress, Upcoming, Ended)
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.black45,
          indicatorColor: const Color(0xFF00C9A7),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: "In Progress"),
            Tab(text: "Upcoming"),
            Tab(text: "Ended"),
          ],
        ),
      ),
      body: Column(
        children: [
          // 3. የመሃል ካርድ ቦታ (ታቦቹ ሲነኩ የሚቀያየሩበት ቦታ)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCardPlaceholder("In Progress"),
                _buildCardPlaceholder("Upcoming"),
                _buildCardPlaceholder("Ended"),
              ],
            ),
          ),

          // 4. የታችኛው የመጋበዣ ቦታ (Bottom Area Placeholder)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // የኮድ ማሳያ እና የኮፒ ማድረጊያ ቦታ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Invitation Code:",
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(width: 8),
                        // ለወደፊት ኮድ የሚቀመጥበት ክፍት ቦታ
                        Container(
                          width: 80,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Copy ቁልፍ ቦታ
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),

decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF00C9A7)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Copy",
                            style: TextStyle(
                              color: Color(0xFF00C9A7),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ዋናው ትልቁ Invitation ቁልፍ
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB800),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "Invitation",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // የመሃል ይዘቶች የሚቀመጡበት ካርድ
  Widget _buildCardPlaceholder(String title) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$title Activities",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "permanently",
              style: TextStyle(fontSize: 12, color: Colors.black38),
            ),
            const SizedBox(height: 14),

            // ባነር የሚቀመጥበት ባዶ ቦታ
            Container(
              height: 125,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5252), Color(0xFFFF7A00)],
                ),
              ),
              child: const Center(
                child: Icon(Icons.card_giftcard, color: Colors.white, size: 44),
              ),
            ),

            const SizedBox(height: 16),

            // Join Now ቁልፍ
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C9A7),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),

),
                ),
                onPressed: () {},
                child: const Text(
                  "Join Now",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
