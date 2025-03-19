// lib/screens/buyer_dashboard.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/auction_model.dart';
import '../../../shared/services/role_service.dart';
import '../../../shared/services/session_service.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import '../../../shared/widgets/item_carousel.dart';
import '../../auth/screens/login_screen.dart';
import '../../profile/screens/kyc_submission_screen.dart';
import '../services/auction_service.dart';
import '../widgets/auction_card.dart';
import '../widgets/fixed_price_card.dart';
import 'auction_detail_screen.dart';
import 'seller_dashboard.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final RoleService _roleService = RoleService();
  final AuctionService _auctionService = AuctionService();
  final SupabaseClient supabase = Supabase.instance.client;
  
  late TabController _tabController;
  bool _isLoading = false;
  NavDestination _currentDestination = NavDestination.dashboard;
  String _searchQuery = '';
  bool _showOnlyActive = true;
  
  // Filters
  double _minPrice = 0.0;
  double _maxPrice = 1000.0;
  List<String> _selectedCategories = [];
  String? _sortOption;
  
  // Watchlist
  List<String> _watchlistedAuctions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWatchlist();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWatchlist() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('watchlist')
            .select('item_id')
            .eq('user_id', user.id)
            .eq('item_type', 'auction');
        
        if (mounted) {
          setState(() {
            _watchlistedAuctions = List<String>.from(
              response.map((item) => item['item_id'] as String)
            );
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _switchToSeller() async {
    setState(() => _isLoading = true);
    
    try {
      // First check if seller profile is verified and active
      final roleStatus = await _roleService.getUserRoles();
      
      if (!mounted) return;
      
      if (!roleStatus['seller'] || roleStatus['seller_status'] != 'verified') {
        // Show dialog explaining they need to complete KYC
        final bool goToKyc = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Seller Verification Required'),
            content: Text(
              roleStatus['seller_status'] == 'pending' 
                ? 'Your seller verification is pending approval. Please check back later.'
                : 'You need to complete seller verification before you can switch to seller mode.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              if (roleStatus['seller_status'] != 'pending')
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Start Verification'),
                ),
            ],
          ),
        ) ?? false;
        
        if (!mounted) return;
        
        if (goToKyc) {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const KycSubmissionScreen())
          );
        }
        
        setState(() => _isLoading = false);
        return;
      }
      
      // If verified, attempt to switch roles
      bool success = await _apiService.switchRole('buyer');
      
      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SellerDashboard()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Switched to Seller mode')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to switch role')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error switching role: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    
    try {
      // Show loading indicator
      if (!mounted) return;
      
      // Use a local context variable that won't be used after the async gap
      BuildContext localContext = context;
      
      showDialog(
        context: localContext,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      
      await supabase.auth.signOut();
      await SessionService.clearSession();
      
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.of(localContext).pop();
      
      Navigator.pushReplacement(
        localContext,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Try to close dialog if open
      Navigator.of(context, rootNavigator: true).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Stream<List<Auction>> _getAuctionsStream() {
    if (_showOnlyActive) {
      return _auctionService.getActiveAuctions();
    } else {
      return _auctionService.getAllAuctions();
    }
  }
  
  Future<void> _toggleWatchlist(String auctionId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      final isWatchlisted = _watchlistedAuctions.contains(auctionId);
      
      if (isWatchlisted) {
        // Remove from watchlist
        await supabase
            .from('watchlist')
            .delete()
            .eq('user_id', user.id)
            .eq('item_id', auctionId);
        
        setState(() {
          _watchlistedAuctions.remove(auctionId);
        });
      } else {
        // Add to watchlist
        await supabase.from('watchlist').insert({
          'user_id': user.id,
          'item_id': auctionId,
          'item_type': 'auction',
          'created_at': DateTime.now().toIso8601String(),
        });
        
        setState(() {
          _watchlistedAuctions.add(auctionId);
        });
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
  
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Auctions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Price Range
                const Text('Price Range:'),
                RangeSlider(
                  values: RangeValues(_minPrice, _maxPrice),
                  min: 0,
                  max: 1000,
                  divisions: 20,
                  labels: RangeLabels(
                    '\$${_minPrice.toInt()}',
                    '\$${_maxPrice.toInt()}'
                  ),
                  onChanged: (values) {
                    setState(() {
                      _minPrice = values.start;
                      _maxPrice = values.end;
                    });
                  },
                ),
                
                // Categories
                const Text('Categories:'),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Flowers'),
                      selected: _selectedCategories.contains('Flowers'),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add('Flowers');
                          } else {
                            _selectedCategories.remove('Flowers');
                          }
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Trees'),
                      selected: _selectedCategories.contains('Trees'),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add('Trees');
                          } else {
                            _selectedCategories.remove('Trees');
                          }
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Succulents'),
                      selected: _selectedCategories.contains('Succulents'),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add('Succulents');
                          } else {
                            _selectedCategories.remove('Succulents');
                          }
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Herbs'),
                      selected: _selectedCategories.contains('Herbs'),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add('Herbs');
                          } else {
                            _selectedCategories.remove('Herbs');
                          }
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Indoor'),
                      selected: _selectedCategories.contains('Indoor'),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add('Indoor');
                          } else {
                            _selectedCategories.remove('Indoor');
                          }
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Outdoor'),
                      selected: _selectedCategories.contains('Outdoor'),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add('Outdoor');
                          } else {
                            _selectedCategories.remove('Outdoor');
                          }
                        });
                      },
                    ),
                  ],
                ),
                
                // Sort by
                const SizedBox(height: 8),
                const Text('Sort by:'),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _sortOption,
                  hint: const Text('Select an option'),
                  onChanged: (value) {
                    setState(() {
                      _sortOption = value;
                    });
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'newest',
                      child: Text('Newest'),
                    ),
                    DropdownMenuItem(
                      value: 'ending_soon',
                      child: Text('Ending Soon'),
                    ),
                    DropdownMenuItem(
                      value: 'price_low',
                      child: Text('Price: Low to High'),
                    ),
                    DropdownMenuItem(
                      value: 'price_high',
                      child: Text('Price: High to Low'),
                    ),
                    DropdownMenuItem(
                      value: 'most_bids',
                      child: Text('Most Bids'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _minPrice = 0;
                          _maxPrice = 1000;
                          _selectedCategories = [];
                          _sortOption = null;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Apply filters
                        Navigator.pop(context);
                        // Refresh auctions with new filters
                        this.setState(() {});
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kutanda Plant Auction"),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: _isLoading ? null : _switchToSeller,
            tooltip: 'Switch to Seller Mode',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLoading ? null : _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "All Auctions"),
            Tab(text: "Fixed Price"),
            Tab(text: "Watchlist"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and filter area
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search plants...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.filter_list),
                            onPressed: _showFilterDialog,
                            tooltip: 'Filter',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('Active auctions only'),
                              value: _showOnlyActive,
                              onChanged: (value) {
                                setState(() {
                                  _showOnlyActive = value;
                                });
                              },
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Featured Auctions Carousel
                StreamBuilder<List<Auction>>(
                  stream: _auctionService.getActiveAuctions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    
                    // Get featured auctions - in production we'd have a featured flag
                    // For now, just take the top 5 with highest bids
                    final featuredAuctions = List<Auction>.from(snapshot.data!)
                      ..sort((a, b) => b.highestBid.compareTo(a.highestBid));
                    final displayedAuctions = featuredAuctions.take(5).toList();
                    
                    return ItemCarousel<Auction>(
                      title: 'Featured Auctions',
                      items: displayedAuctions,
                      onItemTap: (auction) {
                        // Navigate to auction details
                        // You can implement this navigation later
                      },
                    );
                  },
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // All Auctions Tab
                      _buildAuctionsTab(),
                      
                      // Fixed Price Tab
                      _buildFixedPriceTab(),
                      
                      // Watchlist Tab
                      _buildWatchlistTab(),
                    ],
                  ),
                ),
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
  
  Widget _buildAuctionsTab() {
    return StreamBuilder<List<Auction>>(
      stream: _getAuctionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No auctions available'),
          );
        }
        
        final auctions = snapshot.data!;
        
        // Filter by search query if provided
        final filteredAuctions = _searchQuery.isEmpty
            ? auctions
            : auctions.where((auction) =>
                auction.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                auction.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        
        // Apply other filters
        final List<Auction> finalFilteredAuctions = filteredAuctions.where((auction) {
          // Price filter
          if (auction.highestBid < _minPrice || auction.highestBid > _maxPrice) {
            return false;
          }
          
          // Category filter (simplified - would need category field in Auction model)
          if (_selectedCategories.isNotEmpty) {
            // Example: check if auction description contains any selected category
            bool matchesCategory = false;
            for (final category in _selectedCategories) {
              if (auction.description.toLowerCase().contains(category.toLowerCase())) {
                matchesCategory = true;
                break;
              }
            }
            if (!matchesCategory) return false;
          }
          
          return true;
        }).toList();
        
        // Sort auctions
        if (_sortOption != null) {
          switch (_sortOption) {
            case 'newest':
              // Would need createdAt field
              break;
            case 'ending_soon':
              finalFilteredAuctions.sort((a, b) => a.endTime.compareTo(b.endTime));
              break;
            case 'price_low':
              finalFilteredAuctions.sort((a, b) => a.highestBid.compareTo(b.highestBid));
              break;
            case 'price_high':
              finalFilteredAuctions.sort((a, b) => b.highestBid.compareTo(a.highestBid));
              break;
            case 'most_bids':
              // Would need bidCount field
              break;
          }
        }
        
        if (finalFilteredAuctions.isEmpty) {
          return const Center(
            child: Text('No matching auctions found'),
          );
        }
        
        return ListView.builder(
          itemCount: finalFilteredAuctions.length,
          itemBuilder: (context, index) {
            final auction = finalFilteredAuctions[index];
            final isWatchlisted = _watchlistedAuctions.contains(auction.id);
            
            return AuctionCard(
              auction: auction,
              isWatchlisted: isWatchlisted,
              onWatchlistToggle: () => _toggleWatchlist(auction.id),
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => AuctionDetailScreen(auctionId: auction.id),
                  ),
                );
              },
              onBid: () => _placeBid(auction),
            );
          },
        );
      },
    );
  }
  
  Widget _buildFixedPriceTab() {
    // This would be implemented similarly to the auctions tab but for fixed price listings
    // For now, using a placeholder
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.store, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Fixed price plants coming soon!',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Browse plants available for immediate purchase',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _tabController.animateTo(0); // Switch to auctions tab
            },
            child: const Text('Browse Auctions Instead'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWatchlistTab() {
    if (_watchlistedAuctions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Your watchlist is empty',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add auctions to your watchlist to track them here',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _tabController.animateTo(0); // Switch to auctions tab
              },
              child: const Text('Browse Auctions'),
            ),
          ],
        ),
      );
    }
    
    return StreamBuilder<List<Auction>>(
      stream: _auctionService.getAllAuctions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No auctions available'),
          );
        }
        
        final allAuctions = snapshot.data!;
        
        // Filter to only show watchlisted auctions
        final watchlistedAuctions = allAuctions.where(
          (auction) => _watchlistedAuctions.contains(auction.id)
        ).toList();
        
        if (watchlistedAuctions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No matching auctions in your watchlist',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _tabController.animateTo(0); // Switch to auctions tab
                  },
                  child: const Text('Browse Auctions'),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: watchlistedAuctions.length,
          itemBuilder: (context, index) {
            final auction = watchlistedAuctions[index];
            
            return AuctionCard(
              auction: auction,
              isWatchlisted: true,
              onWatchlistToggle: () => _toggleWatchlist(auction.id),
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => AuctionDetailScreen(auctionId: auction.id),
                  ),
                );
              },
              onBid: () => _placeBid(auction),
            );
          },
        );
      },
    );
  }
  
// lib/features/auctions/screens/buyer_dashboard.dart (partial - just fixing the placeBid method and adding _bidRepository)
void _placeBid(Auction auction) {
  TextEditingController bidController = TextEditingController();
  final minimumBid = auction.highestBid + auction.bidIncrement;
  
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text("Place Bid on ${auction.title}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current highest bid: \$${auction.highestBid.toStringAsFixed(2)}'),
          Text('Minimum bid: \$${minimumBid.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          TextField(
            controller: bidController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Your bid amount",
              prefixText: "\$",
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            // Validate bid amount
            final bidAmount = double.tryParse(bidController.text);
            
            if (bidAmount == null || bidAmount < minimumBid) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text('Bid must be at least \$${minimumBid.toStringAsFixed(2)}')),
              );
              return;
            }
            
            // Close dialog
            Navigator.pop(dialogContext);
            
            // Show loading indicator
            if (mounted) {
              showLoadingDialog(context);
            }
            
            try {
              final user = supabase.auth.currentUser;
              if (user == null) throw Exception('User not logged in');
              
              // Place bid using auction service instead of repository
              await _auctionService.placeBid(auction.id, bidAmount, user.id);
              
              // Close loading dialog
              if (!mounted) return;
              Navigator.pop(context);
              
              if (mounted) {
                showSnackBar(context, 'Bid placed successfully!');
              }
            } catch (e) {
              // Close loading dialog
              if (!mounted) return;
              Navigator.pop(context);
              
              if (mounted) {
                showSnackBar(context, 'Error: $e');
              }
            }
          },
          child: const Text("Place Bid"),
        ),
      ],
    ),
  );
}
}