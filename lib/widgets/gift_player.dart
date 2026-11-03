import 'package:flutter/material.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';

class GiftPlayer extends StatefulWidget {
  final String url; // የስጦታው SVGA ሊንክ
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
  SVGAAnimationController? _animationController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = SVGAAnimationController(vsync: this);
    _playAnimation();
  }

  Future<void> _playAnimation() async {
    try {
      final videoItem = await SVGAParser.shared.decodeFromURL(widget.url);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (_animationController != null) {
        _animationController!.videoItem = videoItem;
        _animationController!
          ..reset()
          ..forward().whenComplete(() {
            if (mounted) {
              widget.onFinished();
            }
          });
      }
    } catch (e) {
      // ኔትወርክ ወይም ሊንኩ ቢሳሳት አፑ እንዳይቆም ወዲያውኑ ይጠፋል
      if (mounted) {
        widget.onFinished();
      }
    }
  }

  @override
  void dispose() {
    _animationController?.stop();
    _animationController?.dispose();
    _animationController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _animationController == null) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      ignoring: true, // ስጦታው ሲንቀሳቀስ የስክሪኑ ንክኪ እንዳይዘጋ
      child: SizedBox.expand(
        child: SVGAImage(
          _animationController!,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
