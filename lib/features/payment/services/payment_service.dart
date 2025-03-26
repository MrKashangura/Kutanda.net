// lib/features/payment/services/payment_service.dart
import 'dart:developer' as dev;
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new order in the database
  Future<String?> createOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double shipping,
    required double tax,
    required double total,
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
  }) async {
    try {
      // Generate a unique order ID
      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000)}';
      
      // Create order record
      await _supabase.from('orders').insert({
        'id': orderId,
        'user_id': userId,
        'subtotal': subtotal,
        'shipping_fee': shipping,
        'tax': tax,
        'total': total,
        'shipping_address': shippingAddress,
        'payment_method': paymentMethod,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Create order items
      for (final item in items) {
        final listing = await _supabase
            .from('fixed_price_listings')
            .select()
            .eq('id', item['item_id'])
            .single();
        
        await _supabase.from('order_items').insert({
          'order_id': orderId,
          'item_id': item['item_id'],
          'quantity': item['quantity'],
          'price': listing['price'],
          'total': listing['price'] * item['quantity'],
        });
        
        // Update inventory
        await _supabase
            .from('fixed_price_listings')
            .update({
              'quantity_available': listing['quantity_available'] - item['quantity'],
              'quantity_sold': (listing['quantity_sold'] ?? 0) + item['quantity'],
            })
            .eq('id', item['item_id']);
      }
      
      dev.log('✅ Order created successfully: $orderId');
      return orderId;
    } catch (e, stackTrace) {
      dev.log('❌ Error creating order: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Process a payment
  Future<bool> processPayment({
    required String orderId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      // In a real app, this would integrate with a payment gateway like Stripe, PayPal, etc.
      // For now, we'll simulate a successful payment
      
      // Create payment record
      final paymentId = 'PAY-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000)}';
      
      await _supabase.from('payments').insert({
        'id': paymentId,
        'order_id': orderId,
        'amount': amount,
        'payment_method': paymentMethod,
        'status': 'succeeded',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Update order status to paid
      await _supabase
          .from('orders')
          .update({
            'status': 'paid',
            'payment_id': paymentId,
            'paid_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      
      dev.log('✅ Payment processed successfully: $paymentId');
      return true;
    } catch (e, stackTrace) {
      dev.log('❌ Error processing payment: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get order details
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    try {
      final order = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', orderId)
          .single();
      
      return Map<String, dynamic>.from(order);
    } catch (e, stackTrace) {
      dev.log('❌ Error getting order details: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get user's orders
  Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final orders = await _supabase
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(orders);
    } catch (e, stackTrace) {
      dev.log('❌ Error getting user orders: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Cancel an order
  Future<bool> cancelOrder(String orderId) async {
    try {
      // Check if the order is cancellable (only pending or paid, not shipped)
      final order = await _supabase
          .from('orders')
          .select('status')
          .eq('id', orderId)
          .single();
      
      final status = order['status'] as String;
      if (status != 'pending' && status != 'paid') {
        throw Exception('Order cannot be cancelled in current state: $status');
      }
      
      // Update order status
      await _supabase
          .from('orders')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      
      // Restore inventory quantities
      final orderItems = await _supabase
          .from('order_items')
          .select('item_id, quantity')
          .eq('order_id', orderId);
      
      for (final item in orderItems) {
        final itemId = item['item_id'];
        final quantity = item['quantity'] as int;
        
        final listing = await _supabase
            .from('fixed_price_listings')
            .select('quantity_available, quantity_sold')
            .eq('id', itemId)
            .single();
        
        await _supabase
            .from('fixed_price_listings')
            .update({
              'quantity_available': (listing['quantity_available'] as int) + quantity,
              'quantity_sold': (listing['quantity_sold'] as int) - quantity,
            })
            .eq('id', itemId);
      }
      
      dev.log('✅ Order cancelled successfully: $orderId');
      return true;
    } catch (e, stackTrace) {
      dev.log('❌ Error cancelling order: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}