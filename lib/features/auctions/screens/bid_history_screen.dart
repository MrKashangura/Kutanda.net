// lib/features/auctions/screens/bid_history_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/helpers.dart';
import '../../../data/models/auction_model.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import 'auction_detail_screen.dart';

class BidHistoryScreen extends StatefulWidget {
  const BidHistoryScreen({super.key});

  @override
  State<BidHistoryScreen> createState() => _BidHistoryScreenState();
}

class _BidHistoryScreenState extends State<BidHistoryScreen> with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allBids = [];
  List<Map<String, dynamic>> _activeBids = [];
  List<Map<String, dynamic>> _completedBids = [];
  List<Map<String, dynamic>> _wonBids = [];
  final Map<String, Auction?> _auctionCache = {};
  
  // Stats
  int _totalBids = 0;
  int _wonAuctions = 0;
  double _successRate = 0.0;
  double _averageBid = 0.0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBidHistory();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBidHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Fetch all bids by this user
      final response = await _supabase
          .from('bids')
          .select('*, auction_id')
          .eq('bidder_id', user.id)
          .order('created_at', ascending: false);
      
      final bids = List<Map<String, dynamic>>.from(response);
      _allBids = bids;
      
      // Load auction details for each bid
      final Set<String> auctionIds = {};
      for (final bid in _allBids) {
        auctionIds.add(bid['auction_id'] as String);
      }
      
      for (final auctionId in auctionIds) {
        final auctionData = await _supabase
            .from('auctions')
            .select()
            .eq('id', auctionId)
            .maybeSingle();
        
        if (auctionData != null) {
          _auctionCache[auctionId] = Auction.fromMap(auctionData);
        }
      }
      
      // Sort bids into categories
      _categorizeAndCalculateStats(user.id);
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bid history: $e')),
        );
      }
    }
  }
  
  void _categorizeAndCalculateStats(String userId) {
    final now = DateTime.now();
    _activeBids = [];
    _completedBids = [];
    _wonBids = [];
    
    double totalBidAmount = 0;
    int completedAuctions = 0;
    
    for (final bid in _allBids) {
      final auctionId = bid['auction_id'] as String;
      final auction = _auctionCache[auctionId];
      final bidAmount = (bid['amount'] as num).toDouble();
      
      totalBidAmount += bidAmount;
      
      if (auction != null) {
        // Determine if auction has ended
        if (now.isAfter(auction.endTime)) {
          completedAuctions++;
          _completedBids.add(bid);
          
          // Check if user won this auction
          if (auction.highestBidderId == userId) {
            _wonBids.add(bid);
          }
        } else {
          _activeBids.add(bid);
        }
      }
    }
    
    // Calculate stats
    _totalBids = _allBids.length;
    _wonAuctions = _wonBids.length;
    _successRate = completedAuctions > 0
        ? (_wonAuctions / completedAuctions) * 100
        : 0.0;
    _averageBid = _totalBids > 0
        ? totalBidAmount / _totalBids
        : 0.0;
  }
  
  String _getBidStatus(Map<String, dynamic> bid, String userId) {
    final auctionId = bid['auction_id'] as String;
    final auction = _auctionCache[auctionId];
    final now = DateTime.now();
    
    if (auction == null) {
      return 'Unknown';
    }
    
    if (now.isAfter(auction.endTime)) {
      // Auction has ended
      if (auction.highestBidderId == userId) {
        return 'Won';
      } else {
        return 'Lost';
      }
    } else {
      // Auction is still active
      if (auction.highestBidderId == userId) {
        return 'Winning';
      } else {
        return 'Outbid';
      }
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Won':
        return Colors.green;
      case 'Winning':
        return Colors.green;
      case 'Outbid':
        return Colors.orange;
      case 'Lost':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  void _navigateToAuctionDetails(String auctionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuctionDetailScreen(auctionId: auctionId),
      ),
    ).then((_) => _loadBidHistory());
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bid History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'All'),
            Tab(text: 'Won'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildStatsCard(),
                ),
                
                // Bids list
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Active bids
                      _activeBids.isEmpty
                          ? _buildEmptyState('No active bids', 'Try bidding on some auctions')
                          : _buildBidsList(_activeBids),
                      
                      // All bids
                      _allBids.isEmpty
                          ? _buildEmptyState('No bid history', 'Try bidding on some auctions')
                          : _buildBidsList(_allBids),
                      
                      // Won bids
                      _wonBids.isEmpty
                          ? _buildEmptyState('No auctions won yet', 'Keep bidding to win auctions')
                          : _buildBidsList(_wonBids),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigation(
        currentDestination: NavDestination.dashboard,
        onDestinationSelected: (destination) {
          handleNavigation(context, destination, false);
        },
        isSellerMode: false,
      ),
    );
  }
  
  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bidding Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Bids', _totalBids.toString()),
                _buildStatItem('Won', '$_wonAuctions auctions'),
                _buildStatItem('Success Rate', '${_successRate.toStringAsFixed(0)}%'),
                _buildStatItem('Avg Bid', formatCurrency(_averageBid)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildBidsList(List<Map<String, dynamic>> bids) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const SizedBox();
    
    return RefreshIndicator(
      onRefresh: _loadBidHistory,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: bids.length,
        itemBuilder: (context, index) {
          final bid = bids[index];
          final auctionId = bid['auction_id'] as String;
          final auction = _auctionCache[auctionId];
          final bidAmount = (bid['amount'] as num).toDouble();
          final bidTime = DateTime.parse(bid['created_at']);
          final status = _getBidStatus(bid, userId);
          
          if (auction == null) {
            return const SizedBox(); // Skip if auction not found
          }
          
          return Card(
            margin: const EdgeInsets.only(top: 8),
            child: InkWell(
              onTap: () => _navigateToAuctionDetails(auctionId),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            auction.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _getStatusColor(status)),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your bid: ${formatCurrency(bidAmount)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Current highest: ${formatCurrency(auction.highestBid)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatRelativeTime(bidTime),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              auction.isActive && !DateTime.now().isAfter(auction.endTime)
                                  ? 'Ends: ${formatRelativeTime(auction.endTime)}'
                                  : 'Ended: ${formatRelativeTime(auction.endTime)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (auction.isActive && !DateTime.now().isAfter(auction.endTime))
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _navigateToAuctionDetails(auctionId),
                            child: const Text('View Auction'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _navigateToAuctionDetails(auctionId),
                            child: const Text('Place Bid'),
                          ),
                        ],
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
  
  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.gavel,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Browse Auctions'),
          ),
        ],
      ),
    );
  }
}