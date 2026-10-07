import 'package:flutter/material.dart';

class HomeAuraBackground extends StatefulWidget {
  final Widget child;
  const HomeAuraBackground({Key? key, required this.child}) : super(key: key);

  @override
  State<HomeAuraBackground> createState() => _HomeAuraBackgroundState();
}

class _HomeAuraBackgroundState extends State<HomeAuraBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -0.7, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0F051C), // ጥልቅ ወይንጠጅ መነሻ
            gradient: RadialGradient(
              center: Alignment(_animation.value, -1.0), // ከላይ ወደ ግራና ቀኝ የሚወዛወዘው ብርሃን
              radius: 1.3,
              colors: const [
                Color(0xFF00FF87), // የሚያበራው ኒዮን አረንጓዴ ላይት
                Color(0xFF07382B), // ከለስላሳው አረንጓዴ ጋር የሚዋሃድ
                Color(0xFF240D36), // ዋናው ማራኪ ወይንጠጅ
                Color(0xFF0A0214), // ከስር የሚያርፈው ጠቆር ያለ ክፍል
              ],
              stops: const [0.0, 0.25, 0.65, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
