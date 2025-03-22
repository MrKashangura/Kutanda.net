// lib/features/auctions/screens/auction_detail_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/helpers.dart';
import '../../../data/models/auction_model.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/services/onesignal_service.dart';
import '../../auth/widgets/countdown_timer.dart';
import '../services/auction_service.dart';
import '../services/auto_bid_service.dart';
import '../services/recommendation_service.dart';
import '../services/watchlist_service.dart';
import '../widgets/auto_bid_widget.dart';
import '../widgets/bid_history_widget.dart';

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
  final WatchlistService _watchlistService = WatchlistService();
  final AutoBidService _autoBidService = AutoBidService();
  final RecommendationService _recommendationService = RecommendationService();
  final NotificationService _notificationService = NotificationService();
  final OneSignalService _oneSignalService = OneSignalService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  late StreamSubscription<List<Map<String, dynamic>>> _bidsSubscription;
  
  bool _isLoading = true;
  Auction? _auction;
  List<Map<String, dynamic>> _bids = [];
  List<Auction> _similarAuctions = [];
  bool _isWatchlisted = false;
  bool _showBidHistory = false;
  bool _showAutoBid = false;
  bool _isBidding = false;
  bool _isAutoBidActive = false;
  Map<String, dynamic>? _sellerProfile;
  
  final TextEditingController _bidController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PageController _imageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadAuctionData();
  }
  
  @override
  void dispose() {
    _bidController.dispose();
    _scrollController.dispose();
    _imageController.dispose();
    _bidsSubscription.cancel();
    super.dispose();
  }
  
  Future<void> _initializeServices() async {
    try {
      await _notificationService.initialize();
      await _oneSignalService.initialize();
    } catch (e) {
      // Silently handle initialization failures
      debugPrint('Warning: Could not initialize services: $e');
    }
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
      
      // Subscribe to real-time bid updates
      _bidsSubscription = _auctionService.listenToBids(widget.auctionId)
          .listen(_onBidsUpdated);
      
      // Get seller profile
      final sellerProfile = await _supabase
          .from('profiles')
          .select('display_name, email, avatar_url, rating')
          .eq('id', auction.sellerId)
          .maybeSingle();
      
      // Check if auction is in watchlist
      final user = _supabase.auth.currentUser;
      bool isWatchlisted = false;
      bool isAutoBidActive = false;
      
      if (user != null) {
        final watchlistData = await _watchlistService.isInWatchlist(widget.auctionId);
        isWatchlisted = watchlistData;
        
        // Check for auto-bid configuration
        final autoBidData = await _autoBidService.getAutoBid(widget.auctionId);
        isAutoBidActive = autoBidData != null && (autoBidData['is_active'] ?? false);
      }
      
      // Get similar auctions
      final similarAuctions = await _recommendationService.getSimilarAuctions(widget.auctionId);
      
      if (mounted) {
        setState(() {
          _auction = auction;
          _sellerProfile = sellerProfile;
          _isWatchlisted = isWatchlisted;
          _isAutoBidActive = isAutoBidActive;
          _similarAuctions = similarAuctions;
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
  
  void _onBidsUpdated(List<Map<String, dynamic>> bids) {
    if (mounted) {
      setState(() {
        _bids = bids;
        
        // If the auction was updated, refresh auction data
        if (bids.isNotEmpty && _auction != null) {
          final latestBid = bids.first;
          final bidAmount = (latestBid['amount'] as num?)?.toDouble() ?? 0.0;
          
          if (bidAmount > _auction!.highestBid) {
            _loadAuctionData();
          }
        }
      });
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
      setState(() => _isLoading = true);
      
      if (_isWatchlisted) {
        // Remove from watchlist
        await _watchlistService.removeFromWatchlist(widget.auctionId);
        
        setState(() => _isWatchlisted = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from watchlist')),
          );
        }
      } else {
        // Add to watchlist
        await _watchlistService.addToWatchlist(widget.auctionId, WatchlistItemType.auction);
        
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bid of ${formatCurrency(bidAmount)} placed successfully!')),
        );
        
        // Notify about bid
        _notificationService.showBidPlacedNotification(_auction!.title, bidAmount);
        
        // Add to watchlist if not already
        if (!_isWatchlisted) {
          await _watchlistService.addToWatchlist(_auction!.id, WatchlistItemType.auction);
          setState(() => _isWatchlisted = true);
        }
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
  
  void _toggleBidHistory() {
    setState(() => _showBidHistory = !_showBidHistory);
  }
  
  void _toggleAutoBid() {
    setState(() => _showAutoBid = !_showAutoBid);
  }
  
  void _handleAutoBidUpdated(bool isActive) {
    setState(() => _isAutoBidActive = isActive);
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
            child: ListView(
              controller: _scrollController,
              children: [
                // Image gallery
                Stack(
                  children: [
                    Container(
                      height: 250,
                      child: PageView.builder(
                        controller: _imageController,
                        onPageChanged: (index) {
                          setState(() => _currentImageIndex = index);
                        },
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
                    
                    // Status badge
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
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
                    ),
                    
                    // Image indicators
                    if (auction.imageUrls.length > 1)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            auction.imageUrls.length,
                            (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Theme.of(context).primaryColor
                                    : Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Main content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        auction.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Seller info
                      _buildSellerCard(),
                      
                      const SizedBox(height: 16),
                      
                      // Bid & timer section
                      _buildBidSection(currentBid, startingPrice, isEnded),
                      
                      const SizedBox(height: 16),
                      
                      // Auto-bid toggle
                      if (!isEnded) 
                        OutlinedButton.icon(
                          onPressed: _toggleAutoBid,
                          icon: Icon(
                            Icons.auto_awesome,
                            color: _isAutoBidActive ? Colors.amber : Colors.grey,
                          ),
                          label: Text(_isAutoBidActive
                              ? 'Auto-Bid Active - Manage'
                              : 'Set Up Auto-Bid'),
                        ),
                      
                      // Auto-bid widget
                      if (_showAutoBid && !isEnded)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: AutoBidWidget(
                            auctionId: auction.id,
                            currentBid: auction.highestBid,
                            bidIncrement: auction.bidIncrement,
                            onAutoBidSet: _handleAutoBidUpdated,
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Bid history
                      BidHistoryWidget(
                        auctionId: auction.id,
                        isExpanded: _showBidHistory,
                        onToggleExpanded: _toggleBidHistory,
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
                      
                      const SizedBox(height: 32),
                      
                      // Similar auctions
                      if (_similarAuctions.isNotEmpty) ...[
                        const Text(
                          'Similar Auctions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSimilarAuctions(),
                      ],
                      
                      const SizedBox(height: 100), // Space for bid input
                    ],
                  ),
                ),
              ],
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
  
  Widget _buildSellerCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 24,
              backgroundImage: _sellerProfile?['avatar_url'] != null 
                  ? NetworkImage(_sellerProfile!['avatar_url']) 
                  : null,
              child: _sellerProfile?['avatar_url'] == null 
                  ? const Icon(Icons.person) 
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seller',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _sellerProfile?['display_name'] ?? 
                    _sellerProfile?['email'] ?? 
                    'Plant Enthusiast',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (_sellerProfile?['rating'] != null)
                    Row(
                      children: [
                        ...List.generate(
                          5, 
                          (index) => Icon(
                            index < (_sellerProfile!['rating'] as num).round()
                                ? Icons.star
                                : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          ),
                        ),
                      ],
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
    );
  }
  
  Widget _buildBidSection(String currentBid, String startingPrice, bool isEnded) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bid info
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
              const SizedBox(height: 4),
              Text(
                'Starting: $startingPrice',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              // Highest bidder info
              if (_auction!.highestBidderId != null && _bids.isNotEmpty) ...[
                const Text(
                  'Highest Bidder',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _getBidderName(_bids.first),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Time remaining
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
                endTime: _auction!.endTime,
                textStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isEnded ? Colors.red : Colors.blue,
                ),
                onTimerEnd: () {
                  // Refresh when timer ends
                  if (mounted) {
                    _loadAuctionData();
                  }
                },
              ),
              const SizedBox(height: 8),
              // Bid count
              Text(
                '${_bids.length} ${_bids.length == 1 ? 'bid' : 'bids'} so far',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              TextButton(
                onPressed: _toggleBidHistory,
                child: Text(_showBidHistory ? 'Hide Bid History' : 'Show Bid History'),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSimilarAuctions() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _similarAuctions.length,
        itemBuilder: (context, index) {
          final auction = _similarAuctions[index];
          
          return SizedBox(
            width: 220,
            child: Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AuctionDetailScreen(auctionId: auction.id),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: auction.imageUrls.isNotEmpty
                          ? Image.network(
                              auction.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported, size: 40),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 40),
                            ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            auction.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Current bid
                          Text(
                            formatCurrency(auction.highestBid),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          
                          // Time remaining
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ends:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: CountdownTimer(
                                  endTime: auction.endTime,
                                  textStyle: TextStyle(
                                    fontSize: 12,
                                    color: DateTime.now().isAfter(auction.endTime)
                                        ? Colors.red
                                        : Colors.blue,
                                  ),
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
            ),
          );
        },
      ),
    );
  }
  
  String _getBidderName(Map<String, dynamic> bid) {
    final bidder = bid['bidder'] as Map<String, dynamic>?;
    if (bidder == null) return 'Unknown';
    
    final displayName = bidder['display_name'];
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    
    final email = bidder['email'];
    if (email != null && email.isNotEmpty) {
      return email.toString().split('@').first;
    }
    
    return 'Unknown';
  }
}