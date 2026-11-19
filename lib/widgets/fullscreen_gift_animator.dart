import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FullscreenGiftEvent {
  final String giftId;
  final String giftName;
  final String asset;
  final String giftIcon;
  final String senderName;

  FullscreenGiftEvent({
    required this.giftId,
    required this.giftName,
    required this.asset,
    this.giftIcon = "🎁",
    required this.senderName,
  });
}

class FullscreenGiftAnimator extends StatefulWidget {
  final Stream<FullscreenGiftEvent> giftStream;

  const FullscreenGiftAnimator({super.key, required this.giftStream});

  @override
  State<FullscreenGiftAnimator> createState() => _FullscreenGiftAnimatorState();
}

class _FullscreenGiftAnimatorState extends State<FullscreenGiftAnimator> {
  FullscreenGiftEvent? _currentGift;
  VideoPlayerController? _videoController;
  Timer? _dismissTimer;
  StreamSubscription? _subscription;

  int _playToken = 0;
  bool _isVideoReady = false;
  bool _useFallbackVisual = false;
  String _fallbackImagePath = "";
  double _opacity = 0.0;
  double _scale = 0.4;

  @override
  void initState() {
    super.initState();
    _subscription = widget.giftStream.listen((event) {
      if (!mounted) return;
      _playAnimation(event);
    });
  }

  String _toFallbackImage(String assetPath) {
    if (assetPath.isEmpty) return "";
    if (assetPath.toLowerCase().endsWith('.mp4')) {
      return assetPath
          .replaceFirst('assets/svga/', 'assets/images/')
          .replaceAll('.mp4', '.jpg');
    }
    return assetPath;
  }

  Future<void> _disposeCurrentVideo() async {
    final oldCtrl = _videoController;
    _videoController = null;
    if (oldCtrl != null) {
      oldCtrl.removeListener(_onVideoProgress);
      try {
        await oldCtrl.dispose();
      } catch (_) {}
    }
  }

  Future<void> _playAnimation(FullscreenGiftEvent event) async {
    _playToken++;
    final int currentToken = _playToken;

    _dismissTimer?.cancel();
    await _disposeCurrentVideo();

    if (!mounted) return;

    final String assetPath = event.asset.trim();
    final bool isMp4 = assetPath.toLowerCase().endsWith('.mp4');

    setState(() {
      _currentGift = event;
      _isVideoReady = false;
      _useFallbackVisual = false;
      _fallbackImagePath = _toFallbackImage(assetPath);
      _opacity = 1.0;
      _scale = 0.45;
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      if (_playToken != currentToken) return;
      setState(() {
        _scale = 1.0;
      });
    });

    if (!isMp4) {
      setState(() {
        _useFallbackVisual = true;
      });
      _dismissTimer = Timer(const Duration(milliseconds: 2400), () {
        _finishCurrentGift(currentToken);
      });
      return;
    }

    _dismissTimer = Timer(const Duration(seconds: 10), () {
      _finishCurrentGift(currentToken);
    });

    try {
      final ctrl = VideoPlayerController.asset(
        assetPath,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await ctrl.initialize();

      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      if (_playToken != currentToken) {
        await ctrl.dispose();
        return;
      }

      _videoController = ctrl;
      ctrl.addListener(_onVideoProgress);

      final int durMs = ctrl.value.duration.inMilliseconds;
      if (durMs > 300) {
        _dismissTimer?.cancel();
        _dismissTimer = Timer(Duration(milliseconds: durMs + 250), () {
          _finishCurrentGift(currentToken);
        });
      }

      await ctrl.setLooping(false);
      await ctrl.setVolume(1.0);
      await ctrl.play();

      if (mounted) {
        if (_playToken == currentToken) {
          setState(() {
            _isVideoReady = true;

});
        }
      }
    } catch (_) {
      if (mounted) {
        if (_playToken == currentToken) {
          setState(() {
            _isVideoReady = false;
            _useFallbackVisual = true;
          });
          _dismissTimer?.cancel();
          _dismissTimer = Timer(const Duration(milliseconds: 2400), () {
            _finishCurrentGift(currentToken);
          });
        }
      }
    }
  }

  void _onVideoProgress() {
    final ctrl = _videoController;
    if (ctrl == null) return;
    if (!ctrl.value.isInitialized) return;

    if (ctrl.value.isCompleted) {
      _finishCurrentGift(_playToken);
      return;
    }

    final int totalMs = ctrl.value.duration.inMilliseconds;
    final int posMs = ctrl.value.position.inMilliseconds;

    if (totalMs > 200) {
      if (posMs >= (totalMs - 300)) {
        if (!ctrl.value.isPlaying) {
          _finishCurrentGift(_playToken);
        }
      }
    }
  }

  void _finishCurrentGift(int token) {
    if (!mounted) return;
    if (token != _playToken) return;

    _dismissTimer?.cancel();
    setState(() {
      _opacity = 0.0;
    });

    Future.delayed(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      if (token != _playToken) return;
      await _disposeCurrentVideo();
      if (mounted) {
        if (token == _playToken) {
          setState(() {
            _currentGift = null;
            _isVideoReady = false;
            _useFallbackVisual = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _dismissTimer?.cancel();
    _disposeCurrentVideo();
    super.dispose();
  }

  Widget _buildIconCenterpiece(String icon) {
    return Container(
      width: 190,
      height: 190,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.45),
            const Color(0xFFFF8C00).withOpacity(0.15),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Text(
          icon,
          style: const TextStyle(fontSize: 105),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentGift == null) return const SizedBox.shrink();

    double videoW = 720;
    double videoH = 1280;
    final ctrl = _videoController;
    if (ctrl != null) {
      if (ctrl.value.isInitialized) {
        if (ctrl.value.size.width > 0) videoW = ctrl.value.size.width;
        if (ctrl.value.size.height > 0) videoH = ctrl.value.size.height;
      }
    }

    final String activeIcon = _currentGift!.giftIcon;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _opacity,
          child: Stack(
            children: [
              if (_isVideoReady && ctrl != null)
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: videoW,
                      height: videoH,
                      child: VideoPlayer(ctrl),
                    ),
                  ),
                ),

              if (_useFallbackVisual)
                Center(
                  child: AnimatedScale(
                    scale: _scale,
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutBack,
                    child: _fallbackImagePath.isNotEmpty
                        ? ClipOval(
                            child: Image.asset(
                              _fallbackImagePath,
                              width: 210,
                              height: 210,

fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) =>
                                  _buildIconCenterpiece(activeIcon),
                            ),
                          )
                        : _buildIconCenterpiece(activeIcon),
                  ),
                ),

              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      "🎉 ${_currentGift!.senderName} sent ${_currentGift!.giftName}! $activeIcon",
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
