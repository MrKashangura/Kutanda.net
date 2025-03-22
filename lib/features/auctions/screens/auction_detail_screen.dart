import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/helpers.dart';
import '../../../data/models/auction_model.dart';
import '../../../shared/services/notification_service.dart';
import '../../auth/widgets/countdown_timer.dart';
import '../services/auction_service.dart';

class AuctionDetailScreen extends StatefulWidget {
  final String auctionId;
  
  const AuctionDetailScreen({
    super.key,
    required this.auctionId,
  });

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  final AuctionService _auctionService = AuctionService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();
  
  bool _isLoading = true;
  Auction? _auction;
  List<Map<String, dynamic>> _bids = [];
  bool _isWatchlisted = false;
  bool _showBidHistory = false;
  bool _isBidding = false;
  
  final TextEditingController _bidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAuctionData();
    _initNotifications();
  }
  
  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }
  
  Future<void> _initNotifications() async {
    await _notificationService.initialize();
  }

  Future<void> _loadAuctionData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load auction details
      final auctionData = await _supabase
          .from('auctions')
          .select()
          .eq('id', widget.auctionId)
          .single();
      
      final auction = Auction.fromMap(auctionData);
      
      // Load bid history
      final bidsData = await _supabase
          .from('bids')
          .select('*, bidder:profiles!bidder_id(display_name, email)')
          .eq('auction_id', widget.auctionId)
          .order('created_at', ascending: false);
      
      // Check if auction is in watchlist
      final user = _supabase.auth.currentUser;
      bool isWatchlisted = false;
      
      if (user != null) {
        final watchlistData = await _supabase
            .from('watchlist')
            .select()
            .eq('user_id', user.id)
            .eq('item_id', widget.auctionId)
            .eq('item_type', 'auction')
            .maybeSingle();
        
        isWatchlisted = watchlistData != null;
      }
      
      if (mounted) {
        setState(() {
          _auction = auction;
          _bids = List<Map<String, dynamic>>.from(bidsData);
          _isWatchlisted = isWatchlisted;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading auction: $e')),
        );
      }
    }
  }
  
  Future<void> _toggleWatchlist() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to use the watchlist')),
      );
      return;
    }
    
    try {
      if (_isWatchlisted) {
        // Remove from watchlist
        await _supabase
            .from('watchlist')
            .delete()
            .eq('user_id', user.id)
            .eq('item_id', widget.auctionId);
        
        setState(() => _isWatchlisted = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from watchlist')),
          );
        }
      } else {
        // Add to watchlist
        await _supabase.from('watchlist').insert({
          'user_id': user.id,
          'item_id': widget.auctionId,
          'item_type': 'auction',
          'created_at': DateTime.now().toIso8601String(),
        });
        
        setState(() => _isWatchlisted = true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to watchlist')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating watchlist: $e')),
        );
      }
    }
  }
  
  Future<void> _placeBid() async {
    if (_auction == null) return;
    
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to place a bid')),
      );
      return;
    }
    
    final bidAmountText = _bidController.text.trim();
    if (bidAmountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a bid amount')),
      );
      return;
    }
    
    final bidAmount = double.tryParse(bidAmountText);
    if (bidAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid bid amount')),
      );
      return;
    }
    
    final minimumBid = _auction!.highestBid + _auction!.bidIncrement;
    if (bidAmount < minimumBid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Minimum bid is ${formatCurrency(minimumBid)}')),
      );
      return;
    }
    
    setState(() => _isBidding = true);
    
    try {
      await _auctionService.placeBid(_auction!.id, bidAmount, user.id);
      
      // Clear bid input
      _bidController.clear();
      
      // Reload auction data
      await _loadAuctionData();
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bid of ${formatCurrency(bidAmount)} placed successfully!')),
        );
        
        // Notify about bid
        _notificationService.showBidPlacedNotification(_auction!.title, bidAmount);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing bid: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBidding = false);
      }
    }
  }
  
  void _showBidHistorySheet() {
    setState(() => _showBidHistory = true);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bid History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Bid list
                  Expanded(
                    child: _bids.isEmpty
                        ? const Center(child: Text('No bids yet'))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _bids.length,
                            itemBuilder: (context, index) {
                              final bid = _bids[index];
                              final bidder = bid['bidder'] as Map<String, dynamic>?;
                              final bidAmount = (bid['amount'] as num).toDouble();
                              final bidTime = DateTime.parse(bid['created_at']);
                              final isAutoBid = bid['is_auto_bid'] ?? false;
                              
                              return ListTile(
                                title: Text(
                                  bidder?['display_name'] ?? bidder?['email'] ?? 'Anonymous',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(formatRelativeTime(bidTime)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      formatCurrency(bidAmount),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (isAutoBid) ...[
                                      const SizedBox(width: 4),
                                      const Tooltip(
                                        message: 'Auto Bid',
                                        child: Icon(Icons.auto_awesome, size: 16),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() => _showBidHistory = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Auction...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_auction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auction')),
        body: const Center(child: Text('Auction not found')),
      );
    }
    
    final auction = _auction!;
    final now = DateTime.now();
    final isEnded = now.isAfter(auction.endTime);
    
    // Format price details
    final currentBid = formatCurrency(auction.highestBid);
    final startingPrice = formatCurrency(auction.startingPrice);
    final minimumBid = formatCurrency(auction.highestBid + auction.bidIncrement);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auction Details'),
        actions: [
          IconButton(
            icon: Icon(
              _isWatchlisted ? Icons.favorite : Icons.favorite_border,
              color: _isWatchlisted ? Colors.red : null,
            ),
            onPressed: _toggleWatchlist,
            tooltip: _isWatchlisted ? 'Remove from watchlist' : 'Add to watchlist',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share auction functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon')),
              );
            },
            tooltip: 'Share',
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image carousel
                  SizedBox(
                    height: 250,
                    child: PageView.builder(
                      itemCount: auction.imageUrls.isEmpty ? 1 : auction.imageUrls.length,
                      itemBuilder: (context, index) {
                        if (auction.imageUrls.isEmpty) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image, size: 100, color: Colors.grey),
                            ),
                          );
                        }
                        
                        return Image.network(
                          auction.imageUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 100, color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and status
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                auction.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isEnded ? Colors.red : Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isEnded ? 'Ended' : 'Active',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Seller info (in a card)
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.grey[300],
                                  radius: 20,
                                  child: const Icon(Icons.person),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Seller',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'Plant Enthusiast',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.verified, size: 16, color: Colors.green[800]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Price and bid information
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Current Bid',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    currentBid,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  Text(
                                    'Starting: $startingPrice',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Time Remaining',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  CountdownTimer(
                                    endTime: auction.endTime,
                                    textStyle: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isEnded ? Colors.red : Colors.blue,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _bids.isEmpty ? null : _showBidHistorySheet,
                                    child: Text(
                                      _bids.isEmpty
                                          ? 'No bids yet'
                                          : 'View ${_bids.length} bid${_bids.length == 1 ? '' : 's'}',
                                      style: TextStyle(
                                        color: _bids.isEmpty ? Colors.grey : Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Description section
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          auction.description,
                          style: const TextStyle(fontSize: 16),
                        ),
                        
                        const SizedBox(height: 100), // Space for the bottom bid section
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Fixed bid section at the bottom
          if (!isEnded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Minimum bid: $minimumBid',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Bid input field
                      Expanded(
                        child: TextField(
                          controller: _bidController,
                          decoration: InputDecoration(
                            labelText: 'Your bid amount',
                            border: const OutlineInputBorder(),
                            prefixText: '\$',
                            hintText: auction.highestBid + auction.bidIncrement > 0
                                ? (auction.highestBid + auction.bidIncrement).toStringAsFixed(2)
                                : '0.00',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          enabled: !_isBidding,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Place bid button
                      ElevatedButton(
                        onPressed: _isBidding ? null : _placeBid,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                        child: _isBidding
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Place Bid'),
                      ),
                    ],
                  ),
                  // Quick bid buttons
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Minimum bid
                        TextButton(
                          onPressed: _isBidding
                              ? null
                              : () {
                                  _bidController.text =
                                      (auction.highestBid + auction.bidIncrement).toStringAsFixed(2);
                                },
                          child: Text('Min (${formatCurrency(auction.highestBid + auction.bidIncrement)})'),
                        ),
                        // Min + 10%
                        TextButton(
                          onPressed: _isBidding
                              ? null
                              : () {
                                  final amount =
                                      auction.highestBid + auction.bidIncrement * 2;
                                  _bidController.text = amount.toStringAsFixed(2);
                                },
                          child: Text('Min +\$${auction.bidIncrement.toStringAsFixed(2)}'),
                        ),
                        // Min + 20%
                        TextButton(
                          onPressed: _isBidding
                              ? null
                              : () {
                                  final amount =
                                      auction.highestBid + auction.bidIncrement * 4;
                                  _bidController.text = amount.toStringAsFixed(2);
                                },
                          child: Text('Min +\$${(auction.bidIncrement * 3).toStringAsFixed(2)}'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}