import 'dart:async';
import 'package:flutter/material.dart';

class StartLiveScreen extends StatefulWidget {
  const StartLiveScreen({Key? key}) : super(key: key);

  @override
  State<StartLiveScreen> createState() => _StartLiveScreenState();
}

class _StartLiveScreenState extends State<StartLiveScreen> {
  int currentStep = 1;

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const FaceVerificationNoticeDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Start live',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // የማሳሰቢያ ባነር (Top Banner)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: const Color(0xFFFFF7ED),
            child: const Text(
              '3 Steps to Going Live - Make Money Daily!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFEA580C),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3ቱ ደረጃዎች (Step Indicator)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepItem(1, 'Verification', isActive: currentStep >= 1),
              _buildStepDivider(isActive: currentStep >= 2),
              _buildStepItem(2, 'Upload Cover', isActive: currentStep >= 2),
              _buildStepDivider(isActive: currentStep >= 3),
              _buildStepItem(3, 'Beautify', isActive: currentStep >= 3),
            ],
          ),
          const Spacer(),

          // የፊት መለያ ምልክት (Center Icon)
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF99F6E4),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
              const Icon(
                Icons.face_retouching_natural_rounded,
                size: 70,
                color: Color(0xFF14B8A6),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'To protect your account, please\nverify your face first.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          const Spacer(),

          // የታችኛው "Verify Now" ሰማያዊ ቁልፍ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _showVerificationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),

),
                  elevation: 0,
                ),
                child: const Text(
                  'Verify Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String title, {required bool isActive}) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$step',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.black89 : Colors.grey,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider({required bool isActive}) {
    return Container(
      width: 45,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
      color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade300,
    );
  }
}

// የማረጋገጫ መስኮት (Countdown Dialog)
class FaceVerificationNoticeDialog extends StatefulWidget {
  const FaceVerificationNoticeDialog({Key? key}) : super(key: key);

  @override
  State<FaceVerificationNoticeDialog> createState() => _FaceVerificationNoticeDialogState();
}

class _FaceVerificationNoticeDialogState extends State<FaceVerificationNoticeDialog> {
  int _secondsLeft = 4;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _secondsLeft = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isReady = _secondsLeft == 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.grey, size: 20),
              ),
            ),
            const Icon(
              Icons.verified_user_rounded,
              size: 50,
              color: Color(0xFF60A5FA),
            ),
            const SizedBox(height: 12),
            const Text(
              'Face Verification',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'To ensure the security of your account, please complete face verification first.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,

child: ElevatedButton(
                onPressed: isReady
                    ? () {
                        Navigator.pop(context);
                        // ወደ ክብ ካሜራ ገጽ የሚወስደው ቀጣይ ክፍል እዚህ ይጠራል
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReady ? const Color(0xFF2563EB) : Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: Text(
                  isReady ? 'Agree and verify' : 'Agree and verify(${_secondsLeft}s)',
                  style: TextStyle(
                    color: isReady ? Colors.white : Colors.black38,
                    fontWeight: FontWeight.bold,
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
