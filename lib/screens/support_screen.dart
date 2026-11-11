import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  int _selectedCategoryIndex = 0;
  bool _isSubmitting = false;

  final List<String> _issueCategories = const [
    "Recharge Issue",
    "Account / Security",
    "Room & Voice",
    "Report User",
    "Other Feedback",
  ];

  static const Color bgColor = Color(0xFFF5EFEB);
  static const Color cardBg = Colors.white;
  static const Color primaryBrown = Color(0xFF3E2723);
  static const Color accentGold = Color(0xFFD49B42);
  static const Color borderColor = Color(0xFFE2D6C5);
  static const Color buttonDark = Color(0xFF4A3528);

  @override
  void dispose() {
    _detailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryBrown,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitTicket() async {
    final detailText = _detailController.text.trim();
    if (detailText.isEmpty) {
      _showToast("Please describe your issue before submitting.");
      return;
    }

    if (_currentUser == null) {
      _showToast("Please log in to submit a ticket.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final String userName = userData['name'] ?? userData['displayName'] ?? "User";
      final String userNumericId = (userData['numericId'] ?? userData['id'] ?? "Unknown").toString();

      await FirebaseFirestore.instance.collection('support_tickets').add({
        'uid': _currentUser!.uid,
        'userName': userName,
        'userNumericId': userNumericId,
        'category': _issueCategories[_selectedCategoryIndex],
        'detail': detailText,
        'contactInfo': _contactController.text.trim(),
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _detailController.clear();
      _contactController.clear();
      _showToast("Ticket submitted successfully. We will review it shortly.");
    } catch (e) {
      _showToast("Failed to submit ticket: $e");
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showTicketHistory() {
    if (_currentUser == null) {
      _showToast("Please log in first.");
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,

height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Ticket History",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryBrown,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('support_tickets')
                    .where('uid', isEqualTo: _currentUser!.uid)
                    .orderBy('createdAt', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No tickets submitted yet.",
                        style: TextStyle(color: Colors.black45, fontSize: 13),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, idx) {
                      final data = snapshot.data!.docs[idx].data() as Map<String, dynamic>;
                      final category = data['category'] ?? "General";
                      final detail = data['detail'] ?? "";
                      final status = data['status'] ?? "pending";

                      final bool isResolved = status == "resolved";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  category,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: primaryBrown,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isResolved
                                        ? const Color(0xFF107C41)
                                        : accentGold,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.toString().toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              detail,
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFaqDetail(String question, String answer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          question,
          style: const TextStyle(color: primaryBrown, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: Text(
          answer,
          style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Got It", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryBrown, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Customer Service & Help",
          style: TextStyle(
            color: primaryBrown,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: primaryBrown),
            onPressed: _showTicketHistory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Live Support Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A3528), Color(0xFF6D5446)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
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
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),

const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          "Instant ticket resolution with staff",
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentGold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      elevation: 0,
                    ),
                    onPressed: () => _showToast("Customer care staff notified."),
                    child: const Text(
                      "Chat Now",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // 2. FAQ Section
            const Text(
              "Frequently Asked Questions",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: primaryBrown,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _buildFaqItem(
                    "Recharge delayed? How to recover coins?",
                    "If your coins do not arrive within 5 minutes, please copy your Transaction Reference ID and submit a ticket under Recharge Issue.",
                  ),
                  const Divider(height: 1, color: Color(0xFFEFE6DE)),
                  _buildFaqItem(
                    "How to become an official host or agent?",
                    "Navigate to Host Center or join an active Agency ID. You can also contact support directly via Telegram or WhatsApp.",
                  ),
                  const Divider(height: 1, color: Color(0xFFEFE6DE)),
                  _buildFaqItem(
                    "Voice stutter or microphone permissions guide",
                    "Ensure microphone permission is granted in OS settings. If audio lags, switch to a stable Wi-Fi or 4G/5G connection.",
                  ),
                  const Divider(height: 1, color: Color(0xFFEFE6DE)),
                  _buildFaqItem(
                    "Community safety and rules violation policy",
                    "Harmful content, harassment, and fraudulent recharge operations result in permanent device and account suspension.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // 3. Feedback Ticket Form
            const Text(
              "Submit a Ticket / Report",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: primaryBrown,
              ),
            ),
            const SizedBox(height: 10),

// Category selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(_issueCategories.length, (idx) {
                  final isSelected = _selectedCategoryIndex == idx;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryIndex = idx),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? buttonDark : cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? buttonDark : borderColor,
                        ),
                      ),
                      child: Text(
                        _issueCategories[idx],
                        style: TextStyle(
                          color: isSelected ? Colors.white : primaryBrown,
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

            // Detail input box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _detailController,
                maxLines: 4,
                style: const TextStyle(color: primaryBrown),
                decoration: const InputDecoration(
                  hintText: "Describe your issue in detail (e.g. Transaction ID, Room ID)...",
                  hintStyle: TextStyle(color: Colors.black38, fontSize: 12.5),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Optional contact info input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _contactController,
                style: const TextStyle(color: primaryBrown),
                decoration: const InputDecoration(
                  hintText: "Contact Phone / Telegram ID (Optional)",
                  hintStyle: TextStyle(color: Colors.black38, fontSize: 12),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF107C41),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _isSubmitting ? null : _submitTicket,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,

child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        "Submit Ticket",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // 4. Social Quick Channels
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialSupportItem(Icons.send, "Telegram", Colors.lightBlue),
                const SizedBox(width: 28),
                _buildSocialSupportItem(Icons.chat, "WhatsApp", Colors.green),
                const SizedBox(width: 28),
                _buildSocialSupportItem(Icons.email_outlined, "Email", Colors.deepOrangeAccent),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ListTile(
      dense: true,
      title: Text(
        question,
        style: const TextStyle(fontSize: 12.5, color: primaryBrown, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black38),
      onTap: () => _showFaqDetail(question, answer),
    );
  }

  Widget _buildSocialSupportItem(IconData icon, String name, Color color) {
    return GestureDetector(
      onTap: () => _showToast("Connecting to official $name channel..."),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
