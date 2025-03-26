// lib/features/auctions/screens/fixed_price_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/helpers.dart';
import '../../../data/models/fixed_price_listing_model.dart';
import '../../../data/models/watchlist_item_model.dart';
import '../screens/checkout_screen.dart';
import '../screens/shopping_cart_screen.dart';
import '../services/cart_service.dart';
import '../services/fixed_price_service.dart';
import '../services/watchlist_service.dart';

class FixedPriceDetailScreen extends StatefulWidget {
  final String listingId;
  
  const FixedPriceDetailScreen({
    super.key,
    required this.listingId,
  });

  @override
  State<FixedPriceDetailScreen> createState() => _FixedPriceDetailScreenState();
}

class _FixedPriceDetailScreenState extends State<FixedPriceDetailScreen> {
  final CartService _cartService = CartService();
  final FixedPriceService _fixedPriceService = FixedPriceService();
  final WatchlistService _watchlistService = WatchlistService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  FixedPriceListing? _listing;
  Map<String, dynamic>? _sellerProfile;
  bool _isSaved = false;
  bool _isAddingToCart = false;
  bool _isBuyingNow = false;
  int _quantity = 1;
  int _cartCount = 0;
  
  final PageController _imageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadListingData();
    _loadCartCount();
  }
  
  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _loadListingData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get listing details
      final listing = await _fixedPriceService.getListingById(widget.listingId);
      
      if (listing == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing not found')),
          );
          Navigator.pop(context);
        }
        return;
      }
      
      // Get seller profile
      final sellerProfile = await _supabase
          .from('profiles')
          .select('display_name, email, avatar_url, rating')
          .eq('id', listing.sellerId)
          .maybeSingle();
      
      // Check if listing is in watchlist
      final user = _supabase.auth.currentUser;
      bool isSaved = false;
      
      if (user != null) {
        final watchlistData = await _watchlistService.isInWatchlist(widget.listingId);
        isSaved = watchlistData;
      }
      
      if (mounted) {
        setState(() {
          _listing = listing;
          _sellerProfile = sellerProfile;
          _isSaved = isSaved;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading listing: $e')),
        );
      }
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
      // Silently handle cart count loading failures
    }
  }
  
  Future<void> _toggleSaved() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to save items')),
      );
      return;
    }
    
    try {
      if (_isSaved) {
        // Remove from watchlist
        await _watchlistService.removeFromWatchlist(widget.listingId);
        
        setState(() => _isSaved = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from saved items')),
          );
        }
      } else {
        // Add to watchlist
        await _watchlistService.addToWatchlist(widget.listingId, WatchlistItemType.fixedPrice);
        
        setState(() => _isSaved = true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to saved items')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating saved items: $e')),
        );
      }
    }
  }
  
  void _updateQuantity(int delta) {
    if (_listing == null) return;
    
    final newQuantity = _quantity + delta;
    if (newQuantity < 1) return;
    
    if (newQuantity > _listing!.quantityAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only ${_listing!.quantityAvailable} available')),
      );
      return;
    }
    
    setState(() => _quantity = newQuantity);
  }
  
  Future<void> _addToCart() async {
    if (_listing == null) return;
    
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add items to cart')),
      );
      return;
    }
    
    setState(() => _isAddingToCart = true);
    
    try {
      final success = await _cartService.addToCart(_listing!.id, _quantity);
      
      // Reload cart count
      await _loadCartCount();
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_quantity ${_quantity > 1 ? 'items' : 'item'} added to cart'),
              action: SnackBarAction(
                label: 'View Cart',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ShoppingCartScreen()),
                  ).then((_) => _loadCartCount());
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add to cart')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding to cart: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }
  
  Future<void> _buyNow() async {
    if (_listing == null) return;
    
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to purchase items')),
      );
      return;
    }
    
    setState(() => _isBuyingNow = true);
    
    try {
      // Add to cart first
      final success = await _cartService.addToCart(_listing!.id, _quantity);
      
      if (success && mounted) {
        // Navigate to checkout
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CheckoutScreen()),
        ).then((_) => _loadCartCount());
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to process purchase')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing purchase: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBuyingNow = false);
      }
    }
  }
  
  void _shareListing() {
    // Implement share functionality
    if (_listing != null) {
      final url = 'https://kutanda.net/listings/${_listing!.id}';
      final title = _listing!.title;
      
      // Show share dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sharing $title: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_listing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Not Found')),
        body: const Center(child: Text('The requested item could not be found')),
      );
    }
    
    final listing = _listing!;
    final isAvailable = listing.quantityAvailable > 0 && listing.isActive;
    final isLowStock = isAvailable && listing.quantityAvailable < 5;
    final subtotal = listing.price * _quantity;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        actions: [
          IconButton(
            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: _toggleSaved,
            tooltip: _isSaved ? 'Remove from saved' : 'Save for later',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ShoppingCartScreen()),
                  ).then((_) => _loadCartCount());
                },
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
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareListing,
            tooltip: 'Share',
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: ListView(
              children: [
                // Image gallery
                Stack(
                  children: [
                    SizedBox(
                      height: 250,
                      child: PageView.builder(
                        controller: _imageController,
                        onPageChanged: (index) {
                          setState(() => _currentImageIndex = index);
                        },
                        itemCount: listing.imageUrls.isEmpty ? 1 : listing.imageUrls.length,
                        itemBuilder: (context, index) {
                          if (listing.imageUrls.isEmpty) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.image, size: 100, color: Colors.grey),
                              ),
                            );
                          }
                          
                          return Image.network(
                            listing.imageUrls[index],
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
                    
                    // Featured badge
                    if (listing.isFeatured)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Featured',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    
                    // Availability badge
                    Positioned(
                      top: listing.isFeatured ? 54 : 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isAvailable 
                              ? (isLowStock ? Colors.orange : Colors.green)
                              : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isAvailable
                              ? (isLowStock 
                                  ? 'Low Stock (${listing.quantityAvailable})'
                                  : 'In Stock')
                              : 'Out of Stock',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    // Image indicators
                    if (listing.imageUrls.length > 1)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            listing.imageUrls.length,
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
                        listing.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Price
                      Text(
                        formatCurrency(listing.price),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Seller info
                      _buildSellerCard(),
                      
                      const SizedBox(height: 24),
                      
                      // Availability info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? (isLowStock ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1))
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isAvailable
                                ? (isLowStock ? Colors.orange : Colors.green)
                                : Colors.red,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isAvailable
                                  ? (isLowStock ? Icons.warning_amber : Icons.check_circle)
                                  : Icons.cancel,
                              color: isAvailable
                                  ? (isLowStock ? Colors.orange : Colors.green)
                                  : Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAvailable
                                        ? (isLowStock
                                            ? 'Low Stock'
                                            : 'In Stock')
                                        : 'Currently Unavailable',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isAvailable
                                          ? (isLowStock ? Colors.orange[800] : Colors.green[800])
                                          : Colors.red[800],
                                    ),
                                  ),
                                  Text(
                                    isAvailable
                                        ? '${listing.quantityAvailable} ${listing.quantityAvailable > 1 ? 'units' : 'unit'} available'
                                        : 'This item is currently out of stock',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isAvailable
                                          ? (isLowStock ? Colors.orange[700] : Colors.green[700])
                                          : Colors.red[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                        listing.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                      
                      const SizedBox(height: 100), // Space for action bar
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Fixed action bar at bottom
          if (isAvailable)
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quantity selector
                  Row(
                    children: [
                      const Text(
                        'Quantity:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _quantity > 1 ? () => _updateQuantity(-1) : null,
                      ),
                      Text(
                        _quantity.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _quantity < listing.quantityAvailable ? () => _updateQuantity(1) : null,
                      ),
                      const Spacer(),
                      Text(
                        'Total: ${formatCurrency(subtotal)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      // Add to Cart button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isAddingToCart ? null : _addToCart,
                          icon: _isAddingToCart
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.shopping_cart),
                          label: const Text('Add to Cart'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Buy Now button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isBuyingNow ? null : _buyNow,
                          icon: _isBuyingNow
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.flash_on),
                          label: const Text('Buy Now'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Out of stock message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This item is currently sold out. Save it to be notified when it becomes available again.',
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _toggleSaved,
                      icon: Icon(
                        _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      ),
                      label: Text(_isSaved ? 'Saved' : 'Save for Later'),
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
}