import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auction_model.dart';
import '../services/notification_service.dart';

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
  /// Listen for outbids on auctions the user has bid on
  Stream<Map<String, dynamic>> listenForOutbids(String userId) {
    return supabase
        .from('bids')
        .stream(primaryKey: ['id'])
        .eq('previous_highest_bidder_id', userId)
        .map((snapshot) {
          if (snapshot.isNotEmpty) {
            for (final bid in snapshot) {
              _handleOutbid(bid, userId);
            }
          }
          return {'outbid': snapshot.isNotEmpty};
        });
  }
  /// Handle outbid notification
  Future<void> _handleOutbid(Map<String, dynamic> bid, String userId) async {
    try {
      // Get auction details
      final auction = await supabase
          .from('auctions')
          .select()
          .eq('id', bid['auction_id'])
          .maybeSingle();
      
      if (auction != null) {
        // Show notification to the outbid user
        final notificationService = NotificationService();
        await notificationService.showOutbidNotification(
          auction['title'], 
          (bid['amount'] as num).toDouble()
        );
        
        log("📣 Outbid notification sent to $userId");
      }
    } catch (e, stackTrace) {
      log("❌ Error handling outbid: $e", error: e, stackTrace: stackTrace);
    }
  }

  /// Enhanced placeBid method to track previous highest bidder for outbid notifications
  Future<void> placeBid(String auctionId, double bidAmount, String bidderId) async {
    try {
      final auction = await supabase
          .from('auctions')
          .select()
          .eq('id', auctionId)
          .maybeSingle();

      if (auction == null) {
        throw Exception("Auction does not exist!");
      }

      String sellerId = auction['seller_id'];
      if (sellerId == bidderId) {
        throw Exception("Sellers cannot bid on their own auctions!");
      }

      double currentHighestBid = (auction['highest_bid'] as num?)?.toDouble() ?? 
                               (auction['starting_price'] as num).toDouble();
      String? previousHighestBidderId = auction['highest_bidder_id'];

      if (bidAmount > currentHighestBid) {
        // Store bid with reference to the previous highest bidder
        await supabase.from('bids').insert({
          'auction_id': auctionId,
          'bidder_id': bidderId,
          'amount': bidAmount,
          'previous_highest_bidder_id': previousHighestBidderId,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Update auction with new highest bid
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
      rethrow;
    }
  }

  /// Check for auctions ending soon (within 5 minutes) and send notifications
  Future<void> checkEndingSoonAuctions() async {
    try {
      final now = DateTime.now();
      final fiveMinutesFromNow = now.add(const Duration(minutes: 5));
      
      final auctions = await supabase
          .from('auctions')
          .select()
          .gt('end_time', now.toIso8601String())
          .lt('end_time', fiveMinutesFromNow.toIso8601String())
          .eq('ending_notified', false);
      
      for (final auction in auctions) {
        // Get users who have bid on this auction
        final bids = await supabase
            .from('bids')
            .select('bidder_id')
            .eq('auction_id', auction['id'])
            .filter('bidder_id', 'neq', auction['seller_id']);
        
        // Get unique bidders
        final Set<String> bidders = {};
        for (final bid in bids) {
          bidders.add(bid['bidder_id']);
        }
        
        // Send notification to all bidders
        final notificationService = NotificationService();
        for (final bidderId in bidders) {
          await notificationService.showAuctionEndingNotification(auction['title']);
        }
        
        // Mark auction as notified
        await supabase
            .from('auctions')
            .update({'ending_notified': true})
            .eq('id', auction['id']);
        
        log("📣 Ending soon notifications sent for auction: ${auction['id']}");
      }
    } catch (e, stackTrace) {
      log("❌ Error checking ending soon auctions: $e", error: e, stackTrace: stackTrace);
    }
  }

  /// Check for ended auctions and notify winners
  Future<void> checkEndedAuctions() async {
    try {
      final now = DateTime.now();
      
      final auctions = await supabase
          .from('auctions')
          .select()
          .lt('end_time', now.toIso8601String())
          .eq('is_active', true);
      
      for (final auction in auctions) {
        // Deactivate the auction
        await supabase
            .from('auctions')
            .update({'is_active': false})
            .eq('id', auction['id']);
        
        // If there's a highest bidder, notify them
        if (auction['highest_bidder_id'] != null) {
          final notificationService = NotificationService();
          await notificationService.showAuctionWonNotification(auction['title']);
          
          log("📣 Auction won notification sent to: ${auction['highest_bidder_id']}");
        }
      }
    } catch (e, stackTrace) {
      log("❌ Error checking ended auctions: $e", error: e, stackTrace: stackTrace);
    }
  }
}

