// lib/data/models/watchlist_item_model.dart
import 'package:uuid/uuid.dart';

enum WatchlistItemType {
  auction,
  fixedPrice
}

class WatchlistItem {
  final String id;
  final String itemId; // Can be auctionId or fixedPriceListingId
  final WatchlistItemType itemType;
  final String userId;
  final DateTime createdAt;
  final double? maxAutoBidAmount; // Only for auctions
  final bool notificationsEnabled;
  
  WatchlistItem({
    String? id,
    required this.itemId,
    required this.itemType,
    required this.userId,
    DateTime? createdAt,
    this.maxAutoBidAmount,
    this.notificationsEnabled = true,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();
  
  /// Convert to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'item_type': itemType.toString().split('.').last, // 'auction' or 'fixedPrice'
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'max_auto_bid_amount': maxAutoBidAmount,
      'notifications_enabled': notificationsEnabled,
    };
  }
  
  /// Create from Supabase Map
  factory WatchlistItem.fromMap(Map<String, dynamic> map) {
    return WatchlistItem(
      id: map['id'],
      itemId: map['item_id'],
      itemType: map['item_type'] == 'auction' 
          ? WatchlistItemType.auction 
          : WatchlistItemType.fixedPrice,
      userId: map['user_id'],
      createdAt: DateTime.parse(map['created_at']),
      maxAutoBidAmount: map['max_auto_bid_amount'] != null 
          ? (map['max_auto_bid_amount'] as num).toDouble() 
          : null,
      notificationsEnabled: map['notifications_enabled'] ?? true,
    );
  }
  
  /// Create a copy with modified properties
  WatchlistItem copyWith({
    String? id,
    String? itemId,
    WatchlistItemType? itemType,
    String? userId,
    DateTime? createdAt,
    double? maxAutoBidAmount,
    bool? notificationsEnabled,
  }) {
    return WatchlistItem(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      maxAutoBidAmount: maxAutoBidAmount ?? this.maxAutoBidAmount,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
  
  @override
  String toString() {
    return 'WatchlistItem(id: $id, itemId: $itemId, itemType: $itemType, userId: $userId)';
  }
}