import 'package:cloud_firestore/cloud_firestore.dart';

class UserIdService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ተጠቃሚ ሲገባ ወይም ሲመዘገብ ቋሚ 6 ዲጂት ID (ከ 100001 ጀምሮ) ይሰጣል
  static Future<int> getOrCreatePermanentId(String userUid, {String? defaultName}) async {
    final userDocRef = _firestore.collection('users').doc(userUid);
    final userSnapshot = await userDocRef.get();

    if (userSnapshot.exists && userSnapshot.data()!.containsKey('numericId')) {
      return (userSnapshot.data()!['numericId'] as num).toInt();
    }

    // አዲስ ተጠቃሚ ከሆነ ቆጣሪውን በ 1 ከፍ በማድረግ ቋሚ ID እንሰጠዋለን
    final counterRef = _firestore.collection('app_settings').doc('user_id_counter');

    return await _firestore.runTransaction<int>((transaction) async {
      final counterSnapshot = await transaction.get(counterRef);
      int nextId = 100001;

      if (counterSnapshot.exists && counterSnapshot.data()!.containsKey('lastId')) {
        nextId = (counterSnapshot.data()!['lastId'] as int) + 1;
      }

      transaction.set(counterRef, {'lastId': nextId}, SetOptions(merge: true));
      transaction.set(userDocRef, {
        'numericId': nextId,
        'uid': userUid,
        'name': defaultName ?? "User $nextId",
        'coins': 2500,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return nextId;
    });
  }
}
