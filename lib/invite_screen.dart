import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InviteScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final Function(int bonusCoins) onRewardClaimed;

  const InviteScreen({
    Key? key,
    required this.userId,
    required this.userName,
    required this.onRewardClaimed,
  }) : super(key: key);

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _redeemController = TextEditingController();

  // የግብዣ ዳሽቦርድ መረጃዎች (Dashboard Data)
  int _totalInvited = 3;
  int _totalEarnedCoins = 1500;
  bool _hasRedeemedCode = false;

  final List<Map<String, dynamic>> _invitedUsers = [
    {'name': 'Abebe Host', 'type': 'Host (Agency)', 'date': 'Today', 'reward': '+500 Coins'},
    {'name': 'Sara VIP', 'type': 'User', 'date': 'Yesterday', 'reward': '+500 Coins'},
    {'name': 'Dawit User', 'type': 'User', 'date': '3 days ago', 'reward': '+500 Coins'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00C9A7),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _claimReward(int coins) {
    widget.onRewardClaimed(coins);
    setState(() {
      _totalEarnedCoins += coins;
    });
  }

  void _redeemFriendCode() {
    String code = _redeemController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    if (_hasRedeemedCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ቀደም ሲል የግብዣ ኮድ ተጠቅመዋል!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (code == "NILE-${widget.userId}") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('የራስዎን ኮድ መጠቀም አይችሉም!'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    setState(() {
      _hasRedeemedCode = true;
    });
    _claimReward(200); // አዲስ ተጠቃሚ በኮድ ሲገባ የሚሰጠው 200 ቦነስ
    _redeemController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber),
            SizedBox(width: 8),
            Text('እንኳን ደስ አለዎት! 🎉', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'በተሳካ ሁኔታ የጓደኛዎን ኮድ አስገብተዋል! 200 Nile Coins ቦነስ ወደ ቦርሳዎ ገብቷል።',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C9A7)),
            onPressed: () => Navigator.pop(context),
            child: const Text('እሺ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String myReferralCode = "NILE-${widget.userId}";
    String myAgencyCode = "AGENCY-${widget.userId}";
    String shareLink = "https://nilevoice.live/join?ref=$myReferralCode";

    return Scaffold(
      backgroundColor: const Color(0xFF0D111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        title: const Text('Invite & Earn 🎁', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),

leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00C9A7),
          labelColor: const Color(0xFF00C9A7),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'User Invitation'),
            Tab(icon: Icon(Icons.business_center), text: 'Agency / Host'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. መደበኛ የተጠቃሚዎች ግብዣ (User Tab)
          _buildUserInviteTab(myReferralCode, shareLink),

          // 2. የኤጀንሲ እና የሆስት ምልመላ ግብዣ (Agency Tab)
          _buildAgencyInviteTab(myAgencyCode),
        ],
      ),
    );
  }

  Widget _buildUserInviteTab(String referralCode, String shareLink) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00897B), Color(0xFF004D40)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00897B).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.card_giftcard, size: 50, color: Colors.amber),
                const SizedBox(height: 10),
                const Text(
                  'ጓደኞችህን ጋብዝ እና ሳንቲም አግኝ!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'ለእያንዳንዱ ለሚጋብዙት ጓደኛ 500 Nile Coins ያግኙ፤ ተጋባዡም 200 Coins ቦነስ ይሰጠዋል!',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ክፍል 1፦ የእኔ መለያ ኮድ እና ሊንክ (Referral Code & Link)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('የእርስዎ ልዩ የግብዣ ኮድ (My Code)', style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D111A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00C9A7).withOpacity(0.5)),
                        ),
                        child: Text(
                          referralCode,
                          style: const TextStyle(
                            fontSize: 18,

fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Color(0xFF00C9A7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C9A7),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _copyToClipboard(referralCode, 'የግብዣ ኮዱ ተገልብጧል!'),
                      icon: const Icon(Icons.copy, color: Colors.black, size: 18),
                      label: const Text('Copy', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // የሊንክ ማጋሪያ ቁልፍ (Share Link)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2838),
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _copyToClipboard(
                    "ሰላም! በ Nile Voice አፕሊኬሽን የቀጥታ ድምፅ ክፍሎች ይግቡ እና አብረን እናውራ! በኮዴ ይመዝገቡ: $referralCode ሊንክ: $shareLink",
                    'የግብዣ ሊንኩ ለመላክ ተዘጋጅቷል!',
                  ),
                  icon: const Icon(Icons.share, color: Colors.amber, size: 20),
                  label: const Text('ግብዣውን በቴሌግራም/ዋትስአፕ አጋራ (Share Link)', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ክፍል 2፦ የግብዣ ኮድ መመዝገቢያ (የጓደኛ ኮድ ማስገቢያ)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('የጓደኛዎን የግብዣ ኮድ ያስገቡ (200 Coins ቦነስ ያግኙ)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _redeemController,
                        enabled: !_hasRedeemedCode,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _hasRedeemedCode ? 'ተጠቅመዋል' : 'ምሳሌ: NILE-1001',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF0D111A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasRedeemedCode ? Colors.grey : Colors.amber,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

),
                      onPressed: _hasRedeemedCode ? null : _redeemFriendCode,
                      child: const Text('ተቀበል', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ክፍል 4፦ የተጋባዦች ሰሌዳ እና ገቢ (Dashboard)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('የተጋበዙ ሰዎች', style: TextStyle(color: Colors.white54, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('$_totalInvited', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Container(height: 35, width: 1, color: Colors.white12),
                    Column(
                      children: [
                        const Text('የተገኘ ሳንቲም', style: TextStyle(color: Colors.white54, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text('$_totalEarnedCoins', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 28),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('የቅርብ ጊዜ ተጋባዦች (Invited History)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                ..._invitedUsers.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 14,
                                backgroundColor: Color(0xFF1E2838),
                                child: Icon(Icons.person, size: 16, color: Color(0xFF00C9A7)),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                  Text(item['type'], style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          Text(item['reward'], style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ክፍል 3፦ የኤጀንሲ እና የሆስት ምልመላ ገጽ (Agency Tab)
  Widget _buildAgencyInviteTab(String agencyCode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF283593), Color(0xFF1A237E)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.workspace_premium, size: 50, color: Colors.amberAccent),
                const SizedBox(height: 10),
                const Text(
                  'የኤጀንሲ ሆስቶች ምልመላ (Agency Portal)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'ሆስቶችን በኤጀንሲ ኮድዎ ስር በማስመዝገብ ከስርጭት ሰዓታቸውና ከሚያገኙት ስጦታ ቋሚ የኤጀንሲ ኮሚሽን ያግኙ!',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('የኤጀንሲ መለያ ኮድ (Agency Code)', style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D111A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.indigoAccent),
                        ),
                        child: Text(
                          agencyCode,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.indigoAccent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _copyToClipboard(agencyCode, 'የኤጀንሲ ኮድ ተገልብጧል!'),
                      child: const Text('Copy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '📌 አሰራር፦\n1. አዲሱ ሆስት በ Nile Voice አፕሊኬሽን ሲመዘገብ ይህንን የኤጀንሲ ኮድ ያስገባል።\n2. ሆስቱ በቀጥታ በእርስዎ ኤጀንሲ ሰሌዳ ስር ይመደባል።\n3. የሆስቱ ሳምንታዊ የስራ ሰዓት እና ያገኘው የነጥብ መጠን በቀጥታ ለኤጀንሲው ሪፖርት ይደረጋል።',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
