// lib/features/auctions/screens/shopping_cart_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/helpers.dart';
import '../../../data/models/auction_model.dart';
import '../../../data/models/fixed_price_listing_model.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import '../services/cart_service.dart';
import 'checkout_screen.dart';

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  final CartService _cartService = CartService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  List<CartItem> _cartItems = [];
  Map<String, FixedPriceListing?> _fixedPriceListings = {};
  Map<String, Auction?> _auctions = {};
  double _subtotal = 0.0;
  double _shippingFee = 0.0;
  double _tax = 0.0;
  double _total = 0.0;
  bool _isProcessingCheckout = false;

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
      
      // Load fixed price listings and auctions details
      for (final item in cartItems) {
        if (item.itemType == 'fixed_price') {
          final listing = await _cartService.getFixedPriceListing(item.itemId);
          _fixedPriceListings[item.itemId] = listing;
        } else if (item.itemType == 'auction') {
          final auction = await _cartService.getAuction(item.itemId);
          _auctions[item.itemId] = auction;
        }
      }
      
      // Calculate totals
      final totals = await _cartService.calculateCartTotals();
      
      if (mounted) {
        setState(() {
          _cartItems = cartItems;
          _subtotal = totals['subtotal'] ?? 0.0;
          _shippingFee = totals['shipping'] ?? 0.0;
          _tax = totals['tax'] ?? 0.0;
          _total = totals['total'] ?? 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cart: $e')),
        );
      }
    }
  }

  Future<void> _updateQuantity(CartItem item, int quantity) async {
    try {
      if (item.itemType == 'auction') {
        // Auctions always have quantity of 1
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auction items have a fixed quantity of 1')),
        );
        return;
      }
      
      // Check if new quantity is valid
      final listing = _fixedPriceListings[item.itemId];
      if (listing != null && quantity > listing.quantityAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only ${listing.quantityAvailable} available')),
        );
        return;
      }
      
      // Update quantity
      final success = await _cartService.updateCartItemQuantity(item.id, quantity);
      
      if (success) {
        // Reload cart to get updated totals
        await _loadCartItems();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update quantity')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating quantity: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(CartItem item) async {
    try {
      final success = await _cartService.removeFromCart(item.id);
      
      if (success) {
        if (mounted) {
          setState(() {
            _cartItems.remove(item);
            if (item.itemType == 'fixed_price') {
              _fixedPriceListings.remove(item.itemId);
            } else if (item.itemType == 'auction') {
              _auctions.remove(item.itemId);
            }
          });
          
          // Recalculate totals
          final totals = await _cartService.calculateCartTotals();
          
          setState(() {
            _subtotal = totals['subtotal'] ?? 0.0;
            _shippingFee = totals['shipping'] ?? 0.0;
            _tax = totals['tax'] ?? 0.0;
            _total = totals['total'] ?? 0.0;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item removed from cart')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove item')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: $e')),
        );
      }
    }
  }

  void _showRemoveDialog(CartItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: const Text('Are you sure you want to remove this item from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeItem(item);
            },
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToCheckout() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }
    
    setState(() => _isProcessingCheckout = true);
    
    try {
      // Check inventory before proceeding
      bool hasInventoryIssue = false;
      
      for (final item in _cartItems) {
        if (item.itemType == 'fixed_price') {
          final listing = await _cartService.getFixedPriceListing(item.itemId);
          if (listing == null || listing.quantityAvailable < item.quantity) {
            hasInventoryIssue = true;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.title} has insufficient inventory available')),
              );
            }
            break;
          }
        }
      }
      
      if (hasInventoryIssue) {
        setState(() => _isProcessingCheckout = false);
        _loadCartItems(); // Refresh cart
        return;
      }
      
      // Navigate to checkout screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutScreen(),
          ),
        ).then((_) => _loadCartItems());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error proceeding to checkout: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingCheckout = false);
      }
    }
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
              return Dismissible(
                key: Key('cart_${item.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                confirmDismiss: (direction) async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Remove Item'),
                      content: const Text('Are you sure you want to remove this item from your cart?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('CANCEL'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('REMOVE'),
                        ),
                      ],
                    ),
                  );
                  return result ?? false;
                },
                onDismissed: (direction) {
                  _removeItem(item);
                },
                child: Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: item.imageUrl != null
                                ? Image.network(
                                    item.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image_not_supported, size: 40),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 40),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Item details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatCurrency(item.price),
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: item.itemType == 'auction' 
                                                ? Colors.purple.withOpacity(0.1) 
                                                : Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: item.itemType == 'auction' 
                                                  ? Colors.purple 
                                                  : Colors.blue,
                                            ),
                                          ),
                                          child: Text(
                                            item.itemType == 'auction' ? 'Auction' : 'Fixed Price',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: item.itemType == 'auction' 
                                                  ? Colors.purple 
                                                  : Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => _showRemoveDialog(item),
                                    splashRadius: 24,
                                    tooltip: 'Remove',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Quantity controls
                              if (item.itemType == 'fixed_price')
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Text('Quantity: '),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline),
                                          onPressed: item.quantity > 1 
                                              ? () => _updateQuantity(item, item.quantity - 1) 
                                              : null,
                                          splashRadius: 20,
                                          iconSize: 20,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline),
                                          onPressed: () => _updateQuantity(item, item.quantity + 1),
                                          splashRadius: 20,
                                          iconSize: 20,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      formatCurrency(item.price * item.quantity),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              
                              // Fixed quantity for auctions
                              if (item.itemType == 'auction')
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Winning bid'),
                                    Text(
                                      formatCurrency(item.price),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:'),
              Text(formatCurrency(_subtotal)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Shipping:'),
              Text(formatCurrency(_shippingFee)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tax (5%):'),
              Text(formatCurrency(_tax)),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                formatCurrency(_total),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Checkout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessingCheckout ? null : _proceedToCheckout,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: _isProcessingCheckout
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Proceed to Checkout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}