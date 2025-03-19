// lib/features/auctions/screens/shopping_cart_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/helpers.dart';
import '../../../data/models/fixed_price_listing_model.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import '../services/cart_service.dart';
import '../widgets/cart_item_widget.dart';

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  final CartService _cartService = CartService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _cartItems = [];
  List<FixedPriceListing> _listings = [];
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to view your cart')),
          );
          Navigator.pop(context);
        }
        return;
      }
      
      // Load cart items
      final cartItems = await _cartService.getCartItems();
      
      if (cartItems.isEmpty) {
        setState(() {
          _cartItems = [];
          _listings = [];
          _total = 0.0;
          _isLoading = false;
        });
        return;
      }
      
      // Get listing details for each cart item
      final listings = <FixedPriceListing>[];
      for (final item in cartItems) {
        final listing = await _cartService.getFixedPriceListing(item['item_id']);
        if (listing != null) {
          listings.add(listing);
        }
      }
      
      // Calculate total
      double total = 0.0;
      for (int i = 0; i < cartItems.length; i++) {
        final item = cartItems[i];
        final listing = listings.firstWhere(
          (l) => l.id == item['item_id'],
          orElse: () => throw Exception('Listing not found'),
        );
        total += listing.price * (item['quantity'] as num);
      }
      
      setState(() {
        _cartItems = cartItems;
        _listings = listings;
        _total = total;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cart: $e')),
        );
      }
    }
  }

  Future<void> _updateQuantity(FixedPriceListing listing, int quantity) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      // Find the cart item
      final cartItem = _cartItems.firstWhere(
        (item) => item['item_id'] == listing.id,
        orElse: () => throw Exception('Cart item not found'),
      );
      
      // Update the quantity
      await _cartService.updateCartItemQuantity(cartItem['id'], quantity);
      
      // Update local state
      setState(() {
        final index = _cartItems.indexOf(cartItem);
        _cartItems[index]['quantity'] = quantity;
        
        // Recalculate total
        _total = 0.0;
        for (int i = 0; i < _cartItems.length; i++) {
          final item = _cartItems[i];
          final listing = _listings.firstWhere(
            (l) => l.id == item['item_id'],
            orElse: () => throw Exception('Listing not found'),
          );
          _total += listing.price * (item['quantity'] as num);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating quantity: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(FixedPriceListing listing) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      // Find the cart item
      final cartItem = _cartItems.firstWhere(
        (item) => item['item_id'] == listing.id,
        orElse: () => throw Exception('Cart item not found'),
      );
      
      // Remove from cart
      await _cartService.removeFromCart(cartItem['id']);
      
      // Update local state
      setState(() {
        _cartItems.removeWhere((item) => item['item_id'] == listing.id);
        _listings.removeWhere((l) => l.id == listing.id);
        
        // Recalculate total
        _total = 0.0;
        for (int i = 0; i < _cartItems.length; i++) {
          final item = _cartItems[i];
          final listing = _listings.firstWhere(
            (l) => l.id == item['item_id'],
            orElse: () => throw Exception('Listing not found'),
          );
          _total += listing.price * (item['quantity'] as num);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removed from cart')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: $e')),
        );
      }
    }
  }

  Future<void> _proceedToCheckout() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }
    
    // Navigate to checkout screen
    Navigator.pushNamed(context, '/checkout');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCartItems,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : _buildCartContent(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_cartItems.isNotEmpty)
            _buildCheckoutBar(),
          BottomNavigation(
            currentDestination: NavDestination.dashboard,
            onDestinationSelected: (destination) {
              handleNavigation(context, destination, false);
            },
            isSellerMode: false,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items to your cart to see them here',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/explore');
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Browse Plants'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _cartItems.length,
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              final listing = _listings.firstWhere(
                (l) => l.id == item['item_id'],
                orElse: () => throw Exception('Listing not found'),
              );
              final quantity = item['quantity'] as int;
              
              return CartItemWidget(
                listing: listing,
                quantity: quantity,
                onQuantityChanged: _updateQuantity,
                onRemove: _removeItem,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              Text(
                formatCurrency(_total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _proceedToCheckout,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Proceed to Checkout'),
          ),
        ],
      ),
    );
  }
}