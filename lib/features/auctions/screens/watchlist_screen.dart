import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/auction_model.dart';
import '../../../data/models/fixed_price_listing_model.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import '../services/auction_service.dart';
import '../widgets/auction_card.dart';
import '../widgets/fixed_price_card.dart';
import 'auction_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> with SingleTickerProviderStateMixin {
  final AuctionService _auctionService = AuctionService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  late TabController _tabController;
  bool _isLoading = true;
  List<String> _watchlistedAuctionIds = [];
  List<String> _savedFixedPriceIds = [];
  List<Auction> _auctions = [];
  List<FixedPriceListing> _fixedPriceListings = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWatchlistData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWatchlistData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      // Get watchlisted auction IDs
      final auctionWatchlistResponse = await _supabase
          .from('watchlist')
          .select('item_id')
          .eq('user_id', user.id)
          .eq('item_type', 'auction');
      
      _watchlistedAuctionIds = List<String>.from(
        auctionWatchlistResponse.map((item) => item['item_id'] as String)
      );
      
      // Get saved fixed price listing IDs
      final savedFixedPriceResponse = await _supabase
          .from('watchlist')
          .select('item_id')
          .eq('user_id', user.id)
          .eq('item_type', 'fixed_price');
      
      _savedFixedPriceIds = List<String>.from(
        savedFixedPriceResponse.map((item) => item['item_id'] as String)
      );
      
      // Load auction data
      await _loadAuctions();
      
      // Load fixed price listing data
      await _loadFixedPriceListings();
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading watchlist: $e')),
        );
      }
    }
  }
  
  Future<void> _loadAuctions() async {
    if (_watchlistedAuctionIds.isEmpty) {
      setState(() => _auctions = []);
      return;
    }
    
    try {
      // Get all auctions in one batch
      final auctionsResponse = await _supabase
          .from('auctions')
          .select()
          .inFilter('id', _watchlistedAuctionIds);
      
      setState(() {
        _auctions = auctionsResponse
            .map((data) => Auction.fromMap(data))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading auctions: $e')),
      );
    }
  }
  
  Future<void> _loadFixedPriceListings() async {
    if (_savedFixedPriceIds.isEmpty) {
      setState(() => _fixedPriceListings = []);
      return;
    }
    
    try {
      // Get all fixed price listings in one batch
      final listingsResponse = await _supabase
          .from('fixed_price_listings')
          .select()
          .inFilter('id', _savedFixedPriceIds);
      
      setState(() {
        _fixedPriceListings = listingsResponse
            .map((data) => FixedPriceListing.fromMap(data))
            .toList();
      });
    } catch (e) {
      // This might not work if the fixed_price_listings table doesn't exist yet
      // We'll show empty state for now
      setState(() => _fixedPriceListings = []);
    }
  }
  
  Future<void> _toggleAuctionWatchlist(String auctionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      final isWatchlisted = _watchlistedAuctionIds.contains(auctionId);
      
      if (isWatchlisted) {
        // Remove from watchlist
        await _supabase
            .from('watchlist')
            .delete()
            .eq('user_id', user.id)
            .eq('item_id', auctionId);
        
        setState(() {
          _watchlistedAuctionIds.remove(auctionId);
          _auctions.removeWhere((auction) => auction.id == auctionId);
        });
      } else {
        // Add to watchlist (shouldn't happen in this screen, but just in case)
        await _supabase.from('watchlist').insert({
          'user_id': user.id,
          'item_id': auctionId,
          'item_type': 'auction',
          'created_at': DateTime.now().toIso8601String(),
        });
        
        setState(() {
          _watchlistedAuctionIds.add(auctionId);
        });
        
        // Reload auctions to get the newly added one
        await _loadAuctions();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isWatchlisted
                ? 'Removed from watchlist'
                : 'Added to watchlist'
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating watchlist: $e')),
      );
    }
  }
  
  Future<void> _toggleFixedPriceSaved(String listingId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      final isSaved = _savedFixedPriceIds.contains(listingId);
      
      if (isSaved) {
        // Remove from saved
        await _supabase
            .from('watchlist')
            .delete()
            .eq('user_id', user.id)
            .eq('item_id', listingId);
        
        setState(() {
          _savedFixedPriceIds.remove(listingId);
          _fixedPriceListings.removeWhere((listing) => listing.id == listingId);
        });
      } else {
        // Add to saved (shouldn't happen in this screen, but just in case)
        await _supabase.from('watchlist').insert({
          'user_id': user.id,
          'item_id': listingId,
          'item_type': 'fixed_price',
          'created_at': DateTime.now().toIso8601String(),
        });
        
        setState(() {
          _savedFixedPriceIds.add(listingId);
        });
        
        // Reload listings to get the newly added one
        await _loadFixedPriceListings();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSaved
                ? 'Removed from saved items'
                : 'Added to saved items'
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating saved items: $e')),
      );
    }
  }
  
  void _placeBid(Auction auction) {
    // Redirect to auction detail screen for bidding
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuctionDetailScreen(auctionId: auction.id),
      ),
    ).then((_) => _loadWatchlistData());
  }
  
  void _addToCart(FixedPriceListing listing) {
    // Cart functionality will be implemented in a future update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shopping cart coming soon')),
    );
  }
  
  void _buyNow(FixedPriceListing listing) {
    // Direct purchase will be implemented in a future update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Direct purchase coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Watchlist'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Auctions'),
            Tab(text: 'Fixed Price Items'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Auctions tab
                _buildAuctionsTab(),
                
                // Fixed price items tab
                _buildFixedPriceTab(),
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
  
  Widget _buildAuctionsTab() {
    if (_auctions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No saved auctions',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Items you add to your watchlist will appear here',
              style: TextStyle(color: Colors.grey),
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
    
    return RefreshIndicator(
      onRefresh: _loadWatchlistData,
      child: ListView.builder(
        itemCount: _auctions.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final auction = _auctions[index];
          
          return AuctionCard(
            auction: auction,
            isWatchlisted: true,
            onWatchlistToggle: () => _toggleAuctionWatchlist(auction.id),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AuctionDetailScreen(auctionId: auction.id),
                ),
              ).then((_) => _loadWatchlistData());
            },
            onBid: () => _placeBid(auction),
          );
        },
      ),
    );
  }
  
  Widget _buildFixedPriceTab() {
    if (_fixedPriceListings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No saved fixed price items',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Items you save will appear here',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Browse Fixed Price Items'),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadWatchlistData,
      child: ListView.builder(
        itemCount: _fixedPriceListings.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final listing = _fixedPriceListings[index];
          
          return FixedPriceCard(
            listing: listing,
            isSaved: true,
            onSavedToggle: () => _toggleFixedPriceSaved(listing.id),
            onTap: () {
              // Navigate to fixed price detail screen when implemented
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fixed price details coming soon')),
              );
            },
            onAddToCart: () => _addToCart(listing),
            onBuyNow: () => _buyNow(listing),
          );
        },
      ),
    );
  }
}