// lib/features/auctions/screens/buyer_dashboard.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/auction_model.dart';
import '../../../data/models/fixed_price_listing_model.dart';
import '../../../data/models/watchlist_item_model.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import '../services/auction_service.dart';
import '../services/cart_service.dart';
import '../services/fixed_price_service.dart';
import '../services/recommendation_service.dart';
import '../services/watchlist_service.dart';
import '../widgets/auction_card.dart';
import '../widgets/fixed_price_card.dart';
import 'auction_detail_screen.dart';
import 'fixed_price_detail_screen.dart';
import 'search_explore_screen.dart';
import 'shopping_cart_screen.dart';
import 'watchlist_screen.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> with SingleTickerProviderStateMixin {
  final AuctionService _auctionService = AuctionService();
  final CartService _cartService = CartService();
  final FixedPriceService _fixedPriceService = FixedPriceService();
  final RecommendationService _recommendationService = RecommendationService();
  final WatchlistService _watchlistService = WatchlistService();
  final NotificationService _notificationService = NotificationService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  late TabController _tabController;
  bool _isLoading = true;
  List<Auction> _auctions = [];
  List<Auction> _recommendedAuctions = [];
  List<Auction> _endingSoonAuctions = [];
  List<FixedPriceListing> _fixedPriceListings = [];
  List<FixedPriceListing> _featuredListings = [];
  List<String> _watchlistedItemIds = [];
  int _cartCount = 0;
  
  NavDestination _currentDestination = NavDestination.dashboard;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
    _loadDashboardData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      await _notificationService.initialize();
    } catch (e) {
      // Silently handle notification initialization failures
      debugPrint('Warning: Could not initialize notifications: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load data in parallel for better performance
      await Future.wait([
        _loadAuctions(),
        _loadFixedPriceListings(),
        _loadWatchlist(),
        _loadCartCount(),
      ]);
      
      if (mounted) {
        setState(() => _isLoading = false);
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

  Future<void> _loadAuctions() async {
    try {
      // Get active auctions
      final auctionsStream = _auctionService.getActiveAuctions();
      _auctions = await auctionsStream.first;
      
      // Get personalized recommendations
      _recommendedAuctions = await _recommendationService.getRecommendedAuctions();
      
      // Get ending soon auctions
      _endingSoonAuctions = _auctions
          .where((auction) {
            final now = DateTime.now();
            final difference = auction.endTime.difference(now);
            // Less than 12 hours remaining
            return difference.inHours < 12 && difference.isNegative == false;
          })
          .toList();
      
      // Sort ending soon auctions by end time
      _endingSoonAuctions.sort((a, b) => a.endTime.compareTo(b.endTime));
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading auctions: $e');
    }
  }

  Future<void> _loadFixedPriceListings() async {
    try {
      // Get active fixed price listings
      _fixedPriceListings = await _fixedPriceService.getActiveListings();
      
      // Get featured listings
      _featuredListings = await _fixedPriceService.getFeaturedListings();
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading fixed price listings: $e');
    }
  }

  Future<void> _loadWatchlist() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      // Get all watchlisted item IDs
      final watchlistIds = await _watchlistService.getWatchlistItemIds();
      
      if (mounted) {
        setState(() {
          _watchlistedItemIds = watchlistIds;
        });
      }
    } catch (e) {
      debugPrint('Error loading watchlist: $e');
    }
  }

  Future<void> _loadCartCount() async {
    try {
      final cartCount = await _cartService.getCartCount();
      
      if (mounted) {
        setState(() {
          _cartCount = cartCount;
        });
      }
    } catch (e) {
      debugPrint('Error loading cart count: $e');
    }
  }

  Future<void> _toggleWatchlist(String itemId, WatchlistItemType itemType) async {
    try {
      final isWatchlisted = _watchlistedItemIds.contains(itemId);
      
      if (isWatchlisted) {
        await _watchlistService.removeFromWatchlist(itemId);
        setState(() {
          _watchlistedItemIds.remove(itemId);
        });
      } else {
        await _watchlistService.addToWatchlist(itemId, itemType);
        setState(() {
          _watchlistedItemIds.add(itemId);
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isWatchlisted 
              ? 'Removed from watchlist' 
              : 'Added to watchlist'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating watchlist: $e')),
      );
    }
  }

  void _navigateToAuctionDetails(String auctionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuctionDetailScreen(auctionId: auctionId),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _navigateToFixedPriceDetails(String listingId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FixedPriceDetailScreen(listingId: listingId),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchExploreScreen()),
    ).then((_) => _loadDashboardData());
  }

  void _navigateToWatchlist() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WatchlistScreen()),
    ).then((_) => _loadDashboardData());
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShoppingCartScreen()),
    ).then((_) => _loadDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kutanda Plant Auction'),
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _navigateToSearch,
            tooltip: 'Search',
          ),
          // Watchlist button
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: _navigateToWatchlist,
            tooltip: 'Watchlist',
          ),
          // Cart button with count indicator
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _navigateToCart,
                tooltip: 'Cart',
              ),
              if (_cartCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _cartCount.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Home'),
            Tab(text: 'Auctions'),
            Tab(text: 'Buy Now'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Home tab
                _buildHomeTab(),
                
                // Auctions tab
                _buildAuctionsTab(),
                
                // Fixed Price tab
                _buildFixedPriceTab(),
              ],
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

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome section
          _buildWelcomeSection(),
          
          const SizedBox(height: 16),
          
          // Ending soon auctions
          if (_endingSoonAuctions.isNotEmpty) ...[
            _buildSectionHeader('Ending Soon', Icons.timelapse),
            SizedBox(
              height: 340,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _endingSoonAuctions.length,
                itemBuilder: (context, index) {
                  final auction = _endingSoonAuctions[index];
                  return SizedBox(
                    width: 280,
                    child: AuctionCard(
                      auction: auction,
                      isWatchlisted: _watchlistedItemIds.contains(auction.id),
                      onWatchlistToggle: () => _toggleWatchlist(
                        auction.id, 
                        WatchlistItemType.auction
                      ),
                      onTap: () => _navigateToAuctionDetails(auction.id),
                      onBid: () => _navigateToAuctionDetails(auction.id),
                    ),
                  );
                },
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Recommended auctions
          if (_recommendedAuctions.isNotEmpty) ...[
            _buildSectionHeader('Recommended For You', Icons.recommend),
            ..._recommendedAuctions.take(3).map((auction) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AuctionCard(
                auction: auction,
                isWatchlisted: _watchlistedItemIds.contains(auction.id),
                onWatchlistToggle: () => _toggleWatchlist(
                  auction.id, 
                  WatchlistItemType.auction
                ),
                onTap: () => _navigateToAuctionDetails(auction.id),
                onBid: () => _navigateToAuctionDetails(auction.id),
              ),
            )),
          ],
          
          const SizedBox(height: 16),
          
          // Featured fixed price listings
          if (_featuredListings.isNotEmpty) ...[
            _buildSectionHeader('Featured Plants', Icons.star),
            SizedBox(
              height: 340,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _featuredListings.length,
                itemBuilder: (context, index) {
                  final listing = _featuredListings[index];
                  return SizedBox(
                    width: 280,
                    child: FixedPriceCard(
                      listing: listing,
                      isSaved: _watchlistedItemIds.contains(listing.id),
                      onSavedToggle: () => _toggleWatchlist(
                        listing.id, 
                        WatchlistItemType.fixedPrice
                      ),
                      onTap: () => _navigateToFixedPriceDetails(listing.id),
                      onAddToCart: () => _navigateToFixedPriceDetails(listing.id),
                      onBuyNow: () => _navigateToFixedPriceDetails(listing.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuctionsTab() {
    if (_auctions.isEmpty) {
      return _buildEmptyState(
        'No active auctions available',
        'Check back soon for new auctions',
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _auctions.length,
        itemBuilder: (context, index) {
          final auction = _auctions[index];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AuctionCard(
              auction: auction,
              isWatchlisted: _watchlistedItemIds.contains(auction.id),
              onWatchlistToggle: () => _toggleWatchlist(
                auction.id, 
                WatchlistItemType.auction
              ),
              onTap: () => _navigateToAuctionDetails(auction.id),
              onBid: () => _navigateToAuctionDetails(auction.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFixedPriceTab() {
    if (_fixedPriceListings.isEmpty) {
      return _buildEmptyState(
        'No fixed price listings available',
        'Check back soon for new plants',
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _fixedPriceListings.length,
        itemBuilder: (context, index) {
          final listing = _fixedPriceListings[index];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FixedPriceCard(
              listing: listing,
              isSaved: _watchlistedItemIds.contains(listing.id),
              onSavedToggle: () => _toggleWatchlist(
                listing.id, 
                WatchlistItemType.fixedPrice
              ),
              onTap: () => _navigateToFixedPriceDetails(listing.id),
              onAddToCart: () => _navigateToFixedPriceDetails(listing.id),
              onBuyNow: () => _navigateToFixedPriceDetails(listing.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              // Navigate to section view
              _navigateToSearch();
            },
            child: const Text('View All'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final String greeting = _getGreeting();
    final String userName = _getUserName();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, $userName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Welcome to Kutanda. Explore rare and beautiful plants from sellers around the world.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton(
                  label: 'Search',
                  icon: Icons.search,
                  onTap: _navigateToSearch,
                ),
                _buildQuickActionButton(
                  label: 'Watchlist',
                  icon: Icons.favorite,
                  onTap: _navigateToWatchlist,
                ),
                _buildQuickActionButton(
                  label: 'Cart',
                  icon: Icons.shopping_cart,
                  onTap: _navigateToCart,
                  badge: _cartCount > 0 ? _cartCount.toString() : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
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
            onPressed: _loadDashboardData,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getUserName() {
    final user = _supabase.auth.currentUser;
    if (user?.userMetadata?['full_name'] != null) {
      return user!.userMetadata!['full_name'];
    } else if (user?.email != null) {
      return user!.email!.split('@')[0];
    } else {
      return 'Plant Enthusiast';
    }
  }
}