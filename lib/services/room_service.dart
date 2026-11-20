import 'package:cloud_firestore/cloud_firestore.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _roomsCollection => _firestore.collection('rooms');

  Stream<DocumentSnapshot> getRoomStream(String roomId) {
    return _roomsCollection.doc(roomId).snapshots();
  }

  Future<bool> _checkIsAgent(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final uData = userDoc.data()!;
        if (uData['isAgent'] == true) return true;
        if (uData['isAgency'] == true) return true;
        if (uData['role'] == 'agent') return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> enterMyRoom({
    required String roomId,
    required String roomTitle,
    required String hostUid,
    required String hostName,
  }) async {
    final roomRef = _roomsCollection.doc(roomId);
    final doc = await roomRef.get();
    final bool isAgent = await _checkIsAgent(hostUid);
    final int goldenSeats = isAgent ? 6 : 3;

    if (!doc.exists) {
      final List<dynamic> seatsList = List.filled(30, null);
      seatsList[0] = {
        'uid': hostUid,
        'name': hostName,
        'isMuted': false,
        'isLocked': false,
      };

      await roomRef.set({
        'roomId': roomId,
        'title': roomTitle,
        'hostUid': hostUid,
        'hostName': hostName,
        'isAgentHost': isAgent,
        'goldenSeatCount': goldenSeats,
        'totalSeats': 30,
        'seats': seatsList,
        'isLive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(roomRef);
        final data = snapshot.data() as Map<String, dynamic>;
        List<dynamic> seats = List.from(data['seats'] ?? List.filled(30, null));

        for (int i = 0; i < seats.length; i++) {
          if (seats[i] != null && seats[i]['uid'] == hostUid) {
            seats[i] = null;
          }
        }

        seats[0] = {
          'uid': hostUid,
          'name': hostName,
          'isMuted': false,
          'isLocked': false,
        };

        transaction.update(roomRef, {
          'seats': seats,
          'isLive': true,
          'isAgentHost': isAgent,
          'goldenSeatCount': goldenSeats,
        });
      });
    }
  }

  Future<bool> takeSeat({
    required String roomId,
    required int seatIndex,
    required String uid,
    required String name,
  }) async {
    final roomRef = _roomsCollection.doc(roomId);

    return await _firestore.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return false;

      final data = snapshot.data() as Map<String, dynamic>;
      List<dynamic> seats = List.from(data['seats'] ?? List.filled(30, null));

      if (seats[seatIndex] != null) return false;

      for (int i = 0; i < seats.length; i++) {
        if (seats[i] != null && seats[i]['uid'] == uid) {
          seats[i] = null;
        }
      }

      seats[seatIndex] = {
        'uid': uid,
        'name': name,
        'isMuted': false,
        'isLocked': false,
      };

      transaction.update(roomRef, {'seats': seats});
      return true;
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

Future<void> toggleSeatMute({
    required String roomId,
    required int seatIndex,
    required bool isMuted,
  }) async {
    final roomRef = _roomsCollection.doc(roomId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      List<dynamic> seats = List.from(data['seats'] ?? List.filled(30, null));

      if (seats[seatIndex] != null) {
        seats[seatIndex]['isMuted'] = isMuted;
        transaction.update(roomRef, {'seats': seats});
      }
    });
  }

  Future<void> kickUserFromSeat({
    required String roomId,
    required int seatIndex,
  }) async {
    final roomRef = _roomsCollection.doc(roomId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      List<dynamic> seats = List.from(data['seats'] ?? List.filled(30, null));

      if (seatIndex > 0 && seatIndex < seats.length) {
        seats[seatIndex] = null;
        transaction.update(roomRef, {'seats': seats});
      }
    });
  }

  Future<void> closeRoom(String roomId) async {
    await _roomsCollection.doc(roomId).update({
      'isLive': false,
    });
  }
}
