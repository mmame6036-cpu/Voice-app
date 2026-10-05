import 'package:flutter/material.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String selectedCategory = 'Common Questions';

  // የእያንዳንዱ ምድብ ጥያቄዎችና መልሶች ዳታ
  final Map<String, List<Map<String, String>>> faqData = {
    'Common Questions': [
      {'q': 'How to protect account security?', 'a': 'Never share your password or verification codes with anyone.'},
      {'q': 'How to level up quickly?', 'a': 'Recharge coins, send gifts, and stay active in voice rooms to increase your level.'},
      {'q': 'How to report inappropriate content?', 'a': 'Tap on the user profile or room settings and select Report.'},
    ],
    'Account & Security': [
      {'q': 'How to edit your profile', 'a': 'Go to your profile page, click edit profile to change your nickname, avatar, or bio.'},
      {'q': 'How to change your email', 'a': 'Navigate to Settings > Account & Security > Email to update your linked address.'},
      {'q': 'How to change your login password', 'a': 'Go to Settings > Account & Security > Password and follow the verification process.'},
      {'q': 'How to change your security password', 'a': 'Access the wallet security settings to change or reset your transaction PIN.'},
    ],
    'Host-related': [
      {'q': 'How to get verified as a host', 'a': 'Apply through an agency or achieve the required followers and live duration.'},
      {'q': 'Difference in earnings between new and old hosts', 'a': 'Senior hosts enjoy higher hourly rates and extra reward tiers based on monthly performance.'},
      {'q': 'What is the gift commission?', 'a': 'Hosts receive a standard point conversion rate for every gift received during live broadcasts.'},
      {'q': 'What is the use of TCoins?', 'a': 'TCoins can be converted into your withdrawal wallet or used within the platform.'},
      {'q': 'How to get TCoins?', 'a': 'Receive gifts from supporters or complete special live-streaming event tasks.'},
    ],
    'Agency & Agent': [
      {'q': 'How to create an agency', 'a': 'Contact official customer support to submit your business credentials and deposit requirements.'},
      {'q': 'How to invite a sub-agent', 'a': 'Go to Agency Center > Sub-Agents and generate an exclusive invite link or agency code.'},
      {'q': 'How to invite a host', 'a': 'Share your unique Agency ID with prospective creators to bind them under your roster.'},
      {'q': 'How to change your upline agent', 'a': 'Submit a transfer request during the official settlement window.'},
      {'q': 'Things to note when disbanding an agency', 'a': 'Ensure all host salaries and commission balances are completely cleared before disbanding.'},
      {'q': 'How to apply for BD', 'a': 'Reach out to the regional Business Development manager via official email.'},
    ],
    'Coin Seller': [
      {'q': 'How to become a coin seller', 'a': 'Meet the trading volume criteria and obtain official merchant authorization.'},
      {'q': 'How to become a payroll', 'a': 'Verified payroll accounts require corporate identification and compliance approval.'},
      {'q': 'Notes on coin pricing', 'a': 'Always adhere to the mandatory pricing brackets to prevent account suspension.'},
      {'q': 'How can a coin seller recall a transfer', 'a': 'Transfers made in error cannot be recalled without official platform mediation.'},
    ],
    'Rooms & Crown Seats': [
      {'q': 'How to invite users into a room', 'a': 'Tap the invite button inside the room and select online friends or share the room link.'},
      {'q': 'How to change a voice room theme, seat count, mic-on mode, and language', 'a': 'Open room settings at the top right to customize layout and access rights.'},

{'q': 'How to set a room admin', 'a': 'Tap on a user profile in the room and assign them moderator/admin privileges.'},
      {'q': 'Maximum number of room admins', 'a': 'Standard rooms permit up to 5 concurrent administrators.'},
      {'q': 'How to lock a room seat', 'a': 'Long press an empty microphone seat and tap Lock Seat.'},
      {'q': 'Condition for a Crown Seat to appear in a room', 'a': 'The highest contributor or VIP tier holder automatically claims the Crown Seat.'},
    ],
    'Tasks, Points & Earnings': [
      {'q': 'Daily task refresh time', 'a': 'All daily quests and check-in metrics reset strictly at 00:00 (UTC+0).'},
      {'q': 'What are the rules for inviting friends?', 'a': 'Invited friends must complete their phone binding and enter a room to award bonus points.'},
      {'q': 'How to view details of gifts received, withdrawals, redemptions, etc.', 'a': 'Open your Host Center or Wallet and tap on Transaction Records.'},
      {'q': 'How to view recharge details', 'a': 'Check your order history under the Recharge screen.'},
      {'q': 'Why are there frozen points and how to unfreeze them', 'a': 'Points under audit or dispute remain frozen until cleared within 48 hours.'},
    ],
    'Recharge & Withdrawal': [
      {'q': 'Ways to recharge coins', 'a': 'Use in-app Google Play payments, local payment channels, or authorized Coin Sellers.'},
      {'q': 'Google recharge not received', 'a': 'Wait up to 10 minutes, or submit your Google Play transaction invoice via Feedback.'},
      {'q': 'What is the withdrawal threshold?', 'a': 'Minimum withdrawal amounts depend on the selected payout processor.'},
      {'q': 'What withdrawal methods are available?', 'a': 'Local bank transfers, mobile wallets, and crypto settlements where applicable.'},
      {'q': 'How long does a withdrawal take to arrive', 'a': 'Standard processing takes 1 to 3 business days.'},
      {'q': 'How to withdraw, and what is the process', 'a': 'Bind your verified payout method under Wallet > Withdraw and submit your request.'},
    ],
  };

  final List<String> categories = [
    'Common Questions',
    'Account & Security',
    'Host-related',
    'Agency & Agent',
    'Coin Seller',
    'Rooms & Crown Seats',
    'Tasks, Points & Earnings',
    'Recharge & Withdrawal',
  ];

  @override
  Widget build(BuildContext context) {
    final currentFaqs = faqData[selectedCategory] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF3EDF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Feedback',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No previous records found.')),
              );
            },
            child: const Text('Record', style: TextStyle(color: Colors.black87, fontSize: 15)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              children: [
                // 1. Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),

child: const TextField(
                    decoration: InputDecoration(
                      icon: Icon(Icons.search, color: Colors.grey),
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.black38),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Issue types Header
                const Text(
                  'Issue types',
                  style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // 3. Category Buttons (Grid of 2 columns)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = selectedCategory == cat;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedCategory = cat;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF904BE6) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          cat,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 22),

                // 4. Questions & Answers Header
                const Text(
                  'Questions & Answers',
                  style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // 5. Expandable FAQ List
                ...currentFaqs.map((faq) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        iconColor: Colors.black54,
                        collapsedIconColor: Colors.black54,
                        title: Text(

faq['q']!,
                          style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                faq['a']!,
                                style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // 6. Bottom Sticky Feedback Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Still need help?',
                  style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feedback form opening...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF904BE6),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text(
                    'Feedback',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
