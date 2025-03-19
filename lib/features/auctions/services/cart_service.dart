// lib/features/auctions/services/cart_service.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/fixed_price_listing_model.dart';

class CartService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Add item to cart
  Future<bool> addToCart(String itemId, int quantity) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if item already exists in cart
      final existingItem = await _supabase
          .from('cart_items')
          .select()
          .eq('user_id', user.id)
          .eq('item_id', itemId)
          .maybeSingle();

      if (existingItem != null) {
        // Update quantity
        final currentQuantity = existingItem['quantity'] as int;
        await _supabase
            .from('cart_items')
            .update({'quantity': currentQuantity + quantity})
            .eq('id', existingItem['id']);
        
        log('✅ Updated cart quantity for: $itemId');
      } else {
        // Add new item
        await _supabase.from('cart_items').insert({
          'user_id': user.id,
          'item_id': itemId,
          'quantity': quantity,
          'created_at': DateTime.now().toIso8601String(),
        });
        
        log('✅ Added to cart: $itemId');
      }
      
      return true;
    } catch (e, stackTrace) {
      log('❌ Error adding to cart: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get all items in user's cart
  Future<List<Map<String, dynamic>>> getCartItems() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      final response = await _supabase
          .from('cart_items')
          .select()
          .eq('user_id', user.id)
          .order('created_at');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      log('❌ Error getting cart items: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Update cart item quantity
  Future<bool> updateCartItemQuantity(String cartItemId, int quantity) async {
    try {
      if (quantity <= 0) {
        // If quantity is 0 or negative, remove item
        return removeFromCart(cartItemId);
      }
      
      await _supabase
          .from('cart_items')
          .update({'quantity': quantity})
          .eq('id', cartItemId);
      
      log('✅ Updated cart quantity: $cartItemId to $quantity');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error updating cart quantity: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Remove item from cart
  Future<bool> removeFromCart(String cartItemId) async {
    try {
      await _supabase
          .from('cart_items')
          .delete()
          .eq('id', cartItemId);
      
      log('✅ Removed from cart: $cartItemId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error removing from cart: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Clear entire cart
  Future<bool> clearCart() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }
      
      await _supabase
          .from('cart_items')
          .delete()
          .eq('user_id', user.id);
      
      log('✅ Cart cleared for user: ${user.id}');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error clearing cart: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get fixed price listing details
  Future<FixedPriceListing?> getFixedPriceListing(String listingId) async {
    try {
      final response = await _supabase
          .from('fixed_price_listings')
          .select()
          .eq('id', listingId)
          .maybeSingle();
      
      if (response == null) {
        return null;
      }
      
      return FixedPriceListing.fromMap(response);
    } catch (e, stackTrace) {
      log('❌ Error getting fixed price listing: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get cart count
  Future<int> getCartCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return 0;
      }
      
      final response = await _supabase
          .from('cart_items')
          .select('quantity')
          .eq('user_id', user.id);
      
      if (response.isEmpty) {
        return 0;
      }
      
      int totalItems = 0;
      for (final item in response) {
        totalItems += item['quantity'] as int;
      }
      
      return totalItems;
    } catch (e, stackTrace) {
      log('❌ Error getting cart count: $e', error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  /// Stream cart count for real-time updates
  Stream<int> streamCartCount() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }
    
    return _supabase
        .from('cart_items')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((items) {
          int count = 0;
          for (final item in items) {
            count += (item['quantity'] as int?) ?? 0;
          }
          return count;
        });
  }
}