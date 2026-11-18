import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class GiftVideoOverlay extends StatefulWidget {
  final String videoPath;
  final VoidCallback onFinished;

  const GiftVideoOverlay({
    super.key,
    required this.videoPath,
    required this.onFinished,
  });

  @override
  State<GiftVideoOverlay> createState() => _GiftVideoOverlayState();
}

class _GiftVideoOverlayState extends State<GiftVideoOverlay> {
  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _isImageFallback = false;
  bool _hasCompleted = false;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    _startPlayback();
  }

  void _completeOnce() {
    if (_hasCompleted) return;
    _hasCompleted = true;
    _safetyTimer?.cancel();
    if (mounted) {
      widget.onFinished();
    }
  }

  Future<void> _startPlayback() async {
    final path = widget.videoPath.trim();
    if (path.isEmpty) {
      _completeOnce();
      return;
    }

    // ፋይሉ .mp4 ካልሆነ (ለምሳሌ Lucky ስጦታ .jpg ከሆነ) ምስሉን ለ2 ሰከንድ ያሳያል
    if (!path.toLowerCase().endsWith('.mp4')) {
      if (mounted) {
        setState(() {
          _isImageFallback = true;
          _isReady = true;
        });
      }
      _safetyTimer = Timer(const Duration(seconds: 2), _completeOnce);
      return;
    }

    // ቪዲዮው በምንም ምክንያት እንዳይንጠለጠል የ12 ሰከንድ ገደብ
    _safetyTimer = Timer(const Duration(seconds: 12), _completeOnce);

    try {
      final ctrl = VideoPlayerController.asset(
        path,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _controller = ctrl;

      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }

      ctrl.addListener(_onVideoTick);
      await ctrl.setLooping(false);
      await ctrl.setVolume(1.0);
      await ctrl.play();

      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    } catch (_) {
      _completeOnce();
    }
  }

  void _onVideoTick() {
    final ctrl = _controller;
    if (ctrl == null) return;
    if (!ctrl.value.isInitialized) return;

    final int totalMs = ctrl.value.duration.inMilliseconds;
    final int posMs = ctrl.value.position.inMilliseconds;

    if (totalMs > 200 && posMs >= (totalMs - 100) && !ctrl.value.isPlaying) {
      _completeOnce();
    }
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return const SizedBox.shrink();

    if (_isImageFallback) {
      return Positioned.fill(
        child: IgnorePointer(
          ignoring: true,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1.15),
              duration: const Duration(milliseconds: 900),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Image.asset(
                widget.videoPath,
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (_, , _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
    }

    final ctrl = _controller;
    if (ctrl == null) return const SizedBox.shrink();

    double videoW = ctrl.value.size.width;
    double videoH = ctrl.value.size.height;
    if (videoW <= 0) videoW = 720;
    if (videoH <= 0) videoH = 1280;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: videoW,
            height: videoH,
            child: VideoPlayer(ctrl),
          ),
        ),
      ),
    );
  }
}
