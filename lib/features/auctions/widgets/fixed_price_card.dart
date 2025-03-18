import 'package:flutter/material.dart';

import '../../../core/utils/helpers.dart';

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
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.quantityAvailable,
    this.quantitySold = 0,
    required this.imageUrls,
    this.isFeatured = false,
    required this.createdAt,
    this.featuredUntil,
    this.isActive = true,
  });
  
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
      featuredUntil: map['featured_until'] != null ? DateTime.parse(map['featured_until']) : null,
      isActive: map['is_active'] ?? true,
    );
  }
}

class FixedPriceCard extends StatelessWidget {
  final FixedPriceListing listing;
  final bool isSaved;
  final VoidCallback onSavedToggle;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  const FixedPriceCard({
    Key? key,
    required this.listing,
    required this.isSaved,
    required this.onSavedToggle,
    required this.onTap,
    required this.onAddToCart,
    required this.onBuyNow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasImages = listing.imageUrls.isNotEmpty;
    final isAvailable = listing.quantityAvailable > 0 && listing.isActive;
    
    // Format price
    final price = formatCurrency(listing.price);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with badges
            Stack(
              children: [
                // Main image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: hasImages
                        ? Image.network(
                            listing.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                
                // Featured badge
                if (listing.isFeatured)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Featured',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                
                // Availability badge
                Positioned(
                  top: listing.isFeatured ? 45 : 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAvailable ? 'Available' : 'Sold Out',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                
                // Save button
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? Colors.blue : Colors.white,
                    ),
                    onPressed: onSavedToggle,
                    tooltip: isSaved ? 'Remove from saved' : 'Save for later',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.3),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content area
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    listing.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Price and quantity info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      
                      // Quantity
                      Text(
                        '${listing.quantityAvailable} available',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: isAvailable ? onAddToCart : null,
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('Add to Cart'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: isAvailable ? onBuyNow : null,
                        icon: const Icon(Icons.flash_on),
                        label: const Text('Buy Now'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}