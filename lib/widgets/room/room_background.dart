import 'package:flutter/material.dart';

class RoomBackground extends StatelessWidget {
  final Widget child;

  const RoomBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF9AA5B8),
                  Color(0xFFC3A5B8),
                  Color(0xFFD3A4B8),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _Room3dCurvedPainter(),
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.15),
          ),
        ),
        SafeArea(
          child: child,
        ),
      ],
    );
  }
}

class _Room3dCurvedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 1.05, size.height * 0.72);

    _drawRibbon(
      canvas: canvas,
      center: center,
      radius: size.width * 0.95,
      strokeWidth: 55,
      gradientColors: const [
        Color(0xFFE8B69B),
        Color(0xFFEAA68C),
      ],
      hasShadow: true,
    );

    _drawRibbon(
      canvas: canvas,
      center: center,
      radius: size.width * 0.76,
      strokeWidth: 55,
      gradientColors: const [
        Color(0xFFE89868),
        Color(0xFFE47B62),
      ],
      hasShadow: true,
    );

    _drawRibbon(
      canvas: canvas,
      center: center,
      radius: size.width * 0.57,
      strokeWidth: 60,
      gradientColors: const [
        Color(0xFFDE6458),
        Color(0xFFCE3858),
      ],
      hasShadow: true,
    );
  }

  void _drawRibbon({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double strokeWidth,
    required List<Color> gradientColors,
    bool hasShadow = false,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (hasShadow) {
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawArc(rect.shift(const Offset(-6, -6)), 3.14 * 0.85, 3.14 * 0.8, false, shadowPaint);
    }

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradientColors,
    );

    final linePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 3.14 * 0.85, 3.1
