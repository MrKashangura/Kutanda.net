// lib/features/auctions/screens/search_explore_screen.dart
import 'package:flutter/material.dart';

import '../../../core/utils/helpers.dart';
import '../../../data/models/auction_model.dart';
import '../../../data/models/fixed_price_listing_model.dart';
import '../../../data/models/watchlist_item_model.dart';
import '../services/auction_service.dart';
import '../services/fixed_price_service.dart';
import '../services/watchlist_service.dart';
import '../widgets/auction_card.dart';
import '../widgets/fixed_price_card.dart';
import 'auction_detail_screen.dart';
import 'fixed_price_detail_screen.dart';

class SearchExploreScreen extends StatefulWidget {
  const SearchExploreScreen({super.key});

  @override
  State<SearchExploreScreen> createState() => _SearchExploreScreenState();
}

class _SearchExploreScreenState extends State<SearchExploreScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final AuctionService _auctionService = AuctionService();
  final FixedPriceService _fixedPriceService = FixedPriceService();
  final WatchlistService _watchlistService = WatchlistService();
  late TabController _tabController;

  bool _isLoading = false;
  String _searchQuery = '';
  List<Auction> _auctionResults = [];
  List<FixedPriceListing> _fixedPriceResults = [];
  List<String> _watchlistedItemIds = [];
  
  // Filter parameters
  final List<String> _categories = [
    'All', 'Flowering', 'Succulents', 'Tropical', 'Indoor', 'Rare', 'Cacti', 'Herbs'
  ];
  String _selectedCategory = 'All';
  RangeValues _priceRange = const RangeValues(0, 1000);
  bool _activeOnly = true;
  String _sortBy = 'newest';
  
  final double _minPrice = 0;
  final double _maxPrice = 1000;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWatchlist();
    _searchAuctions();
    _searchFixedPriceListings();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadWatchlist() async {
    try {
      final watchlistIds = await _watchlistService.getWatchlistItemIds();
      if (mounted) {
        setState(() {
          _watchlistedItemIds = watchlistIds;
        });
      }
    } catch (e) {
      // Silently handle watchlist loading failures
    }
  }

  Future<void> _searchAuctions() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      // Get auctions based on active filter
      Stream<List<Auction>> auctionsStream = _auctionService.getActiveAuctions();
      
      // Convert stream to Future for filtering
      final auctions = await auctionsStream.first;
      
      // Apply filters
      final filteredAuctions = auctions.where((auction) {
        // Apply search query
        if (_searchQuery.isNotEmpty) {
          final matchesQuery = auction.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              auction.description.toLowerCase().contains(_searchQuery.toLowerCase());
          if (!matchesQuery) return false;
        }
        
        // Apply price filter
        if (auction.startingPrice < _priceRange.start || auction.highestBid > _priceRange.end) {
          return false;
        }
        
        // Apply category filter
        if (_selectedCategory != 'All') {
          // Note: In a real app, you would need a category field in the auction model
          final hasCategory = auction.description.toLowerCase().contains(_selectedCategory.toLowerCase());
          if (!hasCategory) return false;
        }
        
        return _activeOnly ? auction.isActive : true;
      }).toList();
      
      // Apply sorting
      switch (_sortBy) {
        case 'endingSoon':
          filteredAuctions.sort((a, b) => a.endTime.compareTo(b.endTime));
          break;
        case 'priceAsc':
          filteredAuctions.sort((a, b) => a.highestBid.compareTo(b.highestBid));
          break;
        case 'priceDesc':
          filteredAuctions.sort((a, b) => b.highestBid.compareTo(a.highestBid));
          break;
        default: // 'newest'
          // Default sort remains as-is from the database
          break;
      }
      
      if (mounted) {
        setState(() {
          _auctionResults = filteredAuctions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching auctions: $e')),
        );
      }
    }
  }
  
  Future<void> _searchFixedPriceListings() async {
    try {
      final listings = await _fixedPriceService.getActiveListings();
      
      // Apply filters
      final filteredListings = listings.where((listing) {
        // Apply search query
        if (_searchQuery.isNotEmpty) {
          final matchesQuery = listing.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              listing.description.toLowerCase().contains(_searchQuery.toLowerCase());
          if (!matchesQuery) return false;
        }
        
        // Apply price filter
        if (listing.price < _priceRange.start || listing.price > _priceRange.end) {
          return false;
        }
        
        // Apply category filter
        if (_selectedCategory != 'All') {
          // Note: In a real app, you would need a category field in the listing model
          final hasCategory = listing.description.toLowerCase().contains(_selectedCategory.toLowerCase());
          if (!hasCategory) return false;
        }
        
        return listing.isActive;
      }).toList();
      
      // Apply sorting
      switch (_sortBy) {
        case 'priceAsc':
          filteredListings.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'priceDesc':
          filteredListings.sort((a, b) => b.price.compareTo(a.price));
          break;
        default: // 'newest'
          // Default sort by creation date (if available)
          filteredListings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }
      
      if (mounted) {
        setState(() {
          _fixedPriceResults = filteredListings;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching fixed price listings: $e')),
        );
      }
    }
  }
  
  Future<void> _performSearch() async {
    _searchAuctions();
    _searchFixedPriceListings();
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
  
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle bar
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Filter & Sort',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = 'All';
                                  _priceRange = RangeValues(_minPrice, _maxPrice);
                                  _activeOnly = true;
                                  _sortBy = 'newest';
                                });
                              },
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Categories
                        const Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories.map((category) {
                            return ChoiceChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        
                        // Price Range
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Price Range',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${formatCurrency(_priceRange.start)} - ${formatCurrency(_priceRange.end)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        RangeSlider(
                          values: _priceRange,
                          min: _minPrice,
                          max: _maxPrice,
                          divisions: 20,
                          labels: RangeLabels(
                            formatCurrency(_priceRange.start),
                            formatCurrency(_priceRange.end),
                          ),
                          onChanged: (values) {
                            setState(() {
                              _priceRange = values;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Show only active
                        SwitchListTile(
                          title: const Text(
                            'Show only active items',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          value: _activeOnly,
                          onChanged: (value) {
                            setState(() {
                              _activeOnly = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Sort options
                        const Text(
                          'Sort By',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RadioListTile<String>(
                          title: const Text('Newest'),
                          value: 'newest',
                          groupValue: _sortBy,
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Ending Soon'),
                          value: 'endingSoon',
                          groupValue: _sortBy,
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Price: Low to High'),
                          value: 'priceAsc',
                          groupValue: _sortBy,
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Price: High to Low'),
                          value: 'priceDesc',
                          groupValue: _sortBy,
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Apply button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _performSearch();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Apply Filters'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Explore'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search plants...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                              _performSearch();
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: _showFilterSheet,
                          tooltip: 'Filter',
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    // Debounce search for performance
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchQuery == value && mounted) {
                        _performSearch();
                      }
                    });
                  },
                ),
              ),
              
              // Category chips
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                            _performSearch();
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              
              // Tabs
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Auctions'),
                  Tab(text: 'Fixed Price'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Auctions tab
                _buildAuctionsTab(),
                
                // Fixed price tab
                _buildFixedPriceTab(),
              ],
            ),
    );
  }

  Widget _buildAuctionsTab() {
    if (_auctionResults.isEmpty) {
      return _buildEmptyState('No matching auctions', Icons.gavel);
    }
    
    return RefreshIndicator(
      onRefresh: _performSearch,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _auctionResults.length,
        itemBuilder: (context, index) {
          final auction = _auctionResults[index];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AuctionCard(
              auction: auction,
              isWatchlisted: _watchlistedItemIds.contains(auction.id),
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
                ).then((_) => _performSearch());
              },
              onBid: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuctionDetailScreen(auctionId: auction.id),
                  ),
                ).then((_) => _performSearch());
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFixedPriceTab() {
    if (_fixedPriceResults.isEmpty) {
      return _buildEmptyState('No matching fixed price listings', Icons.shopping_bag);
    }
    
    return RefreshIndicator(
      onRefresh: _performSearch,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _fixedPriceResults.length,
        itemBuilder: (context, index) {
          final listing = _fixedPriceResults[index];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FixedPriceCard(
              listing: listing,
              isSaved: _watchlistedItemIds.contains(listing.id),
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
                ).then((_) => _performSearch());
              },
              onAddToCart: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FixedPriceDetailScreen(listingId: listing.id),
                  ),
                ).then((_) => _performSearch());
              },
              onBuyNow: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FixedPriceDetailScreen(listingId: listing.id),
                  ),
                ).then((_) => _performSearch());
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _selectedCategory = 'All';
                _priceRange = RangeValues(_minPrice, _maxPrice);
                _activeOnly = true;
                _sortBy = 'newest';
              });
              _performSearch();
            },
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }
}