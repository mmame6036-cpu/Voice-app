import 'package:flutter/material.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  // የተመረጠው የችግር አይነት
  int _selectedCategoryIndex = 0;
  final List<String> _issueCategories = [
    "Recharge Issue",
    "Account / Security",
    "Room & Voice",
    "Report User",
    "Other Feedback",
  ];

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
          "Customer Service & Help",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. የቀጥታ ቻት ባነር (Live Support Banner)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C9A7), Color(0xFF00BFA5)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C9A7).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Online Support 24/7",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Instant chat with official customer service",
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Chat Now",
                      style: TextStyle(
                        color: Color(0xFF00C9A7),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

// 2. ተደጋግመው የሚጠየቁ ጥያቄዎች (FAQ Section)
            const Text(
              "Frequently Asked Questions",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                children: [
                  _buildFaqItem("Recharge delayed? How to recover coins?"),
                  const Divider(height: 1, color: Colors.black12),
                  _buildFaqItem("How to become an official host or agent?"),
                  const Divider(height: 1, color: Colors.black12),
                  _buildFaqItem("Voice stutter or microphone permissions guide"),
                  const Divider(height: 1, color: Colors.black12),
                  _buildFaqItem("Community safety and rules violation policy"),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. የቅሬታ ማቅረቢያ ቅጽ (Feedback Ticket Form)
            const Text(
              "Submit a Ticket / Report",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            // የምድብ መምረጫ
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_issueCategories.length, (idx) {
                  final isSelected = _selectedCategoryIndex == idx;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryIndex = idx),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00C9A7) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00C9A7) : Colors.black12,
                        ),
                      ),
                      child: Text(
                        _issueCategories[idx],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 14),

            // የጽሁፍ ማስገቢያ ሳጥን
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: const TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Describe your problem in detail (e.g. Transaction ID, Room ID)...",
                  hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 14),

// የስክሪንሾት ማያያዣ ቦታ (Upload Screenshot Placeholder)
            Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12, style: BorderStyle.solid),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: Colors.black38, size: 24),
                      SizedBox(height: 4),
                      Text("Upload", style: TextStyle(color: Colors.black38, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Attach screenshots or payment proofs (Max 3 images)",
                    style: TextStyle(color: Colors.black45, fontSize: 11),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ማቅረቢያ ቁልፍ (Submit Button)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C9A7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                onPressed: () {},
                child: const Text(
                  "Submit Ticket",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 4. ማህበራዊ አቋራጮች (Telegram & WhatsApp Support)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialSupportItem(Icons.send, "Telegram", Colors.lightBlue),
                const SizedBox(width: 24),
                _buildSocialSupportItem(Icons.chat, "WhatsApp", Colors.green),
                const SizedBox(width: 24),
                _buildSocialSupportItem(Icons.email_outlined, "Email", Colors.orangeAccent),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question) {
    return ListTile(
      dense: true,
      title: Text(
        question,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black38),
      onTap: () {},
    );
  }

  Widget _buildSocialSupportItem(IconData icon, String name, Color color) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}
