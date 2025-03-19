// lib/features/payment/screens/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/fixed_price_listing_model.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import '../../auctions/services/cart_service.dart';
import '../services/payment_service.dart';
import '../widgets/delivery_address_form.dart';
import '../widgets/payment_method_selector.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService();
  final PaymentService _paymentService = PaymentService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _cartItems = [];
  List<FixedPriceListing> _listings = [];
  double _subtotal = 0.0;
  double _shippingFee = 10.0; // Default shipping fee
  double _tax = 0.0;
  double _total = 0.0;
  
  String? _selectedPaymentMethod;
  Map<String, dynamic> _deliveryAddress = {};
  bool _saveAddress = true;
  bool _isProcessingPayment = false;
  
  final _addressFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadCartItems();
    _loadUserAddress();
  }

  Future<void> _loadUserAddress() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      // Check if user has a saved address
      final profile = await _supabase
          .from('profiles')
          .select('shipping_address')
          .eq('id', user.id)
          .single();
      
      if (profile != null && profile['shipping_address'] != null) {
        setState(() {
          _deliveryAddress = Map<String, dynamic>.from(profile['shipping_address']);
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadCartItems() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to checkout')),
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
          _subtotal = 0.0;
          _total = 0.0;
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your cart is empty')),
          );
          Navigator.pop(context);
        }
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
      
      // Calculate totals
      double subtotal = 0.0;
      for (int i = 0; i < cartItems.length; i++) {
        final item = cartItems[i];
        final listing = listings.firstWhere(
          (l) => l.id == item['item_id'],
          orElse: () => throw Exception('Listing not found'),
        );
        subtotal += listing.price * (item['quantity'] as num);
      }
      
      // Calculate tax (assuming 5% tax rate)
      final tax = subtotal * 0.05;
      
      // Calculate total
      final total = subtotal + _shippingFee + tax;
      
      setState(() {
        _cartItems = cartItems;
        _listings = listings;
        _subtotal = subtotal;
        _tax = tax;
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

  Future<void> _processPayment() async {
    // Validate all required information
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }
    
    if (!_addressFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the delivery address')),
      );
      return;
    }
    
    // Save form data
    _addressFormKey.currentState!.save();
    
    setState(() => _isProcessingPayment = true);
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      // Save address if requested
      if (_saveAddress) {
        await _supabase
            .from('profiles')
            .update({'shipping_address': _deliveryAddress})
            .eq('id', user.id);
      }
      
      // Create order in the database
      final orderId = await _paymentService.createOrder(
        userId: user.id,
        items: _cartItems,
        subtotal: _subtotal,
        shipping: _shippingFee,
        tax: _tax,
        total: _total,
        shippingAddress: _deliveryAddress,
        paymentMethod: _selectedPaymentMethod!,
      );
      
      if (orderId == null) throw Exception('Failed to create order');
      
      // Process payment
      final paymentSuccess = await _paymentService.processPayment(
        orderId: orderId,
        amount: _total,
        paymentMethod: _selectedPaymentMethod!,
      );
      
      if (!paymentSuccess) throw Exception('Payment processing failed');
      
      // Clear cart after successful payment
      await _cartService.clearCart();
      
      if (mounted) {
        // Navigate to order confirmation page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(orderId: orderId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing payment: $e')),
        );
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  void _updateDeliveryAddress(Map<String, dynamic> address) {
    setState(() {
      _deliveryAddress = address;
    });
  }

  void _updateShippingMethod(String method, double fee) {
    setState(() {
      _shippingFee = fee;
      _total = _subtotal + _shippingFee + _tax;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary section
                  _buildOrderSummary(),
                  
                  const SizedBox(height: 24),
                  
                  // Delivery address section
                  _buildDeliveryAddressSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Shipping method section
                  _buildShippingMethodSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Payment method section
                  _buildPaymentMethodSection(),
                  
                  const SizedBox(height: 32),
                  
                  // Total and checkout button
                  _buildTotalSection(),
                  
                  const SizedBox(height: 40),
                ],
              ),
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

  Widget _buildOrderSummary() {
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
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Order items
            ...List.generate(_cartItems.length, (index) {
              final item = _cartItems[index];
              final listing = _listings.firstWhere(
                (l) => l.id == item['item_id'],
                orElse: () => throw Exception('Listing not found'),
              );
              final quantity = item['quantity'] as int;
              final itemTotal = listing.price * quantity;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: listing.imageUrls.isNotEmpty
                            ? Image.network(
                                listing.imageUrls.first,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Item details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Qty: $quantity × ${formatCurrency(listing.price)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Item price
                    Text(
                      formatCurrency(itemTotal),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
            
            const Divider(),
            
            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text(formatCurrency(_subtotal)),
              ],
            ),
            const SizedBox(height: 8),
            
            // Shipping
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Shipping'),
                Text(formatCurrency(_shippingFee)),
              ],
            ),
            const SizedBox(height: 8),
            
            // Tax
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tax (5%)'),
                Text(formatCurrency(_tax)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatCurrency(_total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryAddressSection() {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_deliveryAddress.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _deliveryAddress = {};
                      });
                    },
                    child: const Text('Change'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            DeliveryAddressForm(
              formKey: _addressFormKey,
              initialAddress: _deliveryAddress,
              onAddressChanged: _updateDeliveryAddress,
            ),
            
            // Save address checkbox
            Row(
              children: [
                Checkbox(
                  value: _saveAddress,
                  onChanged: (value) {
                    setState(() {
                      _saveAddress = value ?? true;
                    });
                  },
                ),
                const Text('Save this address for future purchases'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingMethodSection() {
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
            const Text(
              'Shipping Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Standard shipping
            RadioListTile<double>(
              title: const Text('Standard Shipping'),
              subtitle: const Text('3-5 business days'),
              secondary: Text(formatCurrency(10.0)),
              value: 10.0,
              groupValue: _shippingFee,
              onChanged: (value) {
                _updateShippingMethod('standard', value!);
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            // Express shipping
            RadioListTile<double>(
              title: const Text('Express Shipping'),
              subtitle: const Text('1-2 business days'),
              secondary: Text(formatCurrency(20.0)),
              value: 20.0,
              groupValue: _shippingFee,
              onChanged: (value) {
                _updateShippingMethod('express', value!);
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
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
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            PaymentMethodSelector(
              selectedMethod: _selectedPaymentMethod,
              onMethodSelected: (method) {
                setState(() {
                  _selectedPaymentMethod = method;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Column(
      children: [
        // Total amount
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              formatCurrency(_total),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Place order button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isProcessingPayment ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isProcessingPayment
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Place Order',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        
        // Terms and policies text
        const SizedBox(height: 12),
        Text(
          'By placing your order, you agree to Kutanda\'s terms and conditions and privacy policy.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}