// lib/features/auctions/services/watchlist_service.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/auction_model.dart';
import '../../../data/models/fixed_price_listing_model.dart';
import '../../../data/models/watchlist_item_model.dart';

class WatchlistService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Add an item to the user's watchlist
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
          .eq('user_uid', user.id)
          .eq('item_uid', itemId)
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
              .eq('uid', existing['uid']);
        }
        log('Item already in watchlist, updated settings');
        return true;
      }

      // Prepare database fields
      final Map<String, dynamic> watchlistData = {
        'user_uid': user.id,
        'item_uid': itemId,
        'item_type': itemType == WatchlistItemType.auction ? 'auction' : 'fixedPrice',
        'created_at': DateTime.now().toIso8601String(),
        'notifications_enabled': true,
      };
      
      // Add auto bid amount if provided
      if (maxAutoBidAmount != null) {
        watchlistData['max_auto_bid_amount'] = maxAutoBidAmount;
      }

      // Insert into database
      await _supabase.from('watchlist').insert(watchlistData);
      
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
          .eq('user_uid', user.id)
          .eq('item_uid', itemId);
      
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
          .eq('user_uid', user.id)
          .eq('item_uid', itemId)
          .maybeSingle();
      
      return result != null;
    } catch (e, stackTrace) {
      log('❌ Error checking watchlist: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get all watchlisted item IDs for a user
  Future<List<String>> getWatchlistItemIds() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      final response = await _supabase
          .from('watchlist')
          .select('item_uid')
          .eq('user_uid', user.id);
      
      return List<String>.from(
        response.map((item) => item['item_uid'] as String)
      );
    } catch (e, stackTrace) {
      log('❌ Error getting watchlist items: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get all watchlisted auctions for a user
  Future<List<Auction>> getWatchlistedAuctions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      // First get watchlist items
      final watchlistItems = await _supabase
          .from('watchlist')
          .select()
          .eq('user_uid', user.id)
          .eq('item_type', 'auction');
      
      if (watchlistItems.isEmpty) {
        return [];
      }

      // Extract auction IDs
      final auctionIds = watchlistItems
          .map<String>((item) => item['item_uid'] as String)
          .toList();
      
      // Fetch auctions with those IDs
      final auctions = await _supabase
          .from('auctions')
          .select()
          .inFilter('id', auctionIds);
      
      return auctions.map((data) => Auction.fromMap(data)).toList();
    } catch (e, stackTrace) {
      log('❌ Error getting watchlisted auctions: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get all watchlisted fixed price listings for a user
  Future<List<FixedPriceListing>> getWatchlistedFixedPriceListings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      // First get watchlist items
      final watchlistItems = await _supabase
          .from('watchlist')
          .select()
          .eq('user_uid', user.id)
          .eq('item_type', 'fixedPrice');
      
      if (watchlistItems.isEmpty) {
        return [];
      }

      // Extract listing IDs
      final listingIds = watchlistItems
          .map<String>((item) => item['item_uid'] as String)
          .toList();
      
      // Fetch listings with those IDs
      final listings = await _supabase
          .from('fixed_price_listings')
          .select()
          .inFilter('uid', listingIds); // Using 'uid' in database
      
      // Convert database fields to model fields
      return listings.map((data) {
        final normalizedData = <String, dynamic>{};
        
        // Map database fields to model fields
        normalizedData['id'] = data['uid'];
        normalizedData['sellerId'] = data['seller_uid'];
        normalizedData['title'] = data['title'];
        normalizedData['description'] = data['description'];
        normalizedData['price'] = (data['price'] as num).toDouble();
        normalizedData['quantityAvailable'] = data['quantity_available'];
        normalizedData['quantitySold'] = data['quantity_sold'] ?? 0;
        normalizedData['imageUrls'] = data['image_urls'] ?? [];
        normalizedData['isFeatured'] = data['is_featured'] ?? false;
        normalizedData['createdAt'] = DateTime.parse(data['created_at']);
        normalizedData['featuredUntil'] = data['featured_until'] != null 
            ? DateTime.parse(data['featured_until']) 
            : null;
        normalizedData['isActive'] = data['is_active'] ?? true;
        
        return FixedPriceListing.fromMap(normalizedData);
      }).toList();
    } catch (e, stackTrace) {
      log('❌ Error getting watchlisted fixed price listings: $e', error: e, stackTrace: stackTrace);
      return [];
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
          .eq('user_uid', user.id)
          .eq('item_uid', itemId);
      
      log('✅ Notifications ${enabled ? 'enabled' : 'disabled'} for item: $itemId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error toggling notifications: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Stream watchlist changes for real-time updates
  Stream<List<Map<String, dynamic>>> streamWatchlist() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('watchlist')
        .stream(primaryKey: ['uid'])
        .eq('user_uid', user.id)
        .map((items) => List<Map<String, dynamic>>.from(items));
  }

  /// Set auto-bid configuration for a watchlisted auction
  Future<bool> setAutoBidAmount(String auctionId, double maxAmount) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final watchlistItem = await _supabase
          .from('watchlist')
          .select()
          .eq('user_uid', user.id)
          .eq('item_uid', auctionId)
          .eq('item_type', 'auction')
          .maybeSingle();
      
      if (watchlistItem == null) {
        // Item not in watchlist, add it first
        return addToWatchlist(auctionId, WatchlistItemType.auction, maxAutoBidAmount: maxAmount);
      }
      
      // Update existing watchlist item
      await _supabase
          .from('watchlist')
          .update({'max_auto_bid_amount': maxAmount})
          .eq('uid', watchlistItem['uid']);
      
      log('✅ Auto-bid amount set for auction: $auctionId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error setting auto-bid amount: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Get auto-bid configuration for a watchlisted auction
  Future<double?> getAutoBidAmount(String auctionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return null;
      }

      final watchlistItem = await _supabase
          .from('watchlist')
          .select('max_auto_bid_amount')
          .eq('user_uid', user.id)
          .eq('item_uid', auctionId)
          .eq('item_type', 'auction')
          .maybeSingle();
      
      if (watchlistItem == null || watchlistItem['max_auto_bid_amount'] == null) {
        return null;
      }
      
      return (watchlistItem['max_auto_bid_amount'] as num).toDouble();
    } catch (e, stackTrace) {
      log('❌ Error getting auto-bid amount: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}