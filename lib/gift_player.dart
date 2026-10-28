import 'package:flutter/material.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';

class GiftPlayer extends StatefulWidget {
  final String url; // የስጦታው የኦንላይን SVGA ሊንክ
  final VoidCallback onFinished; // አኒሜሽኑ ሲያልቅ የሚጠራ

  const GiftPlayer({
    super.key,
    required this.url,
    required this.onFinished,
  });

  @override
  State<GiftPlayer> createState() => _GiftPlayerState();
}

class _GiftPlayerState extends State<GiftPlayer>
    with SingleTickerProviderStateMixin {
  late SVGAAnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = SVGAAnimationController(vsync: this);
    _playAnimation();
  }

  Future<void> _playAnimation() async {
    try {
      final videoItem = await SVGAParser.shared.decodeFromURL(widget.url);
      if (mounted) {
        _animationController.videoItem = videoItem;
        _animationController
          ..reset()
          ..forward().whenComplete(() {
            widget.onFinished();
          });
      }
    } catch (e) {
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: SVGAImage(_animationController),
      ),
    );
  }
}
