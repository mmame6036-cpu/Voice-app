import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class TaskScreen extends StatefulWidget {
  final String userId;

  const TaskScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool isFaceVerified = false;
  bool isLoading = false;

  // የነጥብና የታስክ ሁኔታዎች
  int totalPoints = 0;
  int streakDays = 0; // ለ 7 ቀን ተከታታይ
  int liveMinutesToday = 0; // የቀን ላይቭ ደቂቃ
  int chairMinutesToday = 0; // የወንበር ደቂቃ
  int giftCoinsReceived = 0; // የተሰጠ/የተቀበለው ስጦታ (ግብ = 600)

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

  Future<void> _verifyFace() async {
    setState(() => isLoading = true);
    try {
      final bool canAuthenticate =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        _notify('ይህ ስልክ የባዮሜትሪክ/የፊት አሻራ አይደግፍም!');
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'ዕለታዊ የታስክ ስራዎችን ለመክፈት የፊት አሻራዎን ያረጋግጡ',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        setState(() {
          isFaceVerified = true;
        });
        _notify('የፊት አሻራ ማረጋገጫ ተሳክቷል! ታስኮች ተከፍተዋል።');
      } else {
        _notify('የፊት አሻራ ማረጋገጫው አልተሳካም!');
      }
    } catch (e) {
      _notify('ስህተት ተከስቷል: $e');
    } finally {
      setState(() => isLoading = false);
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
            // 1. የነጥብ ማሳያ ካርድ (Points Header)
            _buildPointsHeader(),

            const SizedBox(height: 20),

            // 2. የፊት አሻራ ማረጋገጫ ክፍል (Auth Banner)
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

            // ታስክ 1፦ የ 7 ቀን ተከታታይ ግብ (8,000 Points)
            _buildTaskCard(
              title: 'የ 7 ቀን ተከታታይ ላይቭ (Streak)',
              points: '8,000 Points',
              requirement: 'በየቀኑ 2 ሰዓት (120 ደቂቃ) ለ 7 ተከታታይ ቀናት ላይቭ መቆየት',
              progressText: '$streakDays / 7 ቀናት ተጠናቀቁ',
              progressValue: streakDays / 7.0,
              icon: Icons.local_fire_department,
              accentColor: Colors.deepOrangeAccent,
              isLocked: !isFaceVerified,
            ),

            const SizedBox(height: 14),

            // ታስክ 2፦ ዕለታዊ ተጨማሪ ሰዓት (1,000+ Points)
            _buildTaskCard(
              title: 'ዕለታዊ የቀጥታ ስርጭት (Daily Live)',

points: '1,000+ Points',
              requirement: 'በየቀኑ 1 ሰዓት (60 ደቂቃ) ላይቭ መቆየት (ቋሚ መነሻ ሆኖ ወደላይ ይጨምራል)',
              progressText: '$liveMinutesToday / 60 ደቂቃ ተጠናቀቀ',
              progressValue: (liveMinutesToday / 60.0).clamp(0.0, 1.0),
              icon: Icons.videocam,
              accentColor: Colors.cyanAccent,
              isLocked: !isFaceVerified,
            ),

            const SizedBox(height: 14),

            // ታስክ 3፦ የወርቃማ ወንበር ታስክ (1,000 Points)
            _buildTaskCard(
              title: 'የወርቃማ ወንበር ቆይታና ስጦታ (Golden Chair)',
              points: '1,000 Points',
              requirement: 'በወርቃማ ወንበር ላይ 1 ሰዓት (60 ደቂቃ) መቆየት + 600 ኮይን ስጦታ መስጠት ወይም መቀበል',
              progressText: 'ወንበር: $chairMinutesToday/60 ደቂቃ | ስጦታ: $giftCoinsReceived/600 ኮይን',
              progressValue: ((chairMinutesToday / 60.0) + (giftCoinsReceived / 600.0)) / 2.0,
              icon: Icons.event_seat,
              accentColor: Colors.amberAccent,
              isLocked: !isFaceVerified,
            ),
          ],
        ),
      ),
    );
  }

  // የነጥብ ማሳያ ራስጌ
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
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ጠቅላላ የተሰበሰበ ነጥብ',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                '$totalPoints',
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
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

  // የፊት አሻራ ማረጋገጫ ካርድ
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
              color: isFaceVerified
                  ? Colors.greenAccent.withOpacity(0.15)
                  : Colors.tealAccent.withOpacity(0.15),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isFaceVerified
                      ? 'ታስኮች ክፍት ናቸው፤ ስራዎን ይቀጥሉ'
                      : 'ታስኮችን ለመክፈት አሻራዎን ያረጋግጡ',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!isFaceVerified)
            isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.tealAccent),
                  )
                : ElevatedButton(
                    onPressed: _verifyFace,
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

  // የታስክ ካርድ መገንቢያ
  Widget _buildTaskCard({
    required String title,
    required String points,
    required String requirement,
    required String progressText,
    required double progressValue,
    required IconData icon,
    required Color accentColor,
    required bool isLocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171926),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked ? Colors.white12 : accentColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.white10
                      : accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLocked ? Icons.lock : icon,
                  color: isLocked ? Colors.white38 : accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isLocked ? Colors.white54 : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      points,
                      style: TextStyle(
                        color: isLocked ? Colors.white30 : accentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

],
          ),
          const SizedBox(height: 12),
          Text(
            requirement,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: isLocked ? 0.0 : progressValue.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF232538),
              valueColor: AlwaysStoppedAnimation<Color>(
                isLocked ? Colors.white24 : accentColor,
              ),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isLocked ? 'ተቆልፏል (አሻራ ያስፈልጋል)' : progressText,
                style: TextStyle(
                  color: isLocked ? Colors.redAccent.shade100 : Colors.white60,
                  fontSize: 11,
                ),
              ),
              Text(
                isLocked ? '' : '${(progressValue.clamp(0.0, 1.0) * 100).toInt()}%',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
