// lib/features/auctions/services/watchlist_service.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/auction_model.dart';
import '../../../data/models/fixed_price_listing_model.dart';
import '../../../data/models/watchlist_item_model.dart';

class WatchlistService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Add an auction to the user's watchlist
  Future<bool> addToWatchlist(String itemId, WatchlistItemType itemType, {double? maxAutoBidAmount}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if item is already in watchlist
      final existing = await _supabase
          .from('watchlist')
          .select()
          .eq('user_id', user.id)
          .eq('item_id', itemId)
          .maybeSingle();
          
      if (existing != null) {
        // Item already in watchlist, just update if needed
        if (maxAutoBidAmount != null) {
          await _supabase
              .from('watchlist')
              .update({
                'max_auto_bid_amount': maxAutoBidAmount,
                'notifications_enabled': true // Ensure notifications are enabled
              })
              .eq('id', existing['id']);
        }
        log('Item already in watchlist, updated settings');
        return true;
      }

      // Create watchlist item
      final watchlistItem = WatchlistItem(
        itemId: itemId,
        itemType: itemType,
        userId: user.id,
        maxAutoBidAmount: maxAutoBidAmount,
      );

      // Insert into database
      await _supabase.from('watchlist').insert(watchlistItem.toMap());
      
      log('✅ Added to watchlist: $itemId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error adding to watchlist: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Remove an item from the user's watchlist
  Future<bool> removeFromWatchlist(String itemId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('watchlist')
          .delete()
          .eq('user_id', user.id)
          .eq('item_id', itemId);
      
      log('✅ Removed from watchlist: $itemId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error removing from watchlist: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Check if an item is in the user's watchlist
  Future<bool> isInWatchlist(String itemId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      final result = await _supabase
          .from('watchlist')
          .select()
          .eq('user_id', user.id)
          .eq('item_id', itemId)
          .maybeSingle();
      
      return result != null;
    } catch (e, stackTrace) {
      log('❌ Error checking watchlist: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Toggle notifications for a watchlist item
  Future<bool> toggleNotifications(String itemId, bool enabled) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('watchlist')
          .update({'notifications_enabled': enabled})
          .eq('user_id', user.id)
          .eq('item_id', itemId);
      
      log('✅ Notifications ${enabled ? 'enabled' : 'disabled'} for item: $itemId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error toggling notifications: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get all auctions in user's watchlist
  Future<List<Auction>> getWatchedAuctions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      // First get watchlist items
      final watchlistItems = await _supabase
          .from('watchlist')
          .select()
          .eq('user_id', user.id)
          .eq('item_type', 'auction');
      
      if (watchlistItems.isEmpty) {
        return [];
      }

      // Extract auction IDs
      final auctionIds = watchlistItems
          .map<String>((item) => item['item_id'] as String)
          .toList();
      
      // Fetch auctions with those IDs
      final auctions = await _supabase
          .from('auctions')
          .select()
          .in_('id', auctionIds);
      
      return auctions.map((data) => Auction.fromMap(data)).toList();
    } catch (e, stackTrace) {
      log('❌ Error getting watched auctions: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get all fixed price listings in user's watchlist
  Future<List<FixedPriceListing>> getWatchedFixedPriceListings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      // First get watchlist items
      final watchlistItems = await _supabase
          .from('watchlist')
          .select()
          .eq('user_id', user.id)
          .eq('item_type', 'fixedPrice');
      
      if (watchlistItems.isEmpty) {
        return [];
      }

      // Extract listing IDs
      final listingIds = watchlistItems
          .map<String>((item) => item['item_id'] as String)
          .toList();
      
      // Fetch listings with those IDs
      final listings = await _supabase
          .from('fixed_price_listings')
          .select()
          .in_('id', listingIds);
      
      return listings.map((data) => FixedPriceListing.fromMap(data)).toList();
    } catch (e, stackTrace) {
      log('❌ Error getting watched fixed price listings: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get watchlist items with auction/listing data
  Stream<List<Map<String, dynamic>>> streamWatchlist() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('watchlist')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((items) => List<Map<String, dynamic>>.from(items));
  }
}