// lib/data/models/fixed_price_listing_model.dart
import 'package:uuid/uuid.dart';

class FixedPriceListing {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final double price;
  final int quantityAvailable;
  final int quantitySold;
  final List<String> imageUrls;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime? featuredUntil;
  final bool isActive;
  
  FixedPriceListing({
    String? id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.quantityAvailable,
    this.quantitySold = 0,
    required this.imageUrls,
    this.isFeatured = false,
    DateTime? createdAt,
    this.featuredUntil,
    this.isActive = true,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();
  
  /// Convert to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'price': price,
      'quantity_available': quantityAvailable,
      'quantity_sold': quantitySold,
      'image_urls': imageUrls,
      'is_featured': isFeatured,
      'created_at': createdAt.toIso8601String(),
      'featured_until': featuredUntil?.toIso8601String(),
      'is_active': isActive,
    };
  }
  
  /// Create from Supabase Map
  factory FixedPriceListing.fromMap(Map<String, dynamic> map) {
    return FixedPriceListing(
      id: map['id'],
      sellerId: map['seller_id'],
      title: map['title'],
      description: map['description'],
      price: (map['price'] as num).toDouble(),
      quantityAvailable: map['quantity_available'],
      quantitySold: map['quantity_sold'] ?? 0,
      imageUrls: List<String>.from(map['image_urls']),
      isFeatured: map['is_featured'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
      featuredUntil: map['featured_until'] != null 
          ? DateTime.parse(map['featured_until']) 
          : null,
      isActive: map['is_active'] ?? true,
    );
  }
  
  /// Create a copy with modified properties
  FixedPriceListing copyWith({
    String? id,
    String? sellerId,
    String? title,
    String? description,
    double? price,
    int? quantityAvailable,
    int? quantitySold,
    List<String>? imageUrls,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? featuredUntil,
    bool? isActive,
  }) {
    return FixedPriceListing(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      quantitySold: quantitySold ?? this.quantitySold,
      imageUrls: imageUrls ?? this.imageUrls,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      featuredUntil: featuredUntil ?? this.featuredUntil,
      isActive: isActive ?? this.isActive,
    );
  }
  
  @override
  String toString() {
    return 'FixedPriceListing(id: $id, title: $title, price: $price, qty: $quantityAvailable)';
  }
}