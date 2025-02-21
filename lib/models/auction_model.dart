import 'package:cloud_firestore/cloud_firestore.dart';

class Auction {
  String id;
  String sellerId;
  String title;
  String description;
  double startingPrice;
  double highestBid;
  String? highestBidderId;
  Timestamp endTime; // ✅ Firestore-compatible Timestamp
  List<String> imageUrls;
  bool isActive;

  Auction({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.startingPrice,
    double? highestBid, // ✅ Ensure default bid is set
    this.highestBidderId,
    required this.endTime,
    required this.imageUrls,
    required this.isActive,
  }) : highestBid = highestBid ?? startingPrice; // ✅ Default highestBid to startingPrice

  // ✅ Convert Auction to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'startingPrice': startingPrice,
      'highestBid': highestBid,
      'highestBidderId': highestBidderId,
      'endTime': endTime, // ✅ Stored as Timestamp in Firestore
      'imageUrls': imageUrls,
      'isActive': isActive,
    };
  }

  // ✅ Create Auction from Firestore Map
  factory Auction.fromMap(Map<String, dynamic> map, String documentId) {
    return Auction(
      id: documentId,
      sellerId: map['sellerId'],
      title: map['title'],
      description: map['description'],
      startingPrice: (map['startingPrice'] as num).toDouble(), // ✅ Convert to double safely
      highestBid: (map['highestBid'] as num?)?.toDouble() ?? (map['startingPrice'] as num).toDouble(),
      highestBidderId: map['highestBidderId'],
      endTime: map['endTime'], // ✅ Firestore Timestamp (No conversion needed)
      imageUrls: List<String>.from(map['imageUrls']),
      isActive: map['isActive'],
    );
  }
}
