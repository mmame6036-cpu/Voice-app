import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class WheelReward {
  final String name;
  final String icon;
  final int coins;
  final Color color;

  const WheelReward({
    required this.name,
    required this.icon,
    required this.coins,
    required this.color,
  });
}

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
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentAngle = 0;
  bool _isSpinning = false;
  static const int spinCost = 50;

  final List<WheelReward> _rewards = const [
    WheelReward(name: "Rose", icon: "🌹", coins: 20, color: Color(0xFFE91E63)),
    WheelReward(name: "Bronze Bag", icon: "💰", coins: 50, color: Color(0xFFFF9800)),
    WheelReward(name: "Super Car", icon: "🏎️", coins: 300, color: Color(0xFF9C27B0)),
    WheelReward(name: "Silver Crown", icon: "👑", coins: 150, color: Color(0xFF2196F3)),
    WheelReward(name: "Rocket", icon: "🚀", coins: 500, color: Color(0xFFE53935)),
    WheelReward(name: "Gold Chest", icon: "🎁", coins: 1000, color: Color(0xFFFFD700)),
  ];

  @override
  void initState() {
    super.initState();
    _coins = widget.currentCoins;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
  }

  void _spin() {
    if (_isSpinning) return;
    if (_coins < spinCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient coins to spin!")),
      );
      return;
    }

    setState(() {
      _isSpinning = true;
      _coins -= spinCost;
    });
    widget.onCoinsUpdated(_coins);

    final random = Random();
    final winningIndex = random.nextInt(_rewards.length);
    final sectorAngle = (2 * pi) / _rewards.length;
    final targetAngle = (4 * 2 * pi) + (winningIndex * sectorAngle) + (sectorAngle / 2);

    _animation = Tween<double>(begin: _currentAngle, end: _currentAngle + targetAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCirc),
    )..addListener(() {
        setState(() {
          _currentAngle = _animation.value % (2 * pi);
        });
      });

    _controller.reset();
    _controller.forward().then((_) {
      final reward = _rewards[winningIndex];
      setState(() {
        _isSpinning = false;
        _coins += reward.coins;
      });
      widget.onCoinsUpdated(_coins);
      _showWinDialog(reward);
    });
  }

  void _showWinDialog(WheelReward reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Congratulations!",
          style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(reward.icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            Text(
              "You won ${reward.name}!",
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "+${reward.coins} Coins",
              style: const TextStyle(color: Color(0xFFFFD700), fontSize: 15, fontWeight: FontWeight.bold),

),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text("Claim", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 520,
      decoration: const BoxDecoration(
        color: Color(0xFF141226),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Lucky Spin Wheel",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    "$_coins",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: _currentAngle,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFD700), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.3),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _WheelPainter(rewards: _rewards),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 10,
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFFFFD700),
                      size: 40,
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1B38),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black45, blurRadius: 6),
                      ],
                    ),
                    child: const Center(

child: Text("🎰", style: TextStyle(fontSize: 22)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: _isSpinning ? null : _spin,
              child: Text(
                _isSpinning ? "Spinning..." : "Spin ($spinCost Coins)",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<WheelReward> rewards;

  _WheelPainter({required this.rewards});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * pi) / rewards.length;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < rewards.length; i++) {
      paint.color = rewards[i].color.withOpacity(0.85);
      final startAngle = i * sweepAngle;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      final textAngle = startAngle + sweepAngle / 2;
      final textRadius = radius * 0.65;
      final textOffset = Offset(
        center.dx + textRadius * cos(textAngle),
        center.dy + textRadius * sin(textAngle),
      );

      final textSpan = TextSpan(
        text: rewards[i].icon,
        style: const TextStyle(fontSize: 22),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(textOffset.dx - textPainter.width / 2, textOffset.dy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
