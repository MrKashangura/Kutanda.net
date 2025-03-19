// lib/features/payment/screens/order_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import '../services/payment_service.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final String orderId;
  
  const OrderConfirmationScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  final PaymentService _paymentService = PaymentService();
  
  bool _isLoading = true;
  Map<String, dynamic>? _orderDetails;
  List<dynamic> _orderItems = [];
  String _orderStatus = 'Processing';
  DateTime? _estimatedDelivery;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
    _calculateEstimatedDelivery();
  }

  Future<void> _loadOrderDetails() async {
    setState(() => _isLoading = true);
    
    try {
      final orderDetails = await _paymentService.getOrderDetails(widget.orderId);
      
      if (orderDetails != null) {
        setState(() {
          _orderDetails = orderDetails;
          _orderItems = orderDetails['order_items'] ?? [];
          _orderStatus = orderDetails['status'] ?? 'Processing';
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error loading order details')),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateEstimatedDelivery() {
    // For now, just estimate 5-7 business days from now
    final now = DateTime.now();
    _estimatedDelivery = now.add(const Duration(days: 7));
  }

  Future<void> _copyOrderId() async {
    await Clipboard.setData(ClipboardData(text: widget.orderId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order ID copied to clipboard')),
      );
    }
  }

  Future<void> _trackOrder() async {
    // In a real app, this would navigate to an order tracking screen
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order tracking coming soon')),
      );
    }
  }

  Future<void> _contactSupport() async {
    // In a real app, this would open a support ticket or chat
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support contact coming soon')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmation'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/buyer_dashboard',
                (route) => false,
              );
            },
            tooltip: 'Go to Home',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Success message
                  _buildSuccessHeader(),
                  
                  const SizedBox(height: 32),
                  
                  // Order Details
                  _buildOrderDetailsCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Delivery Information
                  _buildDeliveryInfoCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  _buildActionButtons(),
                  
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

  Widget _buildSuccessHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Thank You for Your Order!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your order has been placed successfully and is now being processed.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
    final total = _orderDetails?['total'] ?? 0.0;
    
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
                  'Order Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _orderStatus,
                  style: TextStyle(
                    color: _getStatusColor(_orderStatus),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Order ID
            Row(
              children: [
                const Text(
                  'Order ID:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.orderId,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: _copyOrderId,
                  tooltip: 'Copy Order ID',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            // Order Date
            Row(
              children: [
                const Text(
                  'Order Date:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(_orderDetails != null && _orderDetails!['created_at'] != null
                    ? formatDate(DateTime.parse(_orderDetails!['created_at']))
                    : 'N/A'),
              ],
            ),
            
            // Payment Method
            Row(
              children: [
                const Text(
                  'Payment Method:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(_getPaymentMethodName(_orderDetails?['payment_method'] ?? '')),
              ],
            ),
            
            const Divider(height: 32),
            
            // Order Items
            const Text(
              'Items:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // Item list
            for (final item in _orderItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item['quantity']}x ${_getItemName(item['item_id'])}'),
                    Text(formatCurrency((item['price'] as num).toDouble() * (item['quantity'] as num))),
                  ],
                ),
              ),
            
            const Divider(height: 24),
            
            // Order Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text(formatCurrency((_orderDetails?['subtotal'] as num?)?.toDouble() ?? 0.0)),
              ],
            ),
            const SizedBox(height: 4),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Shipping:'),
                Text(formatCurrency((_orderDetails?['shipping_fee'] as num?)?.toDouble() ?? 0.0)),
              ],
            ),
            const SizedBox(height: 4),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tax:'),
                Text(formatCurrency((_orderDetails?['tax'] as num?)?.toDouble() ?? 0.0)),
              ],
            ),
            const SizedBox(height: 8),
            
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
                  formatCurrency((total as num).toDouble()),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfoCard() {
    // Extract shipping address
    final shippingAddress = _orderDetails?['shipping_address'] as Map<String, dynamic>? ?? {};
    
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
              'Delivery Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Estimated Delivery
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Estimated Delivery:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(_estimatedDelivery != null
                    ? formatDate(_estimatedDelivery!)
                    : 'Calculating...'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Shipping Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shipping Address:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(shippingAddress['full_name'] ?? 'N/A'),
                      Text(shippingAddress['address_line1'] ?? 'N/A'),
                      if (shippingAddress['address_line2'] != null && shippingAddress['address_line2'].isNotEmpty)
                        Text(shippingAddress['address_line2']),
                      Text('${shippingAddress['city'] ?? 'N/A'}, ${shippingAddress['state'] ?? 'N/A'} ${shippingAddress['zip_code'] ?? 'N/A'}'),
                      Text(shippingAddress['country'] ?? 'N/A'),
                      const SizedBox(height: 4),
                      Text('Phone: ${shippingAddress['phone'] ?? 'N/A'}'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _trackOrder,
          icon: const Icon(Icons.local_shipping),
          label: const Text('Track Order'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _contactSupport,
          icon: const Icon(Icons.headset_mic),
          label: const Text('Contact Support'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/buyer_dashboard',
              (route) => false,
            );
          },
          icon: const Icon(Icons.shopping_bag),
          label: const Text('Continue Shopping'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'card':
        return 'Credit/Debit Card';
      case 'paypal':
        return 'PayPal';
      case 'mobile_money':
        return 'Mobile Money';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return method;
    }
  }

  String _getItemName(String itemId) {
    // In a real app, this would look up the item name
    // For now, return a placeholder
    return 'Plant Item';
  }
}