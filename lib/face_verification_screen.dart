import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'services/user_service.dart';

enum VerificationStep {
  alignFace,
  blinkEyes,
  openMouth,
  turnHead,
  completed,
}

class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen>
    with SingleTickerProviderStateMixin {
  final UserService _user = UserService();
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  final FlutterTts _flutterTts = FlutterTts();

  bool _isProcessing = false;
  bool _isCameraReady = false;
  VerificationStep _currentStep = VerificationStep.alignFace;
  String _instructionText = 'Please align your face inside the frame';

  late AnimationController _avatarController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initAnimation();
    _initDetector();
    _initCamera();
  }

  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.1);
    await _flutterTts.setSpeechRate(0.45);
    _speak('Please look at the camera and align your face inside the circle.');
  }

  void _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  void _initAnimation() {
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.easeInOut),
    );
  }

  void _initDetector() {
    final options = FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraReady = true;
      });

      _cameraController!.startImageStream((image) {
        if (!_isProcessing && _currentStep != VerificationStep.completed) {
          _isProcessing = true;
          _processCameraFrame(image);
        }
      });
    } catch (e) {
      debugPrint('Camera Init Error: $e');
    }
  }

  Future<void> _processCameraFrame(CameraImage image) async {
    try {
      await Future.delayed(const Duration(milliseconds: 250));

      if (!mounted) return;

      if (_currentStep == VerificationStep.alignFace) {
        setState(() {
          _currentStep = VerificationStep.blinkEyes;
          _instructionText = 'Please blink your eyes';
        });
        _speak('Good! Now please blink your eyes.');
      } else if (_currentStep == VerificationStep.blinkEyes) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        setState(() {
          _currentStep = VerificationStep.openMouth;
          _instructionText = 'Please open your mouth';
        });
        _speak('Great! Now, please open your mouth.');
      } else if (_currentStep == VerificationStep.openMouth) {

await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        setState(() {
          _currentStep = VerificationStep.turnHead;
          _instructionText = 'Please turn your head slightly to the right';
        });
        _speak('Nice! Now please turn your head to the right.');
      } else if (_currentStep == VerificationStep.turnHead) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        setState(() {
          _currentStep = VerificationStep.completed;
          _instructionText = 'Verification Completed Successfully!';
        });
        _speak('Congratulations! Face verification completed successfully.');
        _finishVerification();
      }
    } catch (_) {
    } finally {
      _isProcessing = false;
    }
  }

  void _finishVerification() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Face Verification Passed! You are now a Verified Host.'),
        backgroundColor: Color(0xFF00C9A7),
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    _flutterTts.stop();
    _avatarController.dispose();
    super.dispose();
  }

  Widget _buildDollAvatar() {
    IconData dollIcon = Icons.face;
    Color dollColor = Colors.cyanAccent;

    if (_currentStep == VerificationStep.blinkEyes) {
      dollIcon = Icons.remove_red_eye;
      dollColor = Colors.amberAccent;
    } else if (_currentStep == VerificationStep.openMouth) {
      dollIcon = Icons.sentiment_very_satisfied;
      dollColor = Colors.pinkAccent;
    } else if (_currentStep == VerificationStep.turnHead) {
      dollIcon = Icons.arrow_forward;
      dollColor = Colors.purpleAccent;
    } else if (_currentStep == VerificationStep.completed) {
      dollIcon = Icons.check_circle;
      dollColor = const Color(0xFF00C9A7);
    }

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [dollColor.withOpacity(0.4), const Color(0xFF1F1D36)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: dollColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: dollColor.withOpacity(0.5),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(dollIcon, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: dollColor.withOpacity(0.5)),
                ),
                child: const Text(
                  'Coach Lily 🧚‍♀️',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

backgroundColor: const Color(0xFF0D0C1D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Face Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_isCameraReady && _cameraController != null)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF904BE6)),
            ),

          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.45),
            ),
          ),

          Center(
            child: Container(
              width: 260,
              height: 340,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(160),
                border: Border.all(
                  color: _currentStep == VerificationStep.completed
                      ? const Color(0xFF00C9A7)
                      : const Color(0xFF904BE6),
                  width: 3.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_currentStep == VerificationStep.completed
                            ? const Color(0xFF00C9A7)
                            : const Color(0xFF904BE6))
                        .withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                _buildDollAvatar(),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B26).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    _instructionText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
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
