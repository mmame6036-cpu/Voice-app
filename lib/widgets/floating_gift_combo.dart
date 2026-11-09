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
  final bool isLucky;
  final int wonCoins;
  final int luckyMultiplier;

  GiftSendEvent({
    required this.senderName,
    required this.targetName,
    required this.giftName,
    required this.giftIcon,
    required this.comboCount,
    this.isLucky = false,
    this.wonCoins = 0,
    this.luckyMultiplier = 0,
  });
}

class _FloatingGiftComboOverlayState extends State<FloatingGiftComboOverlay>
    with TickerProviderStateMixin {
  GiftSendEvent? _currentEvent;
  Timer? _hideTimer;
  StreamSubscription? _subscription;

  late AnimationController _comboScaleController;
  late Animation<double> _comboScaleAnimation;

  late AnimationController _burstController;
  late Animation<double> _burstScaleAnimation;
  late Animation<double> _burstFadeAnimation;
  bool _showBurst = false;

  @override
  void initState() {
    super.initState();

    _comboScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _comboScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _comboScaleController,
      curve: Curves.easeOutBack,
    ));

    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _burstScaleAnimation = Tween<double>(begin: 0.2, end: 1.2).animate(
      CurvedAnimation(parent: _burstController, curve: Curves.elasticOut),
    );

    _burstFadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_burstController);

    _burstController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _showBurst = false;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _subscription = widget.giftStream.listen((event) {
        if (mounted) {
          _showGiftCombo(event);
        }
      });
    });
  }

  void _showGiftCombo(GiftSendEvent event) {
    _hideTimer?.cancel();

    setState(() {
      _currentEvent = event;
    });

    if (_comboScaleController.isAnimating) {
      _comboScaleController.reset();
    }
    _comboScaleController.forward();

    if ((event.comboCount > 0 && event.comboCount % 5 == 0) || event.wonCoins > 0) {
      setState(() {
        _showBurst = true;
      });
      if (_burstController.isAnimating) {
        _burstController.reset();
      }
      _burstController.forward(from: 0.0);
    }

    _hideTimer = Timer(const Duration(milliseconds: 2600), () {
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
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentEvent == null && !_showBurst) {
      return const SizedBox.shrink();
    }

return Stack(
      children: [
        if (_currentEvent != null)
          Positioned(
            left: 16,
            top: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _currentEvent!.isLucky
                          ? [const Color(0xFFFF8C00), const Color(0xFFFF0080)]
                          : [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: (_currentEvent!.isLucky ? Colors.orangeAccent : Colors.purpleAccent).withOpacity(0.5),
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
                  child: Text(
                    "x${_currentEvent!.comboCount}",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFFFFD700),
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
              ],
            ),
          ),
        if (_showBurst && _currentEvent != null)
          Center(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: _burstFadeAnimation,
                child: ScaleTransition(
                  scale: _burstScaleAnimation,

child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_currentEvent!.wonCoins > 0
                                      ? const Color(0xFFFFD700)
                                      : const Color(0xFFFF1493))
                                  .withOpacity(0.6),
                              blurRadius: 35,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          "assets/images/weekly_lovers_heart_value.webp",
                          width: 150,
                          height: 150,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Text(_currentEvent!.giftIcon.isNotEmpty ? _currentEvent!.giftIcon : "💎",
                                  style: const TextStyle(fontSize: 90)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentEvent!.wonCoins > 0
                            ? "LUCKY x${_currentEvent!.luckyMultiplier}! +${_currentEvent!.wonCoins} COINS!"
                            : "COMBO ${_currentEvent!.comboCount}X BURST!",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFFFFD700),
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 8,
                              offset: Offset(2, 3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
