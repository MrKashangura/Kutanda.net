// lib/data/repositories/auction_repository.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/auction_model.dart';

class AuctionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create an auction
  Future<bool> createAuction(Auction auction) async {
    try {
      await _supabase.from('auctions').insert(auction.toMap());
      log("✅ Auction Created: ${auction.id}");
      return true;
    } catch (e, stackTrace) {
      log("❌ Error Creating Auction: $e", error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get all auctions
  Future<List<Auction>> getAllAuctions() async {
    try {
      final response = await _supabase
          .from('auctions')
          .select()
          .order('created_at', ascending: false);
      
      return response.map((data) => Auction.fromMap(data)).toList();
    } catch (e, stackTrace) {
      log("❌ Error Getting Auctions: $e", error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get active auctions
  Future<List<Auction>> getActiveAuctions() async {
    try {
      final response = await _supabase
          .from('auctions')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      return response.map((data) => Auction.fromMap(data)).toList();
    } catch (e, stackTrace) {
      log("❌ Error Getting Active Auctions: $e", error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get auctions by seller
  Future<List<Auction>> getSellerAuctions(String sellerId) async {
    try {
      final response = await _supabase
          .from('auctions')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);
      
      return response.map((data) => Auction.fromMap(data)).toList();
    } catch (e, stackTrace) {
      log("❌ Error Getting Seller Auctions: $e", error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get auction by ID
  Future<Auction?> getAuctionById(String auctionId) async {
    try {
      final response = await _supabase
          .from('auctions')
          .select()
          .eq('id', auctionId)
          .maybeSingle();
      
      if (response == null) return null;
      return Auction.fromMap(response);
    } catch (e, stackTrace) {
      log("❌ Error Getting Auction: $e", error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Update auction
  Future<bool> updateAuction(Auction auction) async {
    try {
      await _supabase
          .from('auctions')
          .update(auction.toMap())
          .eq('id', auction.id);
      
      log("✅ Auction Updated: ${auction.id}");
      return true;
    } catch (e, stackTrace) {
      log("❌ Error Updating Auction: $e", error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Delete auction
  Future<bool> deleteAuction(String auctionId) async {
    try {
      await _supabase
          .from('auctions')
          .delete()
          .eq('id', auctionId);
      
      log("✅ Auction Deleted: $auctionId");
      return true;
    } catch (e, stackTrace) {
      log("❌ Error Deleting Auction: $e", error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Place a bid
  Future<bool> placeBid(String auctionId, double bidAmount, String bidderId) async {
    try {
      // Begin transaction
      // Step 1: Get the current auction data
      final auction = await getAuctionById(auctionId);
      if (auction == null) {
        throw Exception("Auction not found");
      }

      // Step 2: Validate the bid
      if (bidAmount <= auction.highestBid) {
        throw Exception("Bid must be higher than the current highest bid");
      }

      // Step 3: Store bid
      await _supabase.from('bids').insert({
        'auction_id': auctionId,
        'bidder_id': bidderId,
        'amount': bidAmount,
        'previous_highest_bidder_id': auction.highestBidderId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Step 4: Update auction with new highest bid
      await _supabase.from('auctions').update({
        'highest_bid': bidAmount,
        'highest_bidder_id': bidderId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', auctionId);

      log("✅ Bid Placed: $bidAmount by $bidderId on auction $auctionId");
      return true;
    } catch (e, stackTrace) {
      log("❌ Error Placing Bid: $e", error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get bids for an auction
  Future<List<Map<String, dynamic>>> getAuctionBids(String auctionId) async {
    try {
      final response = await _supabase
          .from('bids')
          .select('*, bidder:profiles!bidder_id(display_name, email)')
          .eq('auction_id', auctionId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      log("❌ Error Getting Auction Bids: $e", error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Listen to auctions (real-time)
  Stream<List<Auction>> listenToAuctions() {
    return _supabase
        .from('auctions')
        .stream(primaryKey: ['id'])
        .map((event) => event.map((data) => Auction.fromMap(data)).toList());
  }

  /// Listen to auctions by seller (real-time)
  Stream<List<Auction>> listenToSellerAuctions(String sellerId) {
    return _supabase
        .from('auctions')
        .stream(primaryKey: ['id'])
        .eq('seller_id', sellerId)
        .map((event) => event.map((data) => Auction.fromMap(data)).toList());
  }

  /// Listen to auction bids (real-time)
  Stream<List<Map<String, dynamic>>> listenToAuctionBids(String auctionId) {
    return _supabase
        .from('bids')
        .stream(primaryKey: ['id'])
        .eq('auction_id', auctionId)
        .map((event) => List<Map<String, dynamic>>.from(event));
  }
}