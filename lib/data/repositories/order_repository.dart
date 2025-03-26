// lib/data/repositories/order_repository.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order_model.dart';

class OrderRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new order
  Future<Order?> createOrder(Order order) async {
    try {
      // Begin transaction
      // 1. Insert order record
      final orderResponse = await _supabase
          .from('orders')
          .insert(order.toMap())
          .select()
          .single();
      
      // 2. Insert order items
      for (final item in order.items) {
        final itemWithOrderId = item.copyWith(orderId: orderResponse['id']);
        await _supabase
            .from('order_items')
            .insert(itemWithOrderId.toMap());
      }
      
      // Load the complete order with items
      return getOrderById(orderResponse['id']);
    } catch (e, stackTrace) {
      log('❌ Error creating order: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final orderResponse = await _supabase
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();
      
      final itemsResponse = await _supabase
          .from('order_items')
          .select()
          .eq('order_id', orderId);
      
      final orderItems = itemsResponse
          .map((item) => OrderItem.fromMap(item))
          .toList();
      
      return Order.fromMap(orderResponse, orderItems: orderItems);
    } catch (e, stackTrace) {
      log('❌ Error getting order: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get orders for a user
  Future<List<Order>> getUserOrders(String userId) async {
    try {
      final orderResponse = await _supabase
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      final orders = <Order>[];
      
      for (final orderData in orderResponse) {
        final itemsResponse = await _supabase
            .from('order_items')
            .select()
            .eq('order_id', orderData['id']);
        
        final orderItems = itemsResponse
            .map((item) => OrderItem.fromMap(item))
            .toList();
        
        orders.add(Order.fromMap(orderData, orderItems: orderItems));
      }
      
      return orders;
    } catch (e, stackTrace) {
      log('❌ Error getting user orders: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': status.toString().split('.').last})
          .eq('id', orderId);
      
      return true;
    } catch (e, stackTrace) {
      log('❌ Error updating order status: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Update order with payment information
  Future<bool> updateOrderPayment(String orderId, String paymentId) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': OrderStatus.paid.toString().split('.').last,
            'payment_id': paymentId,
            'paid_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      
      return true;
    } catch (e, stackTrace) {
      log('❌ Error updating order payment: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Update order with shipping information
  Future<bool> updateOrderShipping(String orderId, String trackingNumber) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': OrderStatus.shipped.toString().split('.').last,
            'tracking_number': trackingNumber,
            'shipped_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      
      return true;
    } catch (e, stackTrace) {
      log('❌ Error updating order shipping: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Update order as delivered
  Future<bool> markOrderDelivered(String orderId) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': OrderStatus.delivered.toString().split('.').last,
            'delivered_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      
      return true;
    } catch (e, stackTrace) {
      log('❌ Error marking order delivered: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Cancel order
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': OrderStatus.cancelled.toString().split('.').last,
            'notes': reason,
          })
          .eq('id', orderId);
      
      return true;
    } catch (e, stackTrace) {
      log('❌ Error cancelling order: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}

extension OrderItemExtension on OrderItem {
  OrderItem copyWith({
    String? id,
    String? orderId,
    String? itemId,
    String? itemType,
    String? title,
    double? price,
    int? quantity,
    double? total,
    String? imageUrl,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      title: title ?? this.title,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}