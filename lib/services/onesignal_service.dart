import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/onesignal_service.dart';

const String supabaseUrl = 'https://dcjycjiqelcftxbymley.supabase.co';

class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  
  OneSignalService._internal();
  
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isInitialized = false;

  // Your OneSignal App ID - you'll need to create an account and app at onesignal.com
  static const String _appId = 'YOUR_ONESIGNAL_APP_ID';
  
  /// Initialize OneSignal
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize OneSignal
      await OneSignal.shared.setAppId(_appId);
      
      // Enable in-app alerts (for when the app is in foreground)
      await OneSignal.shared.setInAppMessageClickHandler((action) {
        log('OneSignal IAM clicked: $action');
      });

      // Handle notification opened events
      OneSignal.shared.setNotificationOpenedHandler((OSNotificationOpenedResult result) {
        log('Notification opened: ${result.notification.title}');
        _handleNotificationOpened(result);
      });
      
      // Request push notification permission (for iOS)
      await OneSignal.shared.promptUserForPushNotificationPermission();
      
      // Subscribe to events when app is in foreground
      OneSignal.shared.setNotificationWillShowInForegroundHandler(
        (OSNotificationReceivedEvent event) {
          // Complete the notification to show it
          event.complete(event.notification);
        }
      );
      
      // Store the OneSignal player ID in Supabase for this user
      await _saveUserExternalId();
      
      _isInitialized = true;
      log('✅ OneSignal initialized successfully');
    } catch (e) {
      log('❌ Error initializing OneSignal: $e');
    }
  }
  
  /// Get the OneSignal external ID (player ID)
  Future<String?> _getExternalId() async {
    try {
      final deviceState = await OneSignal.shared.getDeviceState();
      return deviceState?.userId; // This is the OneSignal Player ID
    } catch (e) {
      log('❌ Error getting OneSignal external ID: $e');
      return null;
    }
  }
  
  /// Save the user's OneSignal ID to Supabase
  Future<void> _saveUserExternalId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        log('⚠️ No authenticated user to save OneSignal ID for');
        return;
      }
      
      final externalId = await _getExternalId();
      if (externalId == null) {
        log('⚠️ Failed to get OneSignal external ID');
        return;
      }
      
      // Store the OneSignal player ID in Supabase linked to this user
      await _supabase.from('user_notification_tokens').upsert(
        {
          'user_id': user.id,
          'onesignal_id': externalId,
          'device_type': 'mobile', // You could get more detailed device info if needed
          'last_updated': DateTime.now().toIso8601String(),
          'is_active': true,
        },
        onConflict: 'user_id, onesignal_id',
      );
      
      // Also set Supabase user ID as an external ID in OneSignal for targeting
      await OneSignal.shared.setExternalUserId(user.id);
      
      log('✅ OneSignal ID saved for user ${user.id}');
    } catch (e) {
      log('❌ Error saving OneSignal ID: $e');
    }
  }
  
  /// Handle when a notification is opened
  void _handleNotificationOpened(OSNotificationOpenedResult result) {
    try {
      // Extract data from the notification
      final data = result.notification.additionalData;
      if (data == null) return;
      
      // Handle different notification types
      final notificationType = data['type'] as String?;
      
      switch (notificationType) {
        case 'outbid':
          final auctionId = data['auction_id'] as String?;
          if (auctionId != null) {
            // Navigate to auction details - this requires a navigation service 
            // or context that we don't have here, so this would need to be 
            // implemented in your app's global state management
            log('Should navigate to auction details: $auctionId');
          }
          break;
          
        case 'ending_soon':
          final auctionId = data['auction_id'] as String?;
          if (auctionId != null) {
            log('Should navigate to auction details: $auctionId');
          }
          break;
          
        case 'auction_won':
          final auctionId = data['auction_id'] as String?;
          if (auctionId != null) {
            log('Should navigate to auction details: $auctionId');
          }
          break;
          
        default:
          log('Unknown notification type: $notificationType');
      }
    } catch (e) {
      log('❌ Error handling notification opened: $e');
    }
  }
  
  /// Tag a user to track auctions they've bid on
  Future<void> tagUserWithAuctionId(String auctionId) async {
    try {
      await OneSignal.shared.sendTag('auction_$auctionId', 'true');
      log('✅ User tagged with auction ID: $auctionId');
    } catch (e) {
      log('❌ Error tagging user with auction ID: $e');
    }
  }
  
  /// Remove a tag when user is no longer interested in an auction
  Future<void> removeAuctionTag(String auctionId) async {
    try {
      await OneSignal.shared.deleteTag('auction_$auctionId');
      log('✅ Auction tag removed: $auctionId');
    } catch (e) {
      log('❌ Error removing auction tag: $e');
    }
  }
  
  /// Clear all OneSignal data when user logs out
  Future<void> clearUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      final externalId = await _getExternalId();
      if (externalId == null) return;
      
      // Mark the token as inactive in Supabase
      await _supabase
          .from('user_notification_tokens')
          .update({'is_active': false})
          .eq('user_id', user.id)
          .eq('onesignal_id', externalId);
      
      // Remove user ID from OneSignal
      await OneSignal.shared.removeExternalUserId();
      
      // Clear all tags
      await OneSignal.shared.clearOneSignalNotifications();
      
      log('✅ OneSignal user data cleared');
    } catch (e) {
      log('❌ Error clearing OneSignal user data: $e');
    }
  }
  Future<void> _handleOutbid(Map<String, dynamic> bid, String userId) async {
  try {
    // Get auction details
    final auction = await supabase
        .from('auctions')
        .select()
        .eq('id', bid['auction_id'])
        .maybeSingle();
    
    if (auction != null) {
      // Initialize OneSignal service for tagging
      final oneSignalService = OneSignalService();
      await oneSignalService.initialize();
      
      // Show local notification to the outbid user
      final notificationService = NotificationService();
      await notificationService.showOutbidNotification(
        auction['title'], 
        (bid['amount'] as num).toDouble()
      );
      
      // Call Supabase Edge Function to send external notification
      await _triggerExternalNotification(
        'outbid',
        [userId], // target user who was outbid
        auction['id'],
        'Outbid Alert!',
        'You have been outbid on ${auction['title']}. New bid: \$${(bid['amount'] as num).toDouble().toStringAsFixed(2)}',
        {
          'previous_bid': auction['highest_bid'],
          'new_bid': bid['amount'],
          'bidder_id': bid['bidder_id'],
        }
      );
      
      log("📣 Outbid notification sent to $userId");
    }
  } catch (e, stackTrace) {
    log("❌ Error handling outbid: $e", error: e, stackTrace: stackTrace);
  }
}

