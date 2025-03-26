// lib/features/auctions/screens/buyer_dashboard.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/auction_model.dart';
import '../../../data/models/fixed_price_listing_model.dart';
import '../../../data/models/watchlist_item_model.dart'; // Added import for WatchlistItemType
import '../../../shared/widgets/bottom_navigation.dart';
import '../services/auction_service.dart';
import '../services/fixed_price_service.dart';
import '../services/watchlist_service.dart';
import '../widgets/auction_card.dart';
import '../widgets/fixed_price_card.dart' as widgets; // Use alias to resolve ambiguity
import 'auction_detail_screen.dart';
import 'bid_history_screen.dart'; // Import BidHistoryScreen
import 'fixed_price_detail_screen.dart';
import 'search_explore_screen.dart';
import 'watchlist_screen.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> with SingleTickerProviderStateMixin {
  final AuctionService _auctionService = AuctionService();
  final FixedPriceService _fixedPriceService = FixedPriceService();
  final WatchlistService _watchlistService = WatchlistService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  late TabController _tabController;
  bool _isLoading = true;
  List<Auction> _auctions = [];
  List<FixedPriceListing> _fixedPriceListings = [];
  List<String> _watchlistedItems = [];
  
  NavDestination _currentDestination = NavDestination.dashboard;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load auctions, fixed price listings, and watchlist in parallel
      final futures = await Future.wait([
        _auctionService.getActiveAuctions().first,
        _fixedPriceService.getActiveListings(),
        _loadWatchlistItems(),
      ]);
      
      if (mounted) {
        setState(() {
          _auctions = futures[0] as List<Auction>;
          _fixedPriceListings = futures[1] as List<FixedPriceListing>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _loadWatchlistItems() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      final items = await _watchlistService.getWatchlistItemIds();
      
      if (mounted) {
        setState(() {
          _watchlistedItems = items;
        });
      }
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> _toggleWatchlist(String itemId, WatchlistItemType itemType) async {
    try {
      final isWatchlisted = _watchlistedItems.contains(itemId);
      
      if (isWatchlisted) {
        await _watchlistService.removeFromWatchlist(itemId);
        
        if (mounted) {
          setState(() {
            _watchlistedItems.remove(itemId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from watchlist'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await _watchlistService.addToWatchlist(itemId, itemType);
        
        if (mounted) {
          setState(() {
            _watchlistedItems.add(itemId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to watchlist'),
              duration: Duration(seconds: 1),
            ),
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

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchExploreScreen()),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kutanda Plant Auction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _navigateToSearch,
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WatchlistScreen()),
              ).then((_) => _loadData());
            },
            tooltip: 'Watchlist',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Featured'),
            Tab(text: 'Auctions'),
            Tab(text: 'Fixed Price'),
            Tab(text: 'Bid History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Featured Tab - Mix of auctions and fixed price
                _buildFeaturedTab(),
                
                // Auctions Tab
                _buildAuctionsTab(),
                
                // Fixed Price Tab
                _buildFixedPriceTab(),
                
                // Bid History Tab
                const BidHistoryScreen(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
      bottomNavigationBar: BottomNavigation(
        currentDestination: _currentDestination,
        onDestinationSelected: (destination) {
          setState(() {
            _currentDestination = destination;
          });
          handleNavigation(context, destination, false);
        },
        isSellerMode: false,
      ),
    );
  }

  Widget _buildFeaturedTab() {
    // Combine featured auctions and fixed price listings
    final featuredAuctions = _auctions
        .where((auction) => auction.isActive)
        .take(3)
        .toList();
    
    final featuredFixedPrice = _fixedPriceListings
        .where((listing) => listing.isFeatured && listing.isActive)
        .take(3)
        .toList();
    
    if (featuredAuctions.isEmpty && featuredFixedPrice.isEmpty) {
      return _buildEmptyState('No featured items available');
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Featured sections header
          const Text(
            'Featured Items',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Featured auctions
          if (featuredAuctions.isNotEmpty) ...[
            const Text(
              'Ending Soon Auctions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...featuredAuctions.map((auction) => AuctionCard(
              auction: auction,
              isWatchlisted: _watchlistedItems.contains(auction.id),
              onWatchlistToggle: () => _toggleWatchlist(
                auction.id, 
                WatchlistItemType.auction
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuctionDetailScreen(auctionId: auction.id),
                  ),
                ).then((_) => _loadData());
              },
              onBid: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuctionDetailScreen(auctionId: auction.id),
                  ),
                ).then((_) => _loadData());
              },
            )),
            const SizedBox(height: 24),
          ],
          
          // Featured fixed price listings
          if (featuredFixedPrice.isNotEmpty) ...[
            const Text(
              'Featured Plants',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...featuredFixedPrice.map((listing) => widgets.FixedPriceCard(
              listing: listing,
              isSaved: _watchlistedItems.contains(listing.id),
              onSavedToggle: () => _toggleWatchlist(
                listing.id, 
                WatchlistItemType.fixedPrice
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FixedPriceDetailScreen(listingId: listing.id),
                  ),
                ).then((_) => _loadData());
              },
              onAddToCart: () {
                // Navigate to fixed price detail for add to cart
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FixedPriceDetailScreen(listingId: listing.id),
                  ),
                ).then((_) => _loadData());
              },
              onBuyNow: () {
                // Navigate to fixed price detail for direct purchase
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FixedPriceDetailScreen(listingId: listing.id),
                  ),
                ).then((_) => _loadData());
              },
            )),
          ],
          
          const SizedBox(height: 16),
          
          // Browse more button
          Center(
            child: OutlinedButton(
              onPressed: _navigateToSearch,
              child: const Text('Browse All Items'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionsTab() {
    if (_auctions.isEmpty) {
      return _buildEmptyState('No active auctions available');
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _auctions.length,
        itemBuilder: (context, index) {
          final auction = _auctions[index];
          
          return AuctionCard(
            auction: auction,
            isWatchlisted: _watchlistedItems.contains(auction.id),
            onWatchlistToggle: () => _toggleWatchlist(
              auction.id, 
              WatchlistItemType.auction
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AuctionDetailScreen(auctionId: auction.id),
                ),
              ).then((_) => _loadData());
            },
            onBid: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AuctionDetailScreen(auctionId: auction.id),
                ),
              ).then((_) => _loadData());
            },
          );
        },
      ),
    );
  }

  Widget _buildFixedPriceTab() {
    if (_fixedPriceListings.isEmpty) {
      return _buildEmptyState('No fixed price listings available');
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _fixedPriceListings.length,
        itemBuilder: (context, index) {
          final listing = _fixedPriceListings[index];
          
          return widgets.FixedPriceCard(
            listing: listing,
            isSaved: _watchlistedItems.contains(listing.id),
            onSavedToggle: () => _toggleWatchlist(
              listing.id, 
              WatchlistItemType.fixedPrice
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FixedPriceDetailScreen(listingId: listing.id),
                ),
              ).then((_) => _loadData());
            },
            onAddToCart: () {
              // Navigate to fixed price detail for add to cart
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FixedPriceDetailScreen(listingId: listing.id),
                ),
              ).then((_) => _loadData());
            },
            onBuyNow: () {
              // Navigate to fixed price detail for direct purchase
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FixedPriceDetailScreen(listingId: listing.id),
                ),
              ).then((_) => _loadData());
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.category, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}