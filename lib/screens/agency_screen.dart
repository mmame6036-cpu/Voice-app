import 'package:flutter/material.dart';

class AgencyScreen extends StatelessWidget {
  const AgencyScreen({super.key});

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
          "Agency Center",
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. የኤጀንሲው ማጠቃለያ እና የኮሚሽን ካርድ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C224D), Color(0xFF1E1B38)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.domain, color: Color(0xFFFFD700), size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "My Agency",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "ID: 10001 (Lv.1 Agency)",
                                style: TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C9A7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          "Settlement",
                          style: TextStyle(

color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildRevenueItem("Agency Commission", "0 USDT", const Color(0xFF00C9A7)),
                      _buildRevenueItem("Total Group Diamonds", "0", const Color(0xFFFFD700)),
                      _buildRevenueItem("Active Hosts", "0", Colors.purpleAccent),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. ፈጣን የአስተዳደር አቋራጮች (Agency Quick Actions)
            Row(
              children: [
                _buildQuickAction(Icons.person_add, "Invite Host", const Color(0xFF00C9A7)),
                const SizedBox(width: 10),
                _buildQuickAction(Icons.how_to_reg, "Requests (0)", Colors.orangeAccent),
                const SizedBox(width: 10),
                _buildQuickAction(Icons.campaign, "Notice", Colors.blueAccent),
                const SizedBox(width: 10),
                _buildQuickAction(Icons.insights, "Analytics", Colors.pinkAccent),
              ],
            ),

            const SizedBox(height: 24),

            // 3. የሆስቶች ዝርዝር ርዕስ (Hosts Management Section)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Agency Hosts List",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Filter >",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // የሆስቶች ዝርዝር ማስቀመጫ ካርዶች (Host Cards Placeholder)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3, // የናሙና 3 ክፍት ካርዶች
              itemBuilder: (context, idx) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B38),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      // አቫታር እና የሁኔታ መብራት
                      Stack(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.person, color: Colors.white54, size: 28),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(

color: idx == 0 ? const Color(0xFF00C9A7) : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF1E1B38), width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // የሆስቱ መረጃ
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Host Slot ${idx + 1}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "ID: 2000${idx + 1} • Duration: 0h • Diamonds: 0",
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ),

                      // መቆጣጠሪያ ቁልፍ
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "Manage",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String title, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B38),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
