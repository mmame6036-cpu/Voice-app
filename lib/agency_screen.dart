import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AgencyCenterPage extends StatefulWidget {
  const AgencyCenterPage({Key? key}) : super(key: key);

  @override
  State<AgencyCenterPage> createState() => _AgencyCenterPageState();
}

class _AgencyCenterPageState extends State<AgencyCenterPage> {
  final String agencyName = "Star Agency";
  final String agencyId = "AG-882910";
  final String inviteCode = "STAR2026";

  final List<Map<String, dynamic>> hosts = [
    {
      "name": "Sara_Voice",
      "id": "104928",
      "micHours": "4.5 hrs",
      "points": "32,000",
      "avatarColor": Colors.pinkAccent,
    },
    {
      "name": "Abebe_Mic",
      "id": "209481",
      "micHours": "2.8 hrs",
      "points": "18,500",
      "avatarColor": Colors.blueAccent,
    },
    {
      "name": "Mimi_Host",
      "id": "301827",
      "micHours": "6.1 hrs",
      "points": "54,200",
      "avatarColor": Colors.amber,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        title: const Text("የኤጀንሲ ማዕከል (Agency Center)"),
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAgencyHeaderCard(),
            const SizedBox(height: 20),
            _buildSummaryRow(),
            const SizedBox(height: 25),
            const Text(
              "የሆስቶች ዝርዝር እና እንቅስቃሴ",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hosts.length,
              itemBuilder: (context, index) {
                final host = hosts[index];
                return _buildHostCard(host);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgencyHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                agencyName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "ID: $agencyId",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                "Invite Code: $inviteCode",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("የግብዣ ኮድ ኮፒ ተደርጓል!")),
                  );
                },
                child: const Icon(Icons.copy, color: Colors.white, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
              "ጠቅላላ ሆስቶች", "${hosts.length}", Colors.tealAccent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard("ጠቅላላ ፖይንት", "104,700", Colors.orangeAccent),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostCard(Map<String, dynamic> host) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: host["avatarColor"],
            child: Text(
              host["name"][0],
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  host["name"],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  "ID: ${host["id"]}",
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${host["points"]} Pts",
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.mic, color: Colors.greenAccent, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    host["micHours"],
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
