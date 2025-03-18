// lib/data/models/bid_model.dart
import 'package:uuid/uuid.dart';

class Bid {
  final String id;
  final String auctionId;
  final String bidderId;
  final double amount;
  final DateTime timestamp;
  final bool isAutoBid;
  final String? previousHighestBidderId;
  
  Bid({
    String? id,
    required this.auctionId,
    required this.bidderId,
    required this.amount,
    DateTime? timestamp,
    this.isAutoBid = false,
    this.previousHighestBidderId,
  }) : 
    id = id ?? const Uuid().v4(),
    timestamp = timestamp ?? DateTime.now();
  
  /// Convert to Map for Supabase
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
  
  /// Create from Supabase Map
  factory Bid.fromMap(Map<String, dynamic> map) {
    return Bid(
      id: map['id'],
      auctionId: map['auction_id'],
      bidderId: map['bidder_id'],
      amount: (map['amount'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
      isAutoBid: map['is_auto_bid'] ?? false,
      previousHighestBidderId: map['previous_highest_bidder_id'],
    );
  }
  
  /// Create a copy with modified properties
  Bid copyWith({
    String? id,
    String? auctionId,
    String? bidderId,
    double? amount,
    DateTime? timestamp,
    bool? isAutoBid,
    String? previousHighestBidderId,
  }) {
    return Bid(
      id: id ?? this.id,
      auctionId: auctionId ?? this.auctionId,
      bidderId: bidderId ?? this.bidderId,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      isAutoBid: isAutoBid ?? this.isAutoBid,
      previousHighestBidderId: previousHighestBidderId ?? this.previousHighestBidderId,
    );
  }
  
  @override
  String toString() {
    return 'Bid(id: $id, amount: $amount, bidderId: $bidderId, time: $timestamp)';
  }
}

class AutoBid {
  final String id;
  final String auctionId;
  final String bidderId;
  final double maxAmount;
  final double increment;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  
  AutoBid({
    String? id,
    required this.auctionId,
    required this.bidderId,
    required this.maxAmount,
    required this.increment,
    this.isActive = true,
    DateTime? createdAt,
    this.lastUpdated,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();
  
  /// Convert to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auction_id': auctionId,
      'bidder_id': bidderId,
      'max_amount': maxAmount,
      'increment': increment,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }
  
  /// Create from Supabase Map
  factory AutoBid.fromMap(Map<String, dynamic> map) {
    return AutoBid(
      id: map['id'],
      auctionId: map['auction_id'],
      bidderId: map['bidder_id'],
      maxAmount: (map['max_amount'] as num).toDouble(),
      increment: (map['increment'] as num).toDouble(),
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
      lastUpdated: map['last_updated'] != null 
          ? DateTime.parse(map['last_updated']) 
          : null,
    );
  }
  
  /// Create a copy with modified properties
  AutoBid copyWith({
    String? id,
    String? auctionId,
    String? bidderId,
    double? maxAmount,
    double? increment,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return AutoBid(
      id: id ?? this.id,
      auctionId: auctionId ?? this.auctionId,
      bidderId: bidderId ?? this.bidderId,
      maxAmount: maxAmount ?? this.maxAmount,
      increment: increment ?? this.increment,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  @override
  String toString() {
    return 'AutoBid(id: $id, maxAmount: $maxAmount, bidderId: $bidderId, active: $isActive)';
  }
}