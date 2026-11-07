import 'package:cloud_firestore/cloud_firestore.dart';

class UserStoryGroup {
  final String userId;
  final String userName;
  final String userAvatar;
  final List<StoryItem> stories;
  final bool hasUnseen;

  UserStoryGroup({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.stories,
    this.hasUnseen = true,
  });
}

class StoryItem {
  final String id;
  final String userId;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final String caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewers;

  StoryItem({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    required this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.viewers,
  });

  factory StoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoryItem(
      id: doc.id,
      userId: data['userId'] ?? '',
      mediaUrl: data['mediaUrl'] ?? '',
      mediaType: data['mediaType'] ?? 'image',
      caption: data['caption'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 24)),
      viewers: List<String>.from(data['viewers'] ?? []),
    );
  }
}
