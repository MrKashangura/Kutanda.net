// lib/features/auctions/screens/fixed_price_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/helpers.dart';
import '../../../data/models/fixed_price_listing_model.dart';
import '../services/cart_service.dart';

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
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  FixedPriceListing? _listing;
  Map<String, dynamic>? _sellerProfile;
  int _quantity = 1;
  bool _isAddingToCart = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadListingData();
    _checkIfSaved();
  }

  Future<void> _loadListingData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get listing details
      final response = await _supabase
          .from('fixed_price_listings')
          .select()
          .eq('id', widget.listingId)
          .maybeSingle();
      
      if (response == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing not found')),
          );
          Navigator.pop(context);
        }
        return;
      }
      
      final listing = FixedPriceListing.fromMap(response);
      
      // Get seller profile
      final sellerProfile = await _supabase
          .from('profiles')
          .select('display_name, email, avatar_url')
          .eq('id', listing.sellerId)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _listing = listing;
          _sellerProfile = sellerProfile;
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

  Future<void> _checkIfSaved() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      final savedItem = await _supabase
          .from('watchlist')
          .select()
          .eq('user_id', user.id)
          .eq('item_id', widget.listingId)
          .eq('item_type', 'fixed_price')
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _isSaved = savedItem != null;
        });
      }
    } catch (e) {
      // Ignore errors checking saved status
    }
  }

  Future<void> _toggleSaved() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to save items')),
        );
        return;
      }
      
      if (_isSaved) {
        // Remove from saved
        await _supabase
            .from('watchlist')
            .delete()
            .eq('user_id', user.id)
            .eq('item_id', widget.listingId)
            .eq('item_type', 'fixed_price');
        
        if (mounted) {
          setState(() => _isSaved = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from saved items')),
          );
        }
      } else {
        // Add to saved
        await _supabase.from('watchlist').insert({
          'user_id': user.id,
          'item_id': widget.listingId,
          'item_type': 'fixed_price',
          'created_at': DateTime.now().toIso8601String(),
        });
        
        if (mounted) {
          setState(() => _isSaved = true);
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
    final newQuantity = _quantity + delta;
    if (newQuantity < 1) return;
    
    if (_listing != null && newQuantity > _listing!.quantityAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only ${_listing!.quantityAvailable} available')),
      );
      return;
    }
    
    setState(() => _quantity = newQuantity);
  }

  Future<void> _addToCart() async {
    if (_listing == null) return;
    
    setState(() => _isAddingToCart = true);
    
    try {
      final success = await _cartService.addToCart(_listing!.id, _quantity);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_quantity ${_quantity > 1 ? 'items' : 'item'} added to cart'),
              action: SnackBarAction(
                label: 'View Cart',
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
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
    
    setState(() => _isAddingToCart = true);
    
    try {
      // Add to cart first
      final success = await _cartService.addToCart(_listing!.id, _quantity);
      
      if (success && mounted) {
        // Navigate to checkout
        Navigator.pushNamed(context, '/checkout');
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
        setState(() => _isAddingToCart = false);
      }
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        actions: [
          IconButton(
            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: _toggleSaved,
            tooltip: _isSaved ? 'Remove from saved' : 'Save for later',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality
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
                  
                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and availability
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                listing.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isAvailable ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isAvailable ? 'Available' : 'Sold Out',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Price
                        Text(
                          formatCurrency(listing.price),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Availability
                        Text(
                          '${listing.quantityAvailable} available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Seller info
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
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
                        
                        const SizedBox(height: 24),
                        
                        // Description Header
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Description
                        Text(
                          listing.description,
                          style: const TextStyle(fontSize: 16),
                        ),
                        
                        const SizedBox(height: 100), // Space for bottom action bar
                      ],
                    ),
                  ),
                ],
              ),
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
                        'Total: ${formatCurrency(listing.price * _quantity)}',
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
                          onPressed: _isAddingToCart ? null : _buyNow,
                          icon: _isAddingToCart
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
                            'This item is currently sold out. Save it to your wishlist to be notified when it becomes available again.',
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Wishlist button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _toggleSaved,
                      icon: Icon(
                        _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      ),
                      label: Text(_isSaved ? 'Saved to Wishlist' : 'Save to Wishlist'),
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