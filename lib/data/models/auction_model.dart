class Auction {
  String id;
  String sellerId;
  String title;
  String description;
  double startingPrice;
  double highestBid;
  double bidIncrement;
  String? highestBidderId;
  DateTime endTime; // ✅ Use DateTime for Supabase compatibility
  List<String> imageUrls;
  bool isActive;
  bool endingNotified; // Tracks if ending notification was sent

  Auction({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.startingPrice,
    double? highestBid,
    this.highestBidderId,
    required this.bidIncrement,
    required this.endTime,
    required this.imageUrls,
    required this.isActive,
    this.endingNotified = false,
  }) : highestBid = highestBid ?? startingPrice; // ✅ Default highestBid to startingPrice

  /// **Convert Auction to Supabase Map**
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'starting_price': startingPrice,
      'highest_bid': highestBid,
      'bid_increment': bidIncrement, // ✅ FIXED: Include bidIncrement
      'highest_bidder_id': highestBidderId,
      'end_time': endTime.toIso8601String(), // ✅ Convert DateTime to ISO string
      'image_urls': imageUrls,
      'is_active': isActive,
      'ending_notified': endingNotified,
    };
  }

  /// **Create Auction from Supabase Map**
  factory Auction.fromMap(Map<String, dynamic> map) {
    return Auction(
      id: map['id'],
      sellerId: map['seller_id'],
      title: map['title'],
      description: map['description'],
      startingPrice: (map['starting_price'] as num).toDouble(),
      highestBid: (map['highest_bid'] as num?)?.toDouble() ?? (map['starting_price'] as num).toDouble(),
      bidIncrement: (map['bid_increment'] as num).toDouble(), // ✅ Ensure bid_increment is fetched
      highestBidderId: map['highest_bidder_id'],
      endTime: DateTime.parse(map['end_time']), // ✅ Convert from ISO 8601 string
      imageUrls: List<String>.from(map['image_urls']),
      isActive: map['is_active'],
      endingNotified: map['ending_notified'] ?? false,
    );
  }
}

