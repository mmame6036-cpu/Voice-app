import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'upload_cover_screen.dart';

class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({Key? key}) : super(key: key);

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  Timer? _verificationTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });

        // ካሜራው እንደበራ ለሙከራ ከ 3 ሰከንድ በኋላ ወደ ደረጃ 2 (Upload Cover) እንዲያሳልፍ
        _verificationTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UploadCoverScreen()),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('የካሜራ ስህተት: $e');
    }
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Face Verification',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),

          // የሁኔታ ማሳወቂያ ጽሑፍ (Status Message)
          const Text(
            'No qualified face detected',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 50),

          // ክብ የካሜራ መመልከቻ (Circular Camera Preview)
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blue.shade100,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.08),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipOval(
                child: _isCameraInitialized && _cameraController != null
                    ? AspectRatio(
                        aspectRatio: 1,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _cameraController!.value.previewSize?.height ?? 280,
                            height: _cameraController!.value.previewSize?.width ?? 280,
                            child: CameraPreview(_cameraController!),

),
                        ),
                      )
                    : Container(
                        color: Colors.black12,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
              ),
            ),
          ),

          const Spacer(),

          // የታችኛው መመሪያ ማሳሰቢያ
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Make sure your face is clearly visible',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
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
