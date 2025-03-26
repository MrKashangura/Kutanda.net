// lib/shared/services/notification_service.dart
import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notificationsPlugin.initialize(
      initializationSettings,
    );
    
    _isInitialized = true;
    log('✅ Notification service initialized');
  }

  Future<void> showOutbidNotification(String auctionTitle, double newBidAmount) async {
    if (!_isInitialized) await initialize();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'outbid_channel',
      'Outbid Notifications',
      channelDescription: 'Notifications for when you get outbid',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    await _notificationsPlugin.show(
      0,
      'You\'ve been outbid!',
      'Someone placed a bid of \$${newBidAmount.toStringAsFixed(2)} on $auctionTitle',
      notificationDetails,
    );
  }

  Future<void> showBidPlacedNotification(String auctionTitle, double bidAmount) async {
    if (!_isInitialized) await initialize();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bid_placed_channel',
      'Bid Placed Notifications',
      channelDescription: 'Notifications for when you place a bid',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    await _notificationsPlugin.show(
      1,
      'Bid Placed Successfully',
      'Your bid of \$${bidAmount.toStringAsFixed(2)} on $auctionTitle was placed successfully',
      notificationDetails,
    );
  }

  Future<void> showAuctionEndingNotification(String auctionTitle) async {
    if (!_isInitialized) await initialize();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'auction_ending_channel',
      'Auction Ending Notifications',
      channelDescription: 'Notifications for auctions that are ending soon',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    await _notificationsPlugin.show(
      2,
      'Auction Ending Soon',
      '$auctionTitle is ending in less than 5 minutes!',
      notificationDetails,
    );
  }
  
  Future<void> showAutoBidNotification(String auctionTitle, double bidAmount) async {
  if (!_isInitialized) await initialize();
  
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'auto_bid_channel',
    'Auto-Bid Notifications',
    channelDescription: 'Notifications for automatic bids',
    importance: Importance.high,
    priority: Priority.high,
  );
  
  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: DarwinNotificationDetails(),
  );
  
  await _notificationsPlugin.show(
    4, // Use a unique ID different from other notification types
    'Auto-Bid Placed',
    'Your auto-bid system placed a bid of \$${bidAmount.toStringAsFixed(2)} on $auctionTitle',
    notificationDetails,
  );
}

  Future<void> showAuctionWonNotification(String auctionTitle) async {
    if (!_isInitialized) await initialize();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'auction_won_channel',
      'Auction Won Notifications',
      channelDescription: 'Notifications for auctions you have won',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    await _notificationsPlugin.show(
      3,
      'Auction Won!',
      'Congratulations! You\'ve won the auction for $auctionTitle',
      notificationDetails,
    );
  }
}