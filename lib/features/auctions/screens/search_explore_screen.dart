// lib/features/auctions/screens/search_explore_screen.dart
import 'package:flutter/material.dart';

import '../../../core/utils/helpers.dart';
import '../../../data/models/auction_model.dart';
import '../../../shared/widgets/filter_dialog.dart';
import '../services/auction_service.dart';

class SearchExploreScreen extends StatefulWidget {
  const SearchExploreScreen({super.key});

  @override
  State<SearchExploreScreen> createState() => _SearchExploreScreenState();
}

class _SearchExploreScreenState extends State<SearchExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AuctionService _auctionService = AuctionService();

  bool _isLoading = false;
  String _searchQuery = '';
  List<Auction> _searchResults = [];
  
  // Filter parameters
  String? _categoryFilter;
  RangeValues _priceRange = const RangeValues(0, 1000); // Default price range
  bool _activeOnly = true;
  String _sortBy = 'newest'; // Options: newest, endingSoon, priceAsc, priceDesc

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    
    try {
      // Get auctions based on active filter
      Stream<List<Auction>> auctionsStream;
      
      if (_activeOnly) {
        auctionsStream = _auctionService.getActiveAuctions();
      } else {
        auctionsStream = _auctionService.getAllAuctions();
      }
      
      // Convert stream to Future for simpler filtering
      final auctions = await auctionsStream.first;
      
      // Apply additional filters
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
        
        // Category filter would go here if we had categories in the model
        
        return true;
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
        default: // 'newest' - would need createdAt field in the model
          // Default sort remains as-is from the database
          break;
      }
      
      setState(() {
        _searchResults = filteredAuctions;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showSnackBar(context, 'Error searching auctions: $e');
      }
    }
  }

  void _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => FilterDialog(
        currentPriceRange: _priceRange,
        activeOnly: _activeOnly,
        sortBy: _sortBy,
        categoryFilter: _categoryFilter,
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        _priceRange = result['priceRange'] as RangeValues;
        _activeOnly = result['activeOnly'] as bool;
        _sortBy = result['sortBy'] as String;
        _categoryFilter = result['categoryFilter'] as String?;
      });
      
      _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Auctions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search plants...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _performSearch();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
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
          
          // Active Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (_activeOnly)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: const Text('Active Only'),
                      selected: true,
                      onSelected: (selected) {
                        setState(() => _activeOnly = selected);
                        _performSearch();
                      },
                    ),
                  ),
                  
                if (_priceRange.start > 0 || _priceRange.end < 1000)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text('Price: \$${_priceRange.start.round()} - \$${_priceRange.end.round()}'),
                      selected: true,
                      onSelected: (selected) {
                        if (!selected) {
                          setState(() => _priceRange = const RangeValues(0, 1000));
                          _performSearch();
                        }
                      },
                    ),
                  ),
                  
                if (_sortBy != 'newest')
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text('Sort: ${_getSortByText(_sortBy)}'),
                      selected: true,
                      onSelected: (selected) {
                        if (!selected) {
                          setState(() => _sortBy = 'newest');
                          _performSearch();
                        }
                      },
                    ),
                  ),
                  
                if (_categoryFilter != null)
                  FilterChip(
                    label: Text('Category: $_categoryFilter'),
                    selected: true,
                    onSelected: (selected) {
                      if (!selected) {
                        setState(() => _categoryFilter = null);
                        _performSearch();
                      }
                    },
                  ),
              ],
            ),
          ),
          
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? const Center(child: Text('No results found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final auction = _searchResults[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: auction.imageUrls.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        auction.imageUrls.first,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.image_not_supported,
                                          size: 60,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.grass, size: 60),
                              title: Text(
                                auction.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auction.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Current Bid: \$${auction.highestBid.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _getTimeRemainingText(auction.endTime),
                                    style: TextStyle(
                                      color: _getTimeRemainingColor(auction.endTime),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Ends: ${auction.endTime.day}/${auction.endTime.month}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Navigate to auction detail
                                Navigator.pushNamed(context, '/auction_detail', arguments: auction.id);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  String _getSortByText(String sortBy) {
    switch (sortBy) {
      case 'endingSoon': return 'Ending Soon';
      case 'priceAsc': return 'Price (Low to High)';
      case 'priceDesc': return 'Price (High to Low)';
      default: return 'Newest';
    }
  }
  
  String _getTimeRemainingText(DateTime endTime) {
    final now = DateTime.now();
    final difference = endTime.difference(now);
    
    if (difference.isNegative) {
      return 'Ended';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h left';
    } else {
      return '${difference.inMinutes}m left';
    }
  }
  
  Color _getTimeRemainingColor(DateTime endTime) {
    final now = DateTime.now();
    final difference = endTime.difference(now);
    
    if (difference.isNegative) {
      return Colors.red;
    } else if (difference.inHours < 6) {
      return Colors.orange;
    } else if (difference.inDays < 1) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }
}