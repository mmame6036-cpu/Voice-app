import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/story_model.dart';

class StoryTrayWidget extends StatelessWidget {
  final VoidCallback onAddStoryTap;
  final Function(UserStoryGroup storyGroup) onStoryGroupTap;

  const StoryTrayWidget({
    super.key,
    required this.onAddStoryTap,
    required this.onStoryGroupTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();

    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
            .snapshots(),
        builder: (context, snapshot) {
          // ስቶሪዎችን በሰው በሰው (userId) መቧደን
          final Map<String, List<StoryItem>> groupedStories = {};

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final story = StoryItem.fromFirestore(doc);
              groupedStories.putIfAbsent(story.userId, () => []).add(story);
            }
          }

          final storyGroups = groupedStories.entries.map((entry) {
            final firstStory = entry.value.first;
            final hasUnseen = currentUser == null
                ? true
                : entry.value.any((s) => !s.viewers.contains(currentUser.uid));

            return UserStoryGroup(
              userId: entry.key,
              userName: firstStory.userId == currentUser?.uid ? "Your Story" : "User",
              userAvatar: "",
              stories: entry.value,
              hasUnseen: hasUnseen,
            );
          }).toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: storyGroups.length + 1, // 1 ለራስህ + አዝራር
            itemBuilder: (context, index) {
              // የመጀመሪያው አዝራር የራስህ ስቶሪ መጨመሪያ ነው
              if (index == 0) {
                return _buildAddStoryButton(currentUser);
              }

              final group = storyGroups[index - 1];
              return _buildUserStoryItem(group);
            },
          );
        },
      ),
    );
  }

  Widget _buildAddStoryButton(User? user) {
    return GestureDetector(
      onTap: onAddStoryTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E1738),
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white.withOpacity(0.6),
                      size: 32,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFD700),
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Add Story",
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildUserStoryItem(UserStoryGroup group) {
    return GestureDetector(
      onTap: () => onStoryGroupTap(group),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: group.hasUnseen
                    ? const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFF2A85), Color(0xFF00E5FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: group.hasUnseen ? null : Colors.white24,
              ),
              child: Container(
                width: 55,
                height: 55,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF130F26),
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    color: Colors.white.withOpacity(0.85),
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 60,
              child: Text(
                group.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
