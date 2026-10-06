import 'package:flutter/material.dart';
import 'chairs_management_screen.dart';

class TaskScreen extends StatefulWidget {
  final dynamic userId;
  final dynamic userData;

  const TaskScreen({
    Key? key,
    this.userId,
    this.userData,
  }) : super(key: key);

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  bool isFaceVerified = false;

  // የነጥብና የታስክ ሁኔታዎች
  int totalPoints = 0;
  int streakDays = 0; // ለ 7 ቀን ተከታታይ
  int liveMinutesToday = 0; // የቀን ላይቭ ደቂቃ
  int chairMinutesToday = 0; // የወንበር ደቂቃ
  int giftCoinsReceived = 0; // የተሰጠ/የተቀበለው ስጦታ

  void _notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2A2B3D),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // የፊት አሻራ ማረጋገጫ Dialog
  void _verifyFaceAndGo() {
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ሰርዝ', style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {
                  isFaceVerified = true;
                });
                _notify('የፊት አሻራ ማረጋገጫ ተሳክቷል!');

                // በቀጥታ ወደ ወንበሮቹ ገጽ ይወስዳል
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChairsManagementScreen()),
                );
              },
              child: const Text('አረጋግጥ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // "Go" በተን ሲነካ
  void _onGoPressed() {
    if (!isFaceVerified) {
      _verifyFaceAndGo();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChairsManagementScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1017),
      appBar: AppBar(
        title: const Text(
          'የሆስቶች ታስክ ማዕከል (Task Center)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF181926),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. የነጥብ ማሳያ ካርድ
            _buildPointsHeader(),

            const SizedBox(height: 20),

// 2. የፊት አሻራ ማረጋገጫ ክፍል
            _buildFaceVerificationCard(),

            const SizedBox(height: 24),

            const Text(
              'ዕለታዊና ሳምንታዊ ግቦች',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // ታስክ 1
            _buildTaskCard(
              title: 'የ 7 ቀን ተከታታይ ላይቭ (Streak)',
              points: '8,000 Points',
              requirement: 'በየቀኑ 2 ሰዓት (120 ደቂቃ) ለ 7 ተከታታይ ቀናት ላይቭ መቆየት',
              progressText: '$streakDays / 7 ቀናት ተጠናቀቁ',
              progressValue: streakDays / 7.0,
              icon: Icons.local_fire_department,
              accentColor: Colors.deepOrangeAccent,
              onGo: _onGoPressed,
            ),

            const SizedBox(height: 14),

            // ታስክ 2
            _buildTaskCard(
              title: 'ዕለታዊ የቀጥታ ስርጭት (Daily Live)',
              points: '1,000+ Points',
              requirement: 'በየቀኑ 1 ሰዓት (60 ደቂቃ) ላይቭ መቆየት',
              progressText: '$liveMinutesToday / 60 ደቂቃ ተጠናቀቀ',
              progressValue: (liveMinutesToday / 60.0).clamp(0.0, 1.0),
              icon: Icons.videocam,
              accentColor: Colors.cyanAccent,
              onGo: _onGoPressed,
            ),

            const SizedBox(height: 14),

            // ታስክ 3
            _buildTaskCard(
              title: 'የወርቃማ ወንበር ቆይታና ስጦታ (Golden Chair)',
              points: '1,000 Points',
              requirement: 'በወርቃማ ወንበር ላይ 1 ሰዓት መቆየት + 600 ኮይን ስጦታ',
              progressText: 'ወንበር: $chairMinutesToday/60 ደቂቃ | ስጦታ: $giftCoinsReceived/600 ኮይን',
              progressValue: ((chairMinutesToday / 60.0) + (giftCoinsReceived / 600.0)) / 2.0,
              icon: Icons.event_seat,
              accentColor: Colors.amberAccent,
              onGo: _onGoPressed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C194D), Color(0xFF1F1C38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ጠቅላላ የተሰበሰበ ነጥብ', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                '$totalPoints',
                style: const TextStyle(color: Colors.amberAccent, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars, color: Colors.amberAccent, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceVerificationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171926),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFaceVerified ? Colors.greenAccent : Colors.tealAccent.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [

Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isFaceVerified ? Colors.greenAccent.withOpacity(0.15) : Colors.tealAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFaceVerified ? Icons.verified_user : Icons.face_retouching_natural,
              color: isFaceVerified ? Colors.greenAccent : Colors.tealAccent,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFaceVerified ? 'የፊት አሻራ ተረጋግጧል' : 'የፊት አሻራ ማረጋገጫ',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  isFaceVerified ? 'ማረጋገጫው አልፏል፤ ወንበሮችን መጠቀም ይችላሉ' : 'ወደ ወንበር ለመሄድ አሻራዎን ያረጋግጡ',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!isFaceVerified)
            ElevatedButton(
              onPressed: _verifyFaceAndGo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('አረጋግጥ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required String points,
    required String requirement,
    required String progressText,
    required double progressValue,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onGo,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171926),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(points, style: TextStyle(color: accentColor, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onGo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: const Text('Go', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),

),
            ],
          ),
          const SizedBox(height: 12),
          Text(requirement, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF232538),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(progressText, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              Text(
                '${(progressValue.clamp(0.0, 1.0) * 100).toInt()}%',
                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
