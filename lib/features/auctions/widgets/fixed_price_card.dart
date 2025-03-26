import 'package:flutter/material.dart';

import '../../../core/utils/helpers.dart';
import '../../../data/models/fixed_price_listing_model.dart';

class FixedPriceCard extends StatelessWidget {
  final FixedPriceListing listing;
  final bool isSaved;
  final VoidCallback onSavedToggle;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  const FixedPriceCard({
    super.key,
    required this.listing,
    required this.isSaved,
    required this.onSavedToggle,
    required this.onTap,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final hasImages = listing.imageUrls.isNotEmpty;
    final isAvailable = listing.quantityAvailable > 0 && listing.isActive;
    final isLowStock = isAvailable && listing.quantityAvailable < 5;
    
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
                      color: isAvailable 
                          ? (isLowStock ? Colors.orange : Colors.green)
                          : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAvailable
                              ? (isLowStock ? Icons.inventory_2 : Icons.check_circle)
                              : Icons.cancel,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAvailable
                              ? (isLowStock 
                                  ? 'Low Stock (${listing.quantityAvailable})'
                                  : 'In Stock (${listing.quantityAvailable})')
                              : 'Out of Stock',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                      
                      // Availability indicator for narrow screens
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable 
                              ? (isLowStock ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1))
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isAvailable 
                                ? (isLowStock ? Colors.orange : Colors.green)
                                : Colors.red,
                          ),
                        ),
                        child: Text(
                          isAvailable
                              ? (isLowStock 
                                  ? 'Only ${listing.quantityAvailable} left'
                                  : '${listing.quantityAvailable} available')
                              : 'Sold out',
                          style: TextStyle(
                            color: isAvailable 
                                ? (isLowStock ? Colors.orange[800] : Colors.green[800])
                                : Colors.red[800],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
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