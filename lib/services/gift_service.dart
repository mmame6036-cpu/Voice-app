import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gift_model.dart';

class GiftSendResult {
  final bool success;
  final String message;
  final int diamondsSent;
  final int wonCoins;
  final int multiplier;

  GiftSendResult({
    required this.success,
    required this.message,
    this.diamondsSent = 0,
    this.wonCoins = 0,
    this.multiplier = 0,
  });
}

class GiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  /// የ Lucky ስጦታ ሲሆን ዕድል የማስላት ስልት
  int _calculateLuckyMultiplier() {
    int roll = _random.nextInt(1000) + 1; // ከ 1 እስከ 1000

    if (roll <= 2) return 500;   // 0.2% እድል -> x500
    if (roll <= 10) return 100;  // 0.8% እድል -> x100
    if (roll <= 30) return 50;   // 2.0% እድል -> x50
    if (roll <= 90) return 10;   // 6.0% እድል -> x10
    if (roll <= 210) return 5;   // 12.0% እድል -> x5

    return 0; // ካልፈነዳለት
  }

  Future<GiftSendResult> sendGift({
    required String senderId,
    required String receiverId,
    required String roomId,
    required GiftItem gift,
    int count = 1,
  }) async {
    final int totalCoinCost = gift.price * count;
    // Lucky ከሆነ 4% (0.04)፤ ሌሎች ከሆኑ 70% (0.70)
    final int hostDiamonds = (totalCoinCost * gift.diamondRate).round();

    int wonMultiplier = 0;
    int totalWonCoins = 0;

    // ስጦታው Lucky ከሆነ ለእያንዳንዱ ስጦታ ዕድል ይታሰባል
    if (gift.isLucky) {
      for (int i = 0; i < count; i++) {
        int mult = _calculateLuckyMultiplier();
        if (mult > 0) {
          wonMultiplier = max(wonMultiplier, mult);
          totalWonCoins += gift.price * mult;
        }
      }
    }

    final DocumentReference senderRef = _firestore.collection('users').doc(senderId);
    final DocumentReference receiverRef = _firestore.collection('users').doc(receiverId);
    final DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);

    try {
      await _firestore.runTransaction((transaction) async {
        final DocumentSnapshot senderSnap = await transaction.get(senderRef);

        if (!senderSnap.exists) {
          throw Exception("ተጠቃሚው አልተገኘም");
        }

        final int senderCoins = (senderSnap.get('coins') ?? 0) as int;

        if (senderCoins < totalCoinCost) {
          throw Exception("በቂ ሳንቲም (Coins) የለዎትም!");
        }

        // 1. ከላኪው ሳንቲም መቀነስ እና ያሸነፈው ካለ መደመር
        final int netCoinChange = -totalCoinCost + totalWonCoins;
        transaction.update(senderRef, {
          'coins': FieldValue.increment(netCoinChange),
        });

        // 2. ለተቀባዩ (Host) በተመኑ መሰረት ዳይመንድ መጨመር
        transaction.update(receiverRef, {
          'diamonds': FieldValue.increment(hostDiamonds),
        });

        // 3. በሩም መልእክቶች ውስጥ የስጦታውን መዝገብ ማስቀመጥ
        final DocumentReference messageRef = roomRef.collection('messages').doc();
        transaction.set(messageRef, {
          'type': 'gift',
          'senderId': senderId,
          'receiverId': receiverId,
          'giftId': gift.id,
          'giftName': gift.name,
          'giftIcon': gift.icon,
          'count': count,
          'isLucky': gift.isLucky,
          'wonCoins': totalWonCoins,
          'multiplier': wonMultiplier,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      return GiftSendResult(
        success: true,
        message: "ስጦታው በተሳካ ሁኔታ ተልኳል",
        diamondsSent: hostDiamonds,
        wonCoins: totalWonCoins,
        multiplier: wonMultiplier,
      );
    } catch (e) {
      return GiftSendResult(
        success: false,
        message: e.toString().replaceAll("Exception: ", ""),
      );
    }
  }
}
