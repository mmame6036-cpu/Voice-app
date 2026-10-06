import 'package:flutter/material.dart';
import 'chairs_management_screen.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({Key? key}) : super(key: key);

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  // የፊት አሻራ መረጋገጡን መቆጣጠሪያ
  bool isFaceVerified = false;

  // የታስኮች ዝርዝር
  final List<Map<String, dynamic>> tasksList = [
    {
      'title': 'የመጀመሪያውን ቪአይፒ ወንበር ክፈት',
      'desc': 'በጌም 200,000 ኮይን በማንቀሳቀስ ወንበር 11-20ን ይክፈቱ',
      'reward': '+20,000 Pts',
      'icon': Icons.chair,
    },
    {
      'title': 'የፕሪሚየም ወንበር ተልዕኮ',
      'desc': 'ተጨማሪ 200,000 ኮይን በማንቀሳቀስ ወንበር 21-30ን ያጠናቁ',
      'reward': '+20,000 Pts',
      'icon': Icons.workspace_premium,
    },
    {
      'title': 'ዕለታዊ የድምፅ ክፍል ተሳትፎ',
      'desc': 'በቀጥታ የድምፅ ሩም ውስጥ ለ30 ደቂቃ ይቆዩ',
      'reward': '+5,000 Pts',
      'icon': Icons.mic,
    },
    {
      'title': 'የጌም ተሳትፎ ተልዕኮ',
      'desc': 'በሚኒ ጌሞች ላይ በመሳተፍ ተጨማሪ ነጥብ ይሰብስቡ',
      'reward': '+10,000 Pts',
      'icon': Icons.sports_esports,
    },
  ];

  // የፊት አሻራ ማረጋገጫ መጠየቂያ Dialog
  void _verifyFaceAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.face_retouching_natural, color: Colors.cyanAccent),
              SizedBox(width: 8),
              Text(
                'የፊት አሻራ ማረጋገጫ',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.camera_front, size: 70, color: Colors.cyanAccent),
              SizedBox(height: 16),
              Text(
                'እባክዎ ፊትዎን ወደ ካሜራው ያሳዩ...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // ሰርዝ
              },
              child: const Text('ሰርዝ', style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
              onPressed: () {
                Navigator.pop(dialogContext); // Dialogውን ዝጋ
                setState(() {
                  isFaceVerified = true; // ተረጋገጠ
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('የፊት አሻራ ማረጋገጫ ተሳክቷል!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 1),
                  ),
                );

                // በቀጥታ ወደ ወንበሮቹ ገጽ ይወስዳል
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChairsManagementScreen(),
                  ),
                );
              },
              child: const Text('አረጋግጥ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // "Go" በተን ሲነካ የሚሰራ
  void _onGoPressed() {
    if (!isFaceVerified) {
      // ገና ካልተረጋገጠ መጀመሪያ የፊት አሻራ ይጠይቃል
      _verifyFaceAndNavigate();
    } else {
      // አስቀድሞ ከተረጋገጠ በቀጥታ ወደ ወንበር ገጽ ይሄዳል
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ChairsManagementScreen(),
        ),
      );
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F131C),
      appBar: AppBar(
        title: const Text('የተግባራት ማዕከል (Task Center)'),
        backgroundColor: const Color(0xFF161B26),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ከላይ የተቀመጠ የፊት አሻራ ሳጥን
            _buildFaceVerificationHeader(),
            const SizedBox(height: 20),

            // 2. የታስኮች አርዕስት
            const Text(
              'ዕለታዊ እና ልዩ ተግባራት',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 3. ወደ ታች የተዘረዘሩ ታስኮች ከ "Go" በተን ጋር
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasksList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final task = tasksList[index];
                return _buildTaskItem(
                  title: task['title'] as String,
                  desc: task['desc'] as String,
                  reward: task['reward'] as String,
                  icon: task['icon'] as IconData,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // የፊት አሻራ ሳጥን ዲዛይን
  Widget _buildFaceVerificationHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFaceVerified ? Colors.greenAccent : Colors.cyanAccent.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isFaceVerified
                  ? Colors.greenAccent.withOpacity(0.15)
                  : Colors.cyanAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.face_retouching_natural,
              color: isFaceVerified ? Colors.greenAccent : Colors.cyanAccent,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFaceVerified ? 'የፊት አሻራ ተረጋግጧል' : 'የፊት አሻራ ማረጋገጫ ሳጥን',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isFaceVerified
                      ? 'ማረጋገጫው አልፏል፤ ተግባራትን መፈፀም ይችላሉ'
                      : 'ወደ ወንበር ለመሄድ መጀመሪያ የፊት አሻራ ያረጋግጡ',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isFaceVerified)
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 24)
          else
            TextButton(
              onPressed: _verifyFaceAndNavigate,
              child: const Text('አረጋግጥ', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // እያንዳንዱ የተዘረዘረ ታስክ ከ "Go" በተን ጋር

Widget _buildTaskItem({
    required String title,
    required String desc,
    required String reward,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2232),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  reward,
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // "Go" በተን
          ElevatedButton(
            onPressed: _onGoPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: const Text(
              'Go',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
