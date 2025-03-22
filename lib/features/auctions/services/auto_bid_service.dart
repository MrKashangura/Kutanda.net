// lib/features/auctions/services/auto_bid_service.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/auction_model.dart';
import '../../../shared/services/notification_service.dart';

class AutoBidService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  /// Create or update an auto-bid configuration
  Future<bool> setAutoBid({
    required String auctionId,
    required double maxAmount,
    required double bidIncrement,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated');
      }

      // Check if the auction exists and if the user is eligible to bid
      final auction = await _supabase
          .from('auctions')
          .select()
          .eq('id', auctionId)
          .single();

      if (auction['seller_id'] == user.id) {
        throw Exception('You cannot auto-bid on your own auction');
      }

      // Check if there's already an auto-bid configuration for this user and auction
      final existingAutoBid = await _supabase
          .from('auto_bids')
          .select()
          .eq('auction_id', auctionId)
          .eq('bidder_id', user.id)
          .maybeSingle();

      if (existingAutoBid != null) {
        // Update existing auto-bid
        await _supabase
            .from('auto_bids')
            .update({
              'max_amount': maxAmount,
              'increment': bidIncrement,
              'is_active': true,
              'last_updated': DateTime.now().toIso8601String(),
            })
            .eq('id', existingAutoBid['id']);

        log('✅ Auto-bid updated for auction: $auctionId');
      } else {
        // Create new auto-bid
        await _supabase.from('auto_bids').insert({
          'auction_id': auctionId,
          'bidder_id': user.id,
          'max_amount': maxAmount,
          'increment': bidIncrement,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        });

        log('✅ Auto-bid created for auction: $auctionId');
      }

      // Also add to watchlist if not already there
      await _ensureInWatchlist(auctionId, user.id);

      return true;
    } catch (e, stackTrace) {
      log('❌ Error setting auto-bid: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Pause an auto-bid
  Future<bool> pauseAutoBid(String auctionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated');
      }

      // Update auto-bid status
      await _supabase
          .from('auto_bids')
          .update({
            'is_active': false,
            'last_updated': DateTime.now().toIso8601String(),
          })
          .eq('auction_id', auctionId)
          .eq('bidder_id', user.id);

      log('✅ Auto-bid paused for auction: $auctionId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error pausing auto-bid: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Resume an auto-bid
  Future<bool> resumeAutoBid(String auctionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated');
      }

      // Update auto-bid status
      await _supabase
          .from('auto_bids')
          .update({
            'is_active': true,
            'last_updated': DateTime.now().toIso8601String(),
          })
          .eq('auction_id', auctionId)
          .eq('bidder_id', user.id);

      log('✅ Auto-bid resumed for auction: $auctionId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error resuming auto-bid: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Delete an auto-bid
  Future<bool> deleteAutoBid(String auctionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated');
      }

      // Delete auto-bid configuration
      await _supabase
          .from('auto_bids')
          .delete()
          .eq('auction_id', auctionId)
          .eq('bidder_id', user.id);

      log('✅ Auto-bid deleted for auction: $auctionId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error deleting auto-bid: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get auto-bid configuration for an auction
  Future<Map<String, dynamic>?> getAutoBid(String auctionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Get auto-bid configuration
      final autoBid = await _supabase
          .from('auto_bids')
          .select()
          .eq('auction_id', auctionId)
          .eq('bidder_id', user.id)
          .maybeSingle();

      return autoBid;
    } catch (e, stackTrace) {
      log('❌ Error getting auto-bid: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Process auto-bids for an auction (called whenever a new bid is placed)
  Future<void> processAutoBids(String auctionId, double currentBid) async {
    try {
      // Get auction details
      final auctionData = await _supabase
          .from('auctions')
          .select()
          .eq('id', auctionId)
          .single();
      
      final auction = Auction.fromMap(auctionData);
      
      // Get all active auto-bids for this auction
      final autoBids = await _supabase
          .from('auto_bids')
          .select('*, bidder:profiles!bidder_id(display_name, email)')
          .eq('auction_id', auctionId)
          .eq('is_active', true)
          .order('max_amount', ascending: false); // Process highest max amount first
      
      // Skip if no auto-bids
      if (autoBids.isEmpty) return;
      
      // Skip if current highest bidder has the highest auto-bid
      if (auction.highestBidderId != null && 
          autoBids.isNotEmpty && 
          autoBids[0]['bidder_id'] == auction.highestBidderId) {
        return;
      }
      
      // Loop through auto-bids
      for (final autoBid in autoBids) {
        final bidderId = autoBid['bidder_id'];
        final maxAmount = (autoBid['max_amount'] as num).toDouble();
        final increment = (autoBid['increment'] as num).toDouble();
        
        // Skip if this bidder is already the highest bidder
        if (bidderId == auction.highestBidderId) continue;
        
        // Calculate next bid
        final minBid = currentBid + auction.bidIncrement;
        final nextBid = _calculateNextBid(currentBid, increment, auction.bidIncrement);
        
        // Check if auto-bid can outbid current highest bid
        if (nextBid <= maxAmount && nextBid >= minBid) {
          // Place bid
          await _placeBid(auctionId, bidderId, nextBid, true);
          
          // Send notification to bidder
          _notificationService.showAutoBidNotification(
            auction.title,
            nextBid
          );
          
          // Update current bid for next iteration
          currentBid = nextBid;
        }
      }
    } catch (e, stackTrace) {
      log('❌ Error processing auto-bids: $e', error: e, stackTrace: stackTrace);
    }
  }

  /// Place a bid as part of auto-bidding
  Future<bool> _placeBid(String auctionId, String bidderId, double amount, bool isAutoBid) async {
    try {
      // Get current auction data
      final auction = await _supabase
          .from('auctions')
          .select()
          .eq('id', auctionId)
          .single();
      
      final currentHighestBid = (auction['highest_bid'] as num).toDouble();
      final previousHighestBidderId = auction['highest_bidder_id'];
      
      // Skip if amount is not higher than current bid
      if (amount <= currentHighestBid) {
        return false;
      }
      
      // Store bid
      await _supabase.from('bids').insert({
        'auction_id': auctionId,
        'bidder_id': bidderId,
        'amount': amount,
        'is_auto_bid': isAutoBid,
        'previous_highest_bidder_id': previousHighestBidderId,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Update auction
      await _supabase.from('auctions').update({
        'highest_bid': amount,
        'highest_bidder_id': bidderId,
      }).eq('id', auctionId);
      
      log('✅ Auto-bid placed: $amount by $bidderId on auction $auctionId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error placing auto-bid: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Calculate the next bid amount based on current bid and increment
  double _calculateNextBid(double currentBid, double userIncrement, double minIncrement) {
    // Ensure increment is at least the minimum
    final increment = userIncrement > minIncrement ? userIncrement : minIncrement;
    
    // Return current bid plus increment
    return currentBid + increment;
  }

  /// Ensure auction is in user's watchlist
  Future<void> _ensureInWatchlist(String auctionId, String userId) async {
    try {
      // Check if already in watchlist
      final watchlistItem = await _supabase
          .from('watchlist')
          .select()
          .eq('item_id', auctionId)
          .eq('user_id', userId)
          .eq('item_type', 'auction')
          .maybeSingle();
      
      // If not in watchlist, add it
      if (watchlistItem == null) {
        await _supabase.from('watchlist').insert({
          'user_id': userId,
          'item_id': auctionId,
          'item_type': 'auction',
          'created_at': DateTime.now().toIso8601String(),
          'notifications_enabled': true,
        });
      }
    } catch (e) {
      // Ignore errors - this is just a convenience feature
    }
  }
}