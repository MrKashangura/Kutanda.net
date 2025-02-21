import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/auction_model.dart';

class AuctionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createAuction(Auction auction) async {
    try {
      await _firestore.collection('auctions').doc(auction.id).set(auction.toMap());
      log("✅ Auction Created: ${auction.id}");
    } catch (e, stackTrace) {
      log("❌ Error Creating Auction: $e", error: e, stackTrace: stackTrace);
    }
  }

  Stream<List<Auction>> getAllAuctions() {
    return _firestore.collection('auctions').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Auction.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<Auction>> getActiveAuctions() {
    return _firestore
        .collection('auctions')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Auction.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<Auction>> getSellerAuctions(String sellerId) {
    return _firestore
        .collection('auctions')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Auction.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> updateAuction(Auction auction) async {
    try {
      await _firestore.collection('auctions').doc(auction.id).update(auction.toMap());
      log("✅ Auction Updated: ${auction.id}");
    } catch (e, stackTrace) {
      log("❌ Error Updating Auction: $e", error: e, stackTrace: stackTrace);
    }
  }

  Future<void> deleteAuction(String auctionId) async {
    try {
      await _firestore.collection('auctions').doc(auctionId).delete();
      log("✅ Auction Deleted: $auctionId");
    } catch (e, stackTrace) {
      log("❌ Error Deleting Auction: $e", error: e, stackTrace: stackTrace);
    }
  }

  Future<void> placeBid(String auctionId, double bidAmount, String bidderId) async {
    try {
      DocumentReference auctionRef = _firestore.collection('auctions').doc(auctionId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot auctionSnapshot = await transaction.get(auctionRef);

        if (!auctionSnapshot.exists) {
          throw Exception("Auction does not exist!");
        }

        String sellerId = auctionSnapshot['sellerId'];
        if (sellerId == bidderId) {
          throw Exception("Sellers cannot bid on their own auctions!");
        }

        double currentHighestBid = (auctionSnapshot['highestBid'] as num?)?.toDouble() 
          ?? (auctionSnapshot['startingPrice'] as num).toDouble();

        if (bidAmount > currentHighestBid) {
          transaction.update(auctionRef, {
            'highestBid': bidAmount,
            'highestBidderId': bidderId,
          });
          log("✅ Bid Placed: $bidAmount by $bidderId");
        } else {
          throw Exception("Bid must be higher than the current highest bid!");
        }
      });
    } on FirebaseException catch (e) {
      log("❌ Firebase Error Placing Bid: ${e.message}", error: e);
    } catch (e, stackTrace) {
      log("❌ Unexpected Error Placing Bid: $e", error: e, stackTrace: stackTrace);
    }
  }
}
