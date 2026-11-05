import 'package:cloud_firestore/cloud_firestore.dart';

class HostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> recordGiftReceived({
    required String hostUid,
    required int giftDiamonds,
  }) async {
    final hostRef = _firestore.collection('hosts').doc(hostUid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(hostRef);

      if (!snapshot.exists) {
        transaction.set(hostRef, {
          'hostUid': hostUid,
          'agencyId': '',
          'status': 'active',
          'totalDiamonds': giftDiamonds,
          'dailyDiamonds': giftDiamonds,
          'monthlyDiamonds': giftDiamonds,
          'liveDurationMinutesToday': 0,
          'validDaysThisMonth': 0,
          'newFansToday': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final data = snapshot.data() as Map<String, dynamic>;
        final String agencyId = data['agencyId'] ?? '';

        transaction.update(hostRef, {
          'totalDiamonds': FieldValue.increment(giftDiamonds),
          'dailyDiamonds': FieldValue.increment(giftDiamonds),
          'monthlyDiamonds': FieldValue.increment(giftDiamonds),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (agencyId.isNotEmpty) {
          final agencyRef = _firestore.collection('agencies').doc(agencyId);
          final int agencyCommission = (giftDiamonds * 0.10).round();

          transaction.update(agencyRef, {
            'totalAgencyEarnings': FieldValue.increment(agencyCommission),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  Future<void> updateLiveDuration({
    required String hostUid,
    required int minutesSpent,
  }) async {
    final hostRef = _firestore.collection('hosts').doc(hostUid);

    final snapshot = await hostRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final int currentTodayMinutes = (data['liveDurationMinutesToday'] ?? 0) + minutesSpent;
    final int currentValidDays = data['validDaysThisMonth'] ?? 0;

    int updatedValidDays = currentValidDays;
    if (currentTodayMinutes >= 120 && (data['isValidDayMarkedToday'] ?? false) == false) {
      updatedValidDays += 1;
      await hostRef.update({'isValidDayMarkedToday': true});
    }

    await hostRef.update({
      'liveDurationMinutesToday': FieldValue.increment(minutesSpent),
      'validDaysThisMonth': updatedValidDays,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> incrementNewFan(String hostUid) async {
    final hostRef = _firestore.collection('hosts').doc(hostUid);
    await hostRef.update({
      'newFansToday': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
