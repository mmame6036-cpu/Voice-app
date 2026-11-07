import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/story_model.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<UserStoryGroup> storyGroups;
  final int initialGroupIndex;

  const StoryViewerScreen({
    super.key,
    required this.storyGroups,
    this.initialGroupIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _currentGroupIndex;
  int _currentStoryIndex = 0;
  late AnimationController _progressController;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex;

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onNextStory();
      }
    });

    _startCurrentStory();
  }

  void _startCurrentStory() {
    _markStoryAsViewed();
    _progressController.stop();
    _progressController.reset();
    _progressController.forward();
  }

  void _markStoryAsViewed() {
    if (_currentUser == null) return;
    final group = widget.storyGroups[_currentGroupIndex];
    if (_currentStoryIndex >= group.stories.length) return;
    final story = group.stories[_currentStoryIndex];

    if (!story.viewers.contains(_currentUser!.uid)) {
      FirebaseFirestore.instance.collection('stories').doc(story.id).update({
        'viewers': FieldValue.arrayUnion([_currentUser!.uid]),
      }).catchError((_) {});
    }
  }

  void _onNextStory() {
    final group = widget.storyGroups[_currentGroupIndex];
    if (_currentStoryIndex < group.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _startCurrentStory();
    } else {
      if (_currentGroupIndex < widget.storyGroups.length - 1) {
        setState(() {
          _currentGroupIndex++;
          _currentStoryIndex = 0;
        });
        _startCurrentStory();
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _onPreviousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _startCurrentStory();
    } else {
      if (_currentGroupIndex > 0) {
        setState(() {
          _currentGroupIndex--;
          _currentStoryIndex = widget.storyGroups[_currentGroupIndex].stories.length - 1;
        });
        _startCurrentStory();
      } else {
        _startCurrentStory();
      }
    }
  }

  void _pauseStory() {
    if (!_isPaused) {
      setState(() => _isPaused = true);
      _progressController.stop();
    }
  }

  void _resumeStory() {
    if (_isPaused) {
      setState(() => _isPaused = false);
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentGroupIndex >= widget.storyGroups.length) {
      return const SizedBox.shrink();
    }

    final group = widget.storyGroups[_currentGroupIndex];
    final story = group.stories[_currentStoryIndex];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onLongPressStart: (_) => _pauseStory(),
          onLongPressEnd: (_) => _resumeStory(),
          onTapUp: (details) {
            final screenWidth = size.width;
            final tapX = details.globalPosition.dx;

if (tapX < screenWidth * 0.3) {
              _onPreviousStory();
            } else {
              _onNextStory();
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Image.network(
                  story.mediaUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFFD700)),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white24, size: 64),
                  ),
                ),
              ),

              if (story.caption.isNotEmpty)
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      story.caption,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Column(
                  children: [
                    Row(
                      children: List.generate(group.stories.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                double value = 0.0;
                                if (index < _currentStoryIndex) {
                                  value = 1.0;
                                } else if (index == _currentStoryIndex) {
                                  value = _progressController.value;
                                }
                                return LinearProgressIndicator(
                                  value: value,
                                  backgroundColor: Colors.white24,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFFD700),
                                  ),
                                  minHeight: 2.5,
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1E1738),
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(

child: Text(
                            group.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
