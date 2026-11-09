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

class _FloatingGiftComboOverlayState extends State<FloatingGiftComboOverlay> {
  GiftSendEvent? _currentEvent;
  Timer? _hideTimer;
  StreamSubscription? _subscription;
  bool _showBurst = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _subscription = widget.giftStream.listen((event) {
        if (!mounted) return;
        _showGiftCombo(event);
      });
    });
  }

  void _showGiftCombo(GiftSendEvent event) {
    _hideTimer?.cancel();

    setState(() {
      _currentEvent = event;
      if ((event.comboCount > 0 && event.comboCount % 5 == 0) || event.wonCoins > 0) {
        _showBurst = true;
      } else {
        _showBurst = false;
      }
    });

    _hideTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _currentEvent = null;
          _showBurst = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentEvent == null) return const SizedBox.shrink();

    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 16,
            top: 130,
            child: AnimatedOpacity(
              opacity: _currentEvent != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
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
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFFFFD700),
                          child: Icon(Icons.person, color: Colors.black, size: 20),
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
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Sent ${_currentEvent!.giftName} to ${_currentEvent!.targetName}",
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentEvent!.giftIcon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "x${_currentEvent!.comboCount}",
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFFFFD700),
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 6, offset: Offset(2, 2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showBurst)
            Center(
              child: IgnorePointer(
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
                        width: 140,
                        height: 140,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Text(_currentEvent!.giftIcon.isNotEmpty ? _currentEvent!.giftIcon : "💎",
                                style: const TextStyle(fontSize: 80)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _currentEvent!.wonCoins > 0
                          ? "LUCKY x${_currentEvent!.luckyMultiplier}! +${_currentEvent!.wonCoins} COINS!"
                          : "COMBO ${_currentEvent!.comboCount}X BURST!",
                      style: const TextStyle(
                        fontSize: 22,
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
        ],
      ),
    );
  }
}
