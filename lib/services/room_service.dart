import 'package:cloud_firestore/cloud_firestore.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _roomsCollection => _firestore.collection('rooms');

  Stream<DocumentSnapshot> getRoomStream(String roomId) {
    return _roomsCollection.doc(roomId).snapshots();
  }

  Future<void> initializeRoom({
    required String roomId,
    required String roomTitle,
    required String hostUid,
    required String hostName,
  }) async {
    final doc = await _roomsCollection.doc(roomId).get();
    if (!doc.exists) {
      final List<dynamic> seatsList = List.filled(30, null);
      seatsList[0] = {
        'uid': hostUid,
        'name': hostName,
        'isMuted': false,
      };

      await _roomsCollection.doc(roomId).set({
        'roomId': roomId,
        'title': roomTitle,
        'hostUid': hostUid,
        'hostName': hostName,
        'totalSeats': 30,
        'seats': seatsList,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> takeSeat({
    required String roomId,
    required int seatIndex,
    required String uid,
    required String name,
  }) async {
    final roomRef = _roomsCollection.doc(roomId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      List<dynamic> seats = List.from(data['seats'] ?? List.filled(30, null));

      for (int i = 0; i < seats.length; i++) {
        if (seats[i] != null && seats[i]['uid'] == uid) {
          seats[i] = null;
        }
      }

      if (seatIndex < seats.length && seats[seatIndex] == null) {
        seats[seatIndex] = {
          'uid': uid,
          'name': name,
          'isMuted': false,
        };
        transaction.update(roomRef, {'seats': seats});
      }
    });
  }

  Future<void> leaveSeat({
    required String roomId,
    required String uid,
  }) async {
    final roomRef = _roomsCollection.doc(roomId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      List<dynamic> seats = List.from(data['seats'] ?? List.filled(30, null));

      for (int i = 0; i < seats.length; i++) {
        if (seats[i] != null && seats[i]['uid'] == uid) {
          seats[i] = null;
        }
      }

      transaction.update(roomRef, {'seats': seats});
    });
  }
}
