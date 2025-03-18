import 'package:flutter/material.dart';

import '../../../core/utils/helpers.dart';
import '../../../data/models/auction_model.dart';
import '../../auth/widgets/countdown_timer.dart';

class AuctionCard extends StatelessWidget {
  final Auction auction;
  final bool isWatchlisted;
  final VoidCallback onWatchlistToggle;
  final VoidCallback onTap;
  final VoidCallback onBid;

  const AuctionCard({
    Key? key,
    required this.auction,
    required this.isWatchlisted,
    required this.onWatchlistToggle,
    required this.onTap,
    required this.onBid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if auction is active and not ended
    final now = DateTime.now();
    final isEnded = now.isAfter(auction.endTime);
    final hasImages = auction.imageUrls.isNotEmpty;
    
    // Format price details
    final currentBid = formatCurrency(auction.highestBid);
    final startingPrice = formatCurrency(auction.startingPrice);
    
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
                            auction.imageUrls.first,
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
                
                // Status badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isEnded ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isEnded ? 'Ended' : 'Active',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                
                // Watchlist button
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      isWatchlisted ? Icons.favorite : Icons.favorite_border,
                      color: isWatchlisted ? Colors.red : Colors.white,
                    ),
                    onPressed: onWatchlistToggle,
                    tooltip: isWatchlisted ? 'Remove from watchlist' : 'Add to watchlist',
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
                    auction.title,
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
                    auction.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Price and time info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price information
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Bid: $currentBid',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          Text(
                            'Starting: $startingPrice',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      
                      // Time remaining
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Time Remaining:',
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                          CountdownTimer(
                            endTime: auction.endTime,
                            textStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isEnded ? Colors.red : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.visibility),
                        label: const Text('Details'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: isEnded ? null : onBid,
                        icon: const Icon(Icons.gavel),
                        label: const Text('Place Bid'),
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