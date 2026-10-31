import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  String _generateCustomId() {
    final random = Random();
    return '${random.nextInt(900000) + 100000}';
  }

  Future<UserModel> saveNewUser({
    required String uid,
    required String name,
    required String avatarUrl,
    String gender = 'unspecified',
    String phoneNumber = '',
  }) async {
    final userDoc = await _usersCollection.doc(uid).get();

    if (userDoc.exists && userDoc.data() != null) {
      return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
    }

    final newUser = UserModel(
      uid: uid,
      customId: _generateCustomId(),
      name: name,
      avatarUrl: avatarUrl,
      gender: gender,
      phoneNumber: phoneNumber,
      coins: 0,
      diamonds: 0,
      wealthLevel: 1,
      createdAt: DateTime.now(),
    );

    await _usersCollection.doc(uid).set(newUser.toMap());
    return newUser;
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
}
