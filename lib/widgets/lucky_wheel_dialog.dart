import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class LuckyWheelDialog extends StatefulWidget {
  final int currentCoins;
  final Function(int) onCoinsUpdated;

  const LuckyWheelDialog({
    super.key,
    required this.currentCoins,
    required this.onCoinsUpdated,
  });

  @override
  State<LuckyWheelDialog> createState() => _LuckyWheelDialogState();
}

class _LuckyWheelDialogState extends State<LuckyWheelDialog>
    with SingleTickerProviderStateMixin {
  late int _coins;
  late AnimationController _animController;
  late Animation<double> _animation;

  double _currentAngle = 0.0;
  bool _isSpinning = false;
  String _resultText = "Spin to win up to 5,000 Coins!";
  final int _spinCost = 100;

  // 8 Wheel Sectors & Rewards
  final List<int> _rewards = [0, 50, 200, 500, 50, 1000, 100, 5000];
  final List<Color> _sectorColors = [
    const Color(0xFF6C5CE7),
    const Color(0xFFFF7675),
    const Color(0xFF00CEC9),
    const Color(0xFFFDCB6E),
    const Color(0xFF0984E3),
    const Color(0xFFE84393),
    const Color(0xFF00B894),
    const Color(0xFFFFD700),
  ];

  @override
  void initState() {
    super.initState();
    _coins = widget.currentCoins;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
  }

  void _spin() {
    if (_isSpinning) return;
    if (_coins < _spinCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient coins! (Cost: 🪙100)")),
      );
      return;
    }

    setState(() {
      _coins -= _spinCost;
      _isSpinning = true;
      _resultText = "Spinning...";
    });
    widget.onCoinsUpdated(_coins);

    // Random target index (0 to 7)
    final rng = Random();
    final targetIdx = rng.nextInt(_rewards.length);

    // Sector angle = 2 * PI / 8
    const double sectorAngle = (2 * pi) / 8;

    // Calculate final stop angle with at least 5 full rotations
    final double fullRotations = (5 + rng.nextInt(3)) * 2 * pi;
    final double targetSectorOffset = (targetIdx * sectorAngle) + (sectorAngle / 2);
    final double targetAngle = _currentAngle + fullRotations + (2 * pi - (_currentAngle % (2 * pi))) + targetSectorOffset;

    _animation = Tween<double>(begin: _currentAngle, end: targetAngle).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _currentAngle = _animation.value;
        });
      });

    _animController.forward(from: 0.0).then((_) {
      final reward = _rewards[targetIdx];
      setState(() {
        _isSpinning = false;
        if (reward > 0) {
          _coins += reward;
          _resultText = "🎉 Congratulations! You won 🪙$reward!";
        } else {
          _resultText = "Better luck next time!";
        }
      });
      widget.onCoinsUpdated(_coins);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 520,
      decoration: const BoxDecoration(
        color: Color(0xFF141226),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "🎰 Lucky Spin Wheel",
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 17, fontWeight: FontWeight.bold),

),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD700), width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 14),
                    const SizedBox(width: 4),
                    Text("$_coins", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _resultText,
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          // Wheel Stack
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating Wheel
                  Transform.rotate(
                    angle: _currentAngle,
                    child: CustomPaint(
                      size: const Size(260, 260),
                      painter: WheelPainter(rewards: _rewards, colors: _sectorColors),
                    ),
                  ),
                  // Outer Frame
                  Container(
                    width: 270,
                    height: 270,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFD700), width: 4),
                    ),
                  ),
                  // Top Pointer
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 18,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_downward, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                  // Center Button
                  GestureDetector(
                    onTap: _spin,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isSpinning ? Colors.grey : const Color(0xFFFFD700),
                        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          _isSpinning ? "WAIT" : "SPIN\n🪙100",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Text(
            "Each spin costs 🪙$_spinCost Coins. Good luck!",
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<int> rewards;
  final List<Color> colors;

  WheelPainter({required this.rewards, required this.colors});

@override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final int count = rewards.length;
    final double sweepAngle = (2 * pi) / count;

    for (int i = 0; i < count; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      final startAngle = i * sweepAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw Reward Text
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + (sweepAngle / 2));

      final textSpan = TextSpan(
        text: rewards[i] == 0 ? "TRY" : "🪙${rewards[i]}",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(radius * 0.45, -textPainter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
