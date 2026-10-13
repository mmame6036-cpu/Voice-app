import 'package:flutter/material.dart';

class RoomBackground extends StatelessWidget {
  final Widget child;

  const RoomBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. መነሻ ለስላሳ ፓስቴል የሰማይ ቀለም (Soft Sky Gradient)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF9AA5B8), // የላይኛው ለስላሳ ሰማያዊ-ግራጫ
                    Color(0xFFC3A5B8), // መሃል ላይ ወደ ለስላሳ ሮዝ የሚቀየር
                    Color(0xFFD3A4B8), // የታችኛው ክፍል
                  ],
                ),
              ),
            ),
          ),

          // 2. ተደራራቢ የ3D ቅስቶች (Layered 3D Bubble Arches with Gradients & Shadows)
          Positioned.fill(
            child: CustomPaint(
              painter: _Room3dCurvedPainter(),
            ),
          ),

          // 3. ወንበሮቹና ጽሁፎቹ በደንብ ጎልተው እንዲታዩ የሚያደርግ ለስላሳ ተደራቢ
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.15),
            ),
          ),

          // 4. ዋናው የክፍሉ ይዘት (Seats, Chat, Header ወዘተ)
          SafeArea(
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Room3dCurvedPainter extends CustomPainter {
  @override
  void Paint(Canvas canvas, Size size) {
    // የቀለበት ማዕከል እና ራዲየስ
    final center = Offset(size.width * 1.05, size.height * 0.72);

    // 1ኛ ውጫዊ ደመናማ ሽፋን (Light Pastel Peach)
    _drawCurvedRibbon(
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

    // 2ኛ መካከለኛ ሽፋን (Warm Peach-Orange 3D)
    _drawCurvedRibbon(
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

    // 3ኛ የውስጠኛው ደማቅ ሽፋን (Vibrant Coral Red / Pink 3D)
    _drawCurvedRibbon(
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

  void _drawCurvedRibbon({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double strokeWidth,
    required List<Color> gradientColors,
    bool hasShadow = false,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    // የ 3D ጥልቀት የሚሰጥ ጥላ (Shadow)
    if (hasShadow) {
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawArc(rect.shift(const Offset(-6, -6)), 3.14 * 0.85, 3.14 * 0.8, false, shadowPaint);
    }

    // የ 3D ቅስት ቀለም (Linear Gradient)
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradientColors,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 3.14 * 0.85, 3.14 * 0.8, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
