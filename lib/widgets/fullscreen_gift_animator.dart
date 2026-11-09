import 'dart:async';
import 'package:flutter/material.dart';

class FullscreenGiftEvent {
  final String giftId;
  final String giftName;
  final String asset;
  final String senderName;

  FullscreenGiftEvent({
    required this.giftId,
    required this.giftName,
    required this.asset,
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
  Timer? _dismissTimer;
  StreamSubscription? _subscription;
  double _opacity = 0.0;
  double _scale = 0.3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _subscription = widget.giftStream.listen((event) {
        if (!mounted) return;
        _playAnimation(event);
      });
    });
  }

  void _playAnimation(FullscreenGiftEvent event) {
    _dismissTimer?.cancel();

    setState(() {
      _currentGift = event;
      _opacity = 0.0;
      _scale = 0.3;
    });

    // Fade and Scale in smoothly
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted && _currentGift != null) {
        setState(() {
          _opacity = 1.0;
          _scale = 1.0;
        });
      }
    });

    // Dismiss after 3.2 seconds
    _dismissTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        setState(() {
          _opacity = 0.0;
          _scale = 1.3;
        });
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            setState(() {
              _currentGift = null;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentGift == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 350),
          opacity: _opacity,
          child: Container(
            color: Colors.black.withOpacity(0.35),
            child: Center(
              child: AnimatedScale(
                scale: _scale,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orangeAccent.withOpacity(0.6),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        "🎉 ${_currentGift!.senderName} sent ${_currentGift!.giftName}! 🚀",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),

),
                    const SizedBox(height: 25),
                    Image.asset(
                      _currentGift!.asset,
                      width: 260,
                      height: 260,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => const Icon(
                        Icons.card_giftcard,
                        size: 150,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
