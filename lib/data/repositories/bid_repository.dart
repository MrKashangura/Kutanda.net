// lib/data/repositories/bid_repository.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

class BidRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Place a bid on an auction
  Future<bool> placeBid(String auctionId, double bidAmount, String bidderId) async {
    try {
      // First, check if the auction exists and get current highest bid
      final auction = await _supabase
          .from('auctions')
          .select('highest_bid, highest_bidder_id, seller_id, is_active, bid_increment')
          .eq('id', auctionId)
          .maybeSingle();
      
      if (auction == null) {
        throw Exception('Auction not found');
      }
      
      // Check if auction is still active
      if (auction['is_active'] != true) {
        throw Exception('Auction is no longer active');
      }
      
      // Check if seller is trying to bid on their own auction
      if (auction['seller_id'] == bidderId) {
        throw Exception('Sellers cannot bid on their own auctions');
      }
      
      // Check if bid is higher than current highest bid
      final currentHighestBid = (auction['highest_bid'] as num).toDouble();
      final bidIncrement = (auction['bid_increment'] as num).toDouble();
      final minimumBid = currentHighestBid + bidIncrement;
      
      if (bidAmount < minimumBid) {
        throw Exception('Bid must be at least \$${minimumBid.toStringAsFixed(2)}');
      }
      
      // Get previous highest bidder ID
      final previousHighestBidderId = auction['highest_bidder_id'] as String?;
      
      // Begin transaction
      // 1. Insert new bid
      await _supabase.from('bids').insert({
        'auction_id': auctionId,
        'bidder_id': bidderId,
        'amount': bidAmount,
        'previous_highest_bidder_id': previousHighestBidderId,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // 2. Update auction with new highest bid
      await _supabase
          .from('auctions')
          .update({
            'highest_bid': bidAmount,
            'highest_bidder_id': bidderId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', auctionId);
      
      log('✅ Bid placed successfully: $bidAmount by $bidderId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error placing bid: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get all bids for an auction
  Future<List<Map<String, dynamic>>> getAuctionBids(String auctionId) async {
    try {
      final response = await _supabase
          .from('bids')
          .select('*, bidder:profiles!bidder_id(display_name, email)')
          .eq('auction_id', auctionId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      log('❌ Error getting auction bids: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get all bids placed by a user
  Future<List<Map<String, dynamic>>> getUserBids(String userId) async {
    try {
      final response = await _supabase
          .from('bids')
          .select('*, auction:auctions!auction_id(title, highest_bid, highest_bidder_id, end_time)')
          .eq('bidder_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      log('❌ Error getting user bids: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get winning bids for a user
  Future<List<Map<String, dynamic>>> getUserWinningBids(String userId) async {
    try {
      final response = await _supabase
          .from('auctions')
          .select('*, seller:profiles!seller_id(display_name, email)')
          .eq('highest_bidder_id', userId)
          .eq('is_active', false) // Auction must be ended
          .order('end_time', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      log('❌ Error getting winning bids: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Stream of bids for an auction (real-time)
  Stream<List<Map<String, dynamic>>> streamAuctionBids(String auctionId) {
    return _supabase
        .from('bids')
        .stream(primaryKey: ['id'])
        .eq('auction_id', auctionId)
        .order('created_at')
        .map((event) => List<Map<String, dynamic>>.from(event));
  }

  /// Create an auto-bid for a user
  Future<bool> createAutoBid(String auctionId, String bidderId, double maxAmount, double increment) async {
    try {
      await _supabase.from('auto_bids').insert({
        'auction_id': auctionId,
        'bidder_id': bidderId,
        'max_amount': maxAmount,
        'increment': increment,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      log('✅ Auto-bid created successfully');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error creating auto-bid: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Cancel an auto-bid
  Future<bool> cancelAutoBid(String auctionId, String bidderId) async {
    try {
      await _supabase
          .from('auto_bids')
          .update({'is_active': false})
          .eq('auction_id', auctionId)
          .eq('bidder_id', bidderId);
      
      log('✅ Auto-bid cancelled successfully');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error cancelling auto-bid: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}