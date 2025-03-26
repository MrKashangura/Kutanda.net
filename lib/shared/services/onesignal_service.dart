// lib/services/onesignal_service.dart
import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  
  OneSignalService._internal();
  
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isInitialized = false;

  // Replace with your actual OneSignal App ID
  static const String _appId = '474b0ac4-c770-4050-b4b2-6b8cbef188a7';
  
  /// Initialize OneSignal
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize OneSignal with your app ID
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(_appId);
      
      // Request push notification permission
      await OneSignal.Notifications.requestPermission(true);

      // Set notification handlers
      OneSignal.Notifications.addClickListener(_handleNotificationOpened);
      
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        event.preventDefault();
        event.notification.display();
      });
      
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
      final deviceState = OneSignal.User.pushSubscription.id;
      return deviceState;
    } catch (e) {
      log('❌ Error getting OneSignal device ID: $e');
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
          'device_type': 'mobile',
          'last_updated': DateTime.now().toIso8601String(),
          'is_active': true,
        },
        onConflict: 'user_id, onesignal_id',
      );
      
      // Set Supabase user ID as an external ID in OneSignal for targeting
      await OneSignal.login(user.id);
      
      log('✅ OneSignal ID saved for user ${user.id}');
    } catch (e) {
      log('❌ Error saving OneSignal ID: $e');
    }
  }
  
  /// Handle when a notification is opened
  void _handleNotificationOpened(OSNotificationClickEvent result) {
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
            // Navigation would happen through a global state management solution
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
      await OneSignal.User.addTagWithKey('auction_$auctionId', 'true');
      log('✅ User tagged with auction ID: $auctionId');
    } catch (e) {
      log('❌ Error tagging user with auction ID: $e');
    }
  }
  
  /// Remove a tag when user is no longer interested in an auction
  Future<void> removeAuctionTag(String auctionId) async {
    try {
      await OneSignal.User.removeTag('auction_$auctionId');
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
      
      // Remove user ID from OneSignal and clear tags
      await OneSignal.logout();
      await OneSignal.User.removeTags(['auction_*']);
      
      log('✅ OneSignal user data cleared');
    } catch (e) {
      log('❌ Error clearing OneSignal user data: $e');
    }
  }
  
  /// Send a notification through Supabase Edge Function
  Future<void> triggerNotification({
    required String notificationType,
    required List<String> targetUserIds,
    required String auctionId,
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Get the authorization token
      final session = _supabase.auth.currentSession;
      final jwt = session?.accessToken;
      if (jwt == null) {
        log("⚠️ Cannot send notification: No valid auth token");
        return;
      }
      
      final supabaseUrl = 'https://dcjycjiqelcftxbymley.supabase.co';
      
      // Call the edge function
      final response = await http.post(
        Uri.parse('$supabaseUrl/functions/v1/send-notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'notificationType': notificationType,
          'targetUserIds': targetUserIds,
          'auctionId': auctionId,
          'title': title,
          'message': message,
          'additionalData': additionalData ?? {},
        }),
      );
      
      if (response.statusCode != 200) {
        log("⚠️ Error from notification edge function: ${response.body}");
      } else {
        log("✅ External notification triggered successfully: $notificationType");
      }
    } catch (e) {
      log("❌ Error triggering external notification: $e");
    }
  }
}