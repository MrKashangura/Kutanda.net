import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      
      final initialized = await _notificationsPlugin.initialize(
        initializationSettings,
      );

      _isInitialized = initialized ?? false;
      log(_isInitialized 
          ? '✅ Notification service initialized' 
          : '⚠️ Notification service initialization returned false');
      
      // Request permissions
      await requestPermissions();
      
      return _isInitialized;
    } catch (e) {
      log('❌ Failed to initialize notification service: $e');
      return false;
    }
  }

  /// Request notification permissions
  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestPermission();
    }
  }

  /// Make sure the service is initialized before sending notifications
  Future<bool> _ensureInitialized({int maxRetries = 3}) async {
    if (_isInitialized) return true;
    
    int retries = 0;
    bool success = false;
    
    while (retries < maxRetries && !success) {
      success = await initialize();
      if (!success) {
        retries++;
        log('⚠️ Retry initialization: attempt $retries of $maxRetries');
        await Future.delayed(Duration(seconds: retries));
      }
    }
    
    return success;
  }

  /// Show notification when user is outbid
  Future<void> showOutbidNotification(String auctionTitle, double newBidAmount) async {
    if (!await _ensureInitialized()) {
      log('❌ Could not initialize notification service, skipping outbid notification');
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'outbid_channel',
      'Outbid Notifications',
      channelDescription: 'Notifications for when you are outbid in an auction',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0,
      'Outbid Alert!',
      'You have been outbid on $auctionTitle. New bid: \$${newBidAmount.toStringAsFixed(2)}',
      platformChannelSpecifics,
    );
    
    log('📣 Sent outbid notification for $auctionTitle');
  }

  /// Show notification when an auction is ending soon
  Future<void> showAuctionEndingNotification(String auctionTitle) async {
    if (!await _ensureInitialized()) {
      log('❌ Could not initialize notification service, skipping auction ending notification');
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'auction_ending_channel',
      'Auction Ending Notifications',
      channelDescription: 'Notifications for when auctions are ending soon',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      1,
      'Auction Ending Soon!',
      '$auctionTitle is ending soon. Don\'t miss your chance!',
      platformChannelSpecifics,
    );
    
    log('📣 Sent auction ending notification for $auctionTitle');
  }

  /// Show notification when a user wins an auction
  Future<void> showAuctionWonNotification(String auctionTitle) async {
    if (!await _ensureInitialized()) {
      log('❌ Could not initialize notification service, skipping auction won notification');
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'auction_won_channel',
      'Auction Won Notifications',
      channelDescription: 'Notifications for when you win an auction',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      2,
      'Congratulations!',
      'You won the auction for $auctionTitle!',
      platformChannelSpecifics,
    );
    
    log('📣 Sent auction won notification for $auctionTitle');
  }
}