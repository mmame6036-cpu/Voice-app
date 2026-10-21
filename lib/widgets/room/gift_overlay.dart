import 'dart:math';
import 'package:flutter/material.dart';

class Big3DGiftOverlay extends StatefulWidget {
  final String senderName;
  final String giftName;
  final String imageUrl;
  final int count;
  final VoidCallback onFinish;

  const Big3DGiftOverlay({
    Key? key,
    required this.senderName,
    required this.giftName,
    required this.imageUrl,
    this.count = 1,
    required this.onFinish,
  }) : super(key: key);

  @override
  State<Big3DGiftOverlay> createState() => _Big3DGiftOverlayState();
}

class _Big3DGiftOverlayState extends State<Big3DGiftOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimController;

  // Car Animation Curves
  late Animation<Offset> _carSlideAnimation;

  // Rocket Animation Curves
  late Animation<Offset> _rocketSlideAnimation;
  late Animation<double> _rocketScaleAnimation;

  // Standard Bounce Curves
  late Animation<double> _bounceScaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _mainAnimController.forward().then((_) {
      if (mounted) widget.onFinish();
    });
  }

  void _initAnimations() {
    _mainAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2700),
    );

    // 1. Car drift sequence: Slide in from left, pause briefly, zoom out to right
    _carSlideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-1.6, 0.3), end: const Offset(0.0, 0.3))
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: ConstantTween(const Offset(0.0, 0.3)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.0, 0.3), end: const Offset(1.8, 0.3))
            .chain(CurveTween(curve: Curves.easeInBack)),
        weight: 35,
      ),
    ]).animate(_mainAnimController);

    // 2. Rocket launch sequence: Rise from bottom, pause, shoot into upper space
    _rocketSlideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.0, 1.4), end: const Offset(0.0, 0.0))
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween(const Offset(0.0, 0.0)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.0, 0.0), end: const Offset(0.0, -1.8))
            .chain(CurveTween(curve: Curves.easeInExpo)),
        weight: 40,
      ),
    ]).animate(_mainAnimController);

    _rocketScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.1), weight: 30),
      TweenSequenceItem(tween: ConstantTween(1.1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.6), weight: 40),
    ]).animate(_mainAnimController);

    // 3. Regular popup sequence with elastic pop
    _bounceScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.1, end: 1.25).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 30),
    ]).animate(_mainAnimController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_mainAnimController);
  }

  @override
  void dispose() {
    _mainAnimController.dispose();
    super.dispose();
  }

  Widget _buildGiftImage() {
    final bool isNetwork = widget.imageUrl.startsWith('http://') ||
        widget.imageUrl.startsWith('https://');

if (isNetwork) {
      return Image.network(
        widget.imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, , _) => const Icon(
          Icons.card_giftcard,
          color: Colors.amberAccent,
          size: 110,
        ),
      );
    }

    return Image.asset(
      widget.imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, , _) => const Icon(
        Icons.card_giftcard,
        color: Colors.amberAccent,
        size: 110,
      ),
    );
  }

  Widget _buildSenderBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C9A7), Color(0xFF6C5CE7)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '${widget.senderName} sent ${widget.giftName}!',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final giftLower = widget.giftName.toLowerCase();

    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _mainAnimController,
          builder: (context, child) {
            // 1. Car Animation
            if (giftLower.contains('car')) {
              return SlideTransition(
                position: _carSlideAnimation,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSenderBanner(),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: 320,
                        height: 220,
                        child: _buildGiftImage(),
                      ),
                    ],
                  ),
                ),
              );
            }

            // 2. Rocket Animation
            if (giftLower.contains('rocket')) {
              return SlideTransition(
                position: _rocketSlideAnimation,
                child: ScaleTransition(
                  scale: _rocketScaleAnimation,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSenderBanner(),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: 250,
                          height: 250,
                          child: _buildGiftImage(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // 3. Regular Bounce & Combo Pop Animation
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _bounceScaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00C9A7).withOpacity(0.45),

blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: _buildGiftImage(),
                    ),
                    const SizedBox(height: 14),
                    _buildSenderBanner(),
                    if (widget.count > 1) ...[
                      const SizedBox(height: 8),
                      Text(
                        'x${widget.count}',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
