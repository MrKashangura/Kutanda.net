// lib/features/auctions/screens/won_auction_checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/auction_model.dart';
import '../../../features/payment/screens/order_confirmation_screen.dart';
import '../../../features/payment/services/payment_service.dart';
import '../../../features/payment/widgets/delivery_address_form.dart';
import '../../../features/payment/widgets/payment_method_selector.dart';
import '../../../shared/widgets/bottom_navigation.dart';

class WonAuctionCheckoutScreen extends StatefulWidget {
  final String auctionId;
  
  const WonAuctionCheckoutScreen({
    super.key,
    required this.auctionId,
  });

  @override
  State<WonAuctionCheckoutScreen> createState() => _WonAuctionCheckoutScreenState();
}

class _WonAuctionCheckoutScreenState extends State<WonAuctionCheckoutScreen> {
  final _addressFormKey = GlobalKey<FormState>();
  final PaymentService _paymentService = PaymentService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  Auction? _auction;
  double _subtotal = 0.0;
  double _shippingFee = 10.0; // Default shipping fee
  double _tax = 0.0;
  double _total = 0.0;
  
  String? _selectedPaymentMethod;
  Map<String, dynamic> _deliveryAddress = {};
  bool _saveAddress = true;
  bool _isProcessingPayment = false;
  Map<String, dynamic>? _sellerProfile;

  @override
  void initState() {
    super.initState();
    _loadAuctionData();
    _loadUserAddress();
  }

  Future<void> _loadAuctionData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get auction details
      final auctionData = await _supabase
          .from('auctions')
          .select()
          .eq('id', widget.auctionId)
          .single();
      
      final auction = Auction.fromMap(auctionData);
      
      // Get seller information
      final sellerProfile = await _supabase
          .from('profiles')
          .select('display_name, email, avatar_url')
          .eq('id', auction.sellerId)
          .maybeSingle();
      
      // Calculate costs
      final subtotal = auction.highestBid;
      final tax = subtotal * 0.05;
      final total = subtotal + _shippingFee + tax;
      
      if (mounted) {
        setState(() {
          _auction = auction;
          _sellerProfile = sellerProfile;
          _subtotal = subtotal;
          _tax = tax;
          _total = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading auction: $e')),
        );
        Navigator.pop(context);
      }
    }
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
      
      if (profile['shipping_address'] != null) {
        setState(() {
          _deliveryAddress = Map<String, dynamic>.from(profile['shipping_address']);
        });
      }
    } catch (e) {
      // Handle error silently
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

  Future<void> _processPayment() async {
    if (_auction == null) return;
    
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
      
      // Create the auction order
      final orderId = await _paymentService.createOrder(
        userId: user.id,
        items: [
          {
            'item_id': _auction!.id,
            'quantity': 1,
            'is_auction': true
          }
        ],
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
      
      // Mark auction as paid
      await _supabase
          .from('auctions')
          .update({
            'is_paid': true,
            'order_id': orderId,
            'paid_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _auction!.id);
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Purchase'),
      ),
      body: _isLoading || _auction == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Auction summary
                  _buildAuctionSummary(),
                  
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

  Widget _buildAuctionSummary() {
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
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Congratulations! You won this auction',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Auction details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Auction image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: _auction!.imageUrls.isNotEmpty
                        ? Image.network(
                            _auction!.imageUrls.first,
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
                const SizedBox(width: 12),
                
                // Auction information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _auction!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Winning bid: ${formatCurrency(_auction!.highestBid)}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Auction ended: ${formatDate(_auction!.endTime)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Seller information
            if (_sellerProfile != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: _sellerProfile!['avatar_url'] != null
                          ? NetworkImage(_sellerProfile!['avatar_url'])
                          : null,
                      child: _sellerProfile!['avatar_url'] == null
                          ? const Icon(Icons.person, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seller:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _sellerProfile!['display_name'] ?? 
                            _sellerProfile!['email'] ?? 
                            'Plant Enthusiast',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            const Divider(height: 32),
            
            // Cost breakdown
            const Text(
              'Cost Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Auction price:'),
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
            const SizedBox(height: 8),
            
            const Divider(),
            
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
        
        // Complete purchase button
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
                    'Complete Purchase',
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
          'By completing your purchase, you agree to Kutanda\'s terms and conditions and privacy policy.',
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