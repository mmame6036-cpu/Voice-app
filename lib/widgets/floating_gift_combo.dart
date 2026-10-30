import 'dart:async';
import 'package:flutter/material.dart';

class FloatingGiftComboOverlay extends StatefulWidget {
  final Stream<GiftSendEvent> giftStream;

  const FloatingGiftComboOverlay({super.key, required this.giftStream});

  @override
  State<FloatingGiftComboOverlay> createState() => _FloatingGiftComboOverlayState();
}

class GiftSendEvent {
  final String senderName;
  final String targetName;
  final String giftName;
  final String giftIcon;
  final int comboCount;

  GiftSendEvent({
    required this.senderName,
    required this.targetName,
    required this.giftName,
    required this.giftIcon,
    required this.comboCount,
  });
}

class _FloatingGiftComboOverlayState extends State<FloatingGiftComboOverlay>
    with SingleTickerProviderStateMixin {
  GiftSendEvent? _currentEvent;
  Timer? _hideTimer;
  late AnimationController _comboScaleController;
  late Animation<double> _comboScaleAnimation;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _comboScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _comboScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.6), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.6, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _comboScaleController,
      curve: Curves.easeOutBack,
    ));

    _subscription = widget.giftStream.listen((event) {
      _showGiftCombo(event);
    });
  }

  void _showGiftCombo(GiftSendEvent event) {
    _hideTimer?.cancel();
    setState(() {
      _currentEvent = event;
    });

    _comboScaleController.reset();
    _comboScaleController.forward();

    _hideTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() {
          _currentEvent = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _hideTimer?.cancel();
    _comboScaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentEvent == null) return const SizedBox.shrink();

    return Positioned(
      left: 16,
      top: 130,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        offset: Offset.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF8E2DE2),
                    Color(0xFF4A00E0),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFFFD700),
                    child: Icon(Icons.person, color: Colors.black, size: 22),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentEvent!.senderName,

style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Sent ${_currentEvent!.giftName} to ${_currentEvent!.targetName}",
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _currentEvent!.giftIcon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ScaleTransition(
              scale: _comboScaleAnimation,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFEE00), Color(0xFFFF3366)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Text(
                  "x${_currentEvent!.comboCount}",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 6,
                        offset: Offset(2, 2),
                      ),
                    ],
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