/// Check for auctions ending soon with external notifications
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
      
      // Convert to List for the edge function
      final biddersList = bidders.toList();
      
      if (biddersList.isNotEmpty) {
        // Send local notifications
        final notificationService = NotificationService();
        for (final bidderId in bidders) {
          await notificationService.showAuctionEndingNotification(auction['title']);
        }
        
        // Send external notification
        await _triggerExternalNotification(
          'ending_soon',
          biddersList,
          auction['id'],
          'Auction Ending Soon!',
          '${auction['title']} is ending in less than 5 minutes. Don\'t miss your chance!',
          {
            'current_bid': auction['highest_bid'],
            'time_remaining': 'less than 5 minutes',
          }
        );
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

/// Check for ended auctions and send external notifications
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
        // Local notification
        final notificationService = NotificationService();
        await notificationService.showAuctionWonNotification(auction['title']);
        
        // External notification to winner
        await _triggerExternalNotification(
          'auction_won',
          [auction['highest_bidder_id']],
          auction['id'],
          'Congratulations! Auction Won!',
          'You won the auction for ${auction['title']} with a bid of \$${(auction['highest_bid'] as num).toDouble().toStringAsFixed(2)}',
          {
            'final_bid': auction['highest_bid'],
            'seller_id': auction['seller_id'],
          }
        );
        
        // Also notify the seller
        await _triggerExternalNotification(
          'auction_sold',
          [auction['seller_id']],
          auction['id'],
          'Your Auction Has Ended',
          'Your auction for ${auction['title']} has ended. It sold for \$${(auction['highest_bid'] as num).toDouble().toStringAsFixed(2)}',
          {
            'final_bid': auction['highest_bid'],
            'buyer_id': auction['highest_bidder_id'],
          }
        );
        
        log("📣 Auction won/sold notifications sent for: ${auction['id']}");
      } else {
        // No bids - notify only the seller
        await _triggerExternalNotification(
          'auction_ended_no_bids',
          [auction['seller_id']],
          auction['id'],
          'Your Auction Has Ended',
          'Your auction for ${auction['title']} has ended without any bids.',
          {}
        );
        
        log("📣 Auction ended (no bids) notification sent to seller: ${auction['seller_id']}");
      }
    }
  } catch (e, stackTrace) {
    log("❌ Error checking ended auctions: $e", error: e, stackTrace: stackTrace);
  }
}

/// Enhanced place bid method to also tag users with OneSignal
Future<void> placeBid(String auctionId, double bidAmount, String bidderId) async {
  try {
    // Regular bid logic...

    // Initialize OneSignal service for tagging
    final oneSignalService = OneSignalService();
    await oneSignalService.initialize();
    
    // Tag the user with this auction ID so they can receive notifications about it
    await oneSignalService.tagUserWithAuctionId(auctionId);
    
  } catch (e, stackTrace) {
    log("❌ Error Placing Bid: $e", error: e, stackTrace: stackTrace);
    rethrow;
  }
}

/// Call the Supabase Edge Function to send an external notification
Future<void> _triggerExternalNotification(
  String notificationType,
  List<String> targetUsers,
  String auctionId,
  String title,
  String message,
  Map<String, dynamic> additionalData
) async {
  try {
    // Get the authorization token - requires the user to be logged in
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      log("⚠️ Cannot send notification: No authenticated user");
      return;
    }
    final authToken = await supabase.auth.refreshSession();
    final jwt = authToken.session?.accessToken;
    if (jwt == null) {
      log("⚠️ Cannot send notification: No valid auth token");
      return;
    }
    
    // Call the edge function
    final response = await http.post(
      Uri.parse('$supabaseUrl/functions/v1/send-notifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode({
        'notificationType': notificationType,
        'targetUsers': targetUsers,
        'auctionId': auctionId,
        'title': title,
        'message': message,
        'additionalData': additionalData,
      }),
    );
    
    if (response.statusCode != 200) {
      log("⚠️ Error from notification edge function: ${response.body}");
    } else {
      log("✅ External notification triggered successfully: $notificationType");
    }
  } catch (e, stackTrace) {
    log("❌ Error triggering external notification: $e", error: e, stackTrace: stackTrace);
  }
}
}