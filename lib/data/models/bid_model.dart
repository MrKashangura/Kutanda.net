// lib/data/models/bid_model.dart
class Bid {
  final String id;
  final String auctionId;
  final String bidderId;
  final double amount;
  final DateTime timestamp;
  final bool isAutoBid;
  final String? previousHighestBidderId;
  
  Bid({
    required this.id,
    required this.auctionId,
    required this.bidderId,
    required this.amount,
    required this.timestamp,
    this.isAutoBid = false,
    this.previousHighestBidderId,
  });
  
  factory Bid.fromMap(Map<String, dynamic> map) {
    return Bid(
      id: map['id'],
      auctionId: map['auction_id'],
      bidderId: map['bidder_id'],
      amount: (map['amount'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] ?? map['created_at']),
      isAutoBid: map['is_auto_bid'] ?? false,
      previousHighestBidderId: map['previous_highest_bidder_id'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auction_id': auctionId,
      'bidder_id': bidderId,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'is_auto_bid': isAutoBid,
      'previous_highest_bidder_id': previousHighestBidderId,
    };
  }
}