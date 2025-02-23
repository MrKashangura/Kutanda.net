import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auction_model.dart';

final supabase = Supabase.instance.client;

class AuctionService {
  /// Create an auction
  Future<void> createAuction(Auction auction) async {
    try {
      await supabase.from('auctions').insert(auction.toMap());
      log("✅ Auction Created: ${auction.id}");
    } catch (e, stackTrace) {
      log("❌ Error Creating Auction: $e", error: e, stackTrace: stackTrace);
    }
  }

 /// Get all auctions (Real-time updates)
Stream<List<Auction>> getAllAuctions() {
  return supabase
      .from('auctions')
      .stream(primaryKey: ['id'])
      .map((snapshot) => snapshot.map((data) => Auction.fromMap(data)).toList()); // ✅ FIXED: Pass only `data`
}


  /// Get active auctions
  Stream<List<Auction>> getActiveAuctions() {
    return supabase
        .from('auctions')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .map((snapshot) => snapshot.map((data) => Auction.fromMap(data)).toList());
  }

  /// Get auctions for a specific seller
  Stream<List<Auction>> getSellerAuctions(String sellerId) {
    return supabase
        .from('auctions')
        .stream(primaryKey: ['id'])
        .eq('seller_id', sellerId) // ✅ Fixed incorrect field name
        .map((snapshot) => snapshot.map((data) => Auction.fromMap(data)).toList());
  }

  /// Update an auction
  Future<void> updateAuction(Auction auction) async {
    try {
      await supabase.from('auctions').update(auction.toMap()).eq('id', auction.id);
      log("✅ Auction Updated: ${auction.id}");
    } catch (e, stackTrace) {
      log("❌ Error Updating Auction: $e", error: e, stackTrace: stackTrace);
    }
  }

  /// Delete an auction
  Future<void> deleteAuction(String auctionId) async {
    try {
      await supabase.from('auctions').delete().eq('id', auctionId);
      log("✅ Auction Deleted: $auctionId");
    } catch (e, stackTrace) {
      log("❌ Error Deleting Auction: $e", error: e, stackTrace: stackTrace);
    }
  }

  /// Place a bid (Real-time bidding)
  Future<void> placeBid(String auctionId, double bidAmount, String bidderId) async {
    try {
      final auction = await supabase
          .from('auctions')
          .select()
          .eq('id', auctionId)
          .maybeSingle(); // ✅ Fixed: Use `.maybeSingle()`

      if (auction == null) {
        throw Exception("Auction does not exist!");
      }

      String sellerId = auction['seller_id'];
      if (sellerId == bidderId) {
        throw Exception("Sellers cannot bid on their own auctions!");
      }

      double currentHighestBid = (auction['highest_bid'] as num?)?.toDouble() ?? 
                                  (auction['starting_price'] as num).toDouble();

      if (bidAmount > currentHighestBid) {
        await supabase.from('bids').insert({
          'auction_id': auctionId,
          'bidder_id': bidderId,
          'amount': bidAmount,
          'created_at': DateTime.now().toIso8601String(),
        });

        await supabase.from('auctions').update({
          'highest_bid': bidAmount,
          'highest_bidder_id': bidderId,
        }).eq('id', auctionId);

        log("✅ Bid Placed: $bidAmount by $bidderId");
      } else {
        throw Exception("Bid must be higher than the current highest bid!");
      }
    } catch (e, stackTrace) {
      log("❌ Error Placing Bid: $e", error: e, stackTrace: stackTrace);
    }
  }

  /// Real-time updates for bids on a specific auction
  Stream<List<Map<String, dynamic>>> listenToBids(String auctionId) {
    return supabase
        .from('bids')
        .stream(primaryKey: ['id'])
        .eq('auction_id', auctionId)
        .map((snapshot) => snapshot.toList());
  }
}

