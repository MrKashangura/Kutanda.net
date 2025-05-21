// lib/data/repositories/auction_repository.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/auction_model.dart';
import '../../services/api_service.dart'; // Import ApiService

class AuctionRepository {
  final SupabaseClient _supabase;
  final ApiService _apiService;

  // Allow SupabaseClient and ApiService injection for testing
  AuctionRepository({SupabaseClient? supabase, ApiService? apiService})
      : _supabase = supabase ?? Supabase.instance.client,
        _apiService = apiService ?? ApiService();

  /// Create an auction
  Future<bool> createAuction(Auction auction) async {
    try {
      final response = await _apiService.post('auctions', auction.toMap());
      if (response != null) { // Assuming success if response is not null
        log("✅ Auction Created: ${auction.id}");
        return true;
      }
      log("❌ Error Creating Auction: Response was null");
      return false;
    } catch (e, stackTrace) {
      log("❌ Error Creating Auction: $e", error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get all auctions
  Future<List<Auction>> getAllAuctions() async {
    try {
      // Adjust the endpoint to include ordering if your ApiService/Supabase function supports it
      // For example, 'auctions?order=created_at.desc'
      final response = await _apiService.get('auctions?order=created_at.desc'); 
      if (response != null && response['data'] is List) {
        final dataList = response['data'] as List;
        return dataList.map((data) => Auction.fromMap(data as Map<String, dynamic>)).toList();
      }
      log("❌ Error Getting Auctions: Response was null or not a list");
      return [];
    } catch (e, stackTrace) {
      log("❌ Error Getting Auctions: $e", error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get active auctions
  Future<List<Auction>> getActiveAuctions() async {
    try {
      // Endpoint adjusted for filtering active auctions and ordering
      final response = await _apiService.get('auctions?is_active=eq.true&order=created_at.desc');
      if (response != null && response['data'] is List) {
        final dataList = response['data'] as List;
        return dataList.map((data) => Auction.fromMap(data as Map<String, dynamic>)).toList();
      }
      log("❌ Error Getting Active Auctions: Response was null or not a list");
      return [];
    } catch (e, stackTrace) {
      log("❌ Error Getting Active Auctions: $e", error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get auctions by seller
  Future<List<Auction>> getSellerAuctions(String sellerId) async {
    try {
      // Endpoint adjusted for filtering by seller_id and ordering
      final response = await _apiService.get('auctions?seller_id=eq.$sellerId&order=created_at.desc');
      if (response != null && response['data'] is List) {
        final dataList = response['data'] as List;
        return dataList.map((data) => Auction.fromMap(data as Map<String, dynamic>)).toList();
      }
      log("❌ Error Getting Seller Auctions: Response was null or not a list");
      return [];
    } catch (e, stackTrace) {
      log("❌ Error Getting Seller Auctions: $e", error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get auction by ID
  Future<Auction?> getAuctionById(String auctionId) async {
    try {
      // Endpoint adjusted to fetch a single auction by ID. 
      // Supabase GET request with `limit=1` on a unique ID will return an array with one or zero elements.
      final response = await _apiService.get('auctions?id=eq.$auctionId&limit=1');
      if (response != null && response['data'] is List) {
        final dataList = response['data'] as List;
        if (dataList.isNotEmpty) {
          return Auction.fromMap(dataList.first as Map<String, dynamic>);
        }
      }
      log("❌ Error Getting Auction: Response was null, not a list, or empty");
      return null;
    } catch (e, stackTrace) {
      log("❌ Error Getting Auction: $e", error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Update auction
  Future<bool> updateAuction(Auction auction) async {
    try {
      // Using PUT to update the auction. The endpoint identifies the auction to update.
      final response = await _apiService.put('auctions?id=eq.${auction.id}', auction.toMap());
      if (response != null) { // Assuming success if response is not null
        log("✅ Auction Updated: ${auction.id}");
        return true;
      }
      log("❌ Error Updating Auction: Response was null");
      return false;
    } catch (e, stackTrace) {
      log("❌ Error Updating Auction: $e", error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Delete auction
  Future<bool> deleteAuction(String auctionId) async {
    try {
      // Using DELETE to remove the auction. The endpoint identifies the auction.
      final response = await _apiService.delete('auctions?id=eq.$auctionId');
      if (response != null) { // Assuming success if response is not null
        log("✅ Auction Deleted: $auctionId");
        return true;
      }
      log("❌ Error Deleting Auction: Response was null");
      return false;
    } catch (e, stackTrace) {
      log("❌ Error Deleting Auction: $e", error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Place a bid
  Future<bool> placeBid(String auctionId, double bidAmount, String bidderId) async {
    try {
      // Call Supabase Edge Function 'place-bid' through ApiService
      final response = await _apiService.post('place-bid', {
        'auction_id': auctionId,
        'bid_amount': bidAmount,
        'bidder_id': bidderId,
      });

      if (response != null && response['data'] != null && response['data']['success'] == true) {
        log("✅ Bid Placed: $bidAmount by $bidderId on auction $auctionId");
        return true;
      }
      log("❌ Error Placing Bid: Invalid response from server or bid placement failed. Response: $response");
      return false;
    } catch (e, stackTrace) {
      log("❌ Error Placing Bid: $e", error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get bids for an auction
  Future<List<Map<String, dynamic>>> getAuctionBids(String auctionId) async {
    try {
      // Endpoint adjusted for fetching bids, joining with profiles, filtering by auction_id, and ordering
      final queryString = 'bids?auction_id=eq.$auctionId&select=*,bidder:profiles!bidder_id(display_name,email)&order=created_at.desc';
      final response = await _apiService.get(queryString);
      
      if (response != null && response['data'] is List) {
        // Ensure that each element in the list is a Map<String, dynamic>
        return List<Map<String, dynamic>>.from(
          (response['data'] as List).map((item) => item as Map<String, dynamic>)
        );
      }
      log("❌ Error Getting Auction Bids: Response was null or not a list");
      return [];
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