class UserModel {
  final String uid;
  final String customId;
  final String name;
  final String avatarUrl;
  final String gender;
  final String phoneNumber;
  final int coins;
  final int diamonds;
  final int wealthLevel;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.customId,
    required this.name,
    required this.avatarUrl,
    this.gender = 'unspecified',
    this.phoneNumber = '',
    this.coins = 0,
    this.diamonds = 0,
    this.wealthLevel = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'customId': customId,
      'name': name,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'coins': coins,
      'diamonds': diamonds,
      'wealthLevel': wealthLevel,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      customId: map['customId'] ?? '',
      name: map['name'] ?? 'User',
      avatarUrl: map['avatarUrl'] ?? '',
      gender: map['gender'] ?? 'unspecified',
      phoneNumber: map['phoneNumber'] ?? '',
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      diamonds: (map['diamonds'] as num?)?.toInt() ?? 0,
      wealthLevel: (map['wealthLevel'] as num?)?.toInt() ?? 1,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
