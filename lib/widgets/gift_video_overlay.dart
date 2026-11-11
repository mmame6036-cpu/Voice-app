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
  late VideoPlayerController _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isReady = true);
          _controller.play();
        }
      });

    _controller.addListener(() {
      if (_controller.value.isInitialized &&
          _controller.value.position >= _controller.value.duration) {
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      ),
    );
  }
}
