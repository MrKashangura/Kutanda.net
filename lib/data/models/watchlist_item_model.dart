// lib/data/models/watchlist_item_model.dart
class WatchlistItem {
  final String id;
  final String itemId; // Can be auctionId or fixedPriceListingId
  final String itemType; // "auction" or "fixedPrice"
  final String userId;
  final DateTime createdAt;
  final double? maxAutoBidAmount; // Only for auctions
  final bool notificationsEnabled;
  
  WatchlistItem({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.userId,
    required this.createdAt,
    this.maxAutoBidAmount,
    this.notificationsEnabled = true,
  });
  
  factory WatchlistItem.fromMap(Map<String, dynamic> map) {
    return WatchlistItem(
      id: map['id'],
      itemId: map['item_id'],
      itemType: map['item_type'],
      userId: map['user_id'],
      createdAt: DateTime.parse(map['created_at']),
      maxAutoBidAmount: map['max_auto_bid_amount'] != null 
          ? (map['max_auto_bid_amount'] as num).toDouble() 
          : null,
      notificationsEnabled: map['notifications_enabled'] ?? true,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'item_type': itemType,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'max_auto_bid_amount': maxAutoBidAmount,
      'notifications_enabled': notificationsEnabled,
    };
  }
}