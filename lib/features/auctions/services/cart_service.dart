// lib/features/auctions/services/cart_service.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/auction_model.dart';
import '../../../data/models/fixed_price_listing_model.dart';

class CartItem {
  final String id;
  final String itemId;
  final String itemType; // 'auction' or 'fixed_price'
  final int quantity;
  final double price; // Cached price at time of adding to cart
  final String title; // Cached title
  final String? imageUrl; // Cached image URL

  CartItem({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.quantity,
    required this.price,
    required this.title,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'item_type': itemType,
      'quantity': quantity,
      'price': price,
      'title': title,
      'image_url': imageUrl,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      itemId: map['item_id'],
      itemType: map['item_type'],
      quantity: map['quantity'],
      price: (map['price'] as num).toDouble(),
      title: map['title'] ?? 'Unknown Item',
      imageUrl: map['image_url'],
    );
  }

  CartItem copyWith({
    String? id,
    String? itemId,
    String? itemType,
    int? quantity,
    double? price,
    String? title,
    String? imageUrl,
  }) {
    return CartItem(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class CartService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Add fixed price item to cart
  Future<bool> addToCart(String itemId, int quantity) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get item details to store in cart
      final listing = await _supabase
          .from('fixed_price_listings')
          .select()
          .eq('id', itemId)
          .single();

      final fixedPriceListing = FixedPriceListing.fromMap(listing);

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
        final newQuantity = currentQuantity + quantity;

        // Check if requested quantity is available
        if (newQuantity > fixedPriceListing.quantityAvailable) {
          throw Exception('Not enough inventory available');
        }

        await _supabase
            .from('cart_items')
            .update({'quantity': newQuantity})
            .eq('id', existingItem['id']);
        
        log('✅ Updated cart quantity for: $itemId');
      } else {
        // Check if requested quantity is available
        if (quantity > fixedPriceListing.quantityAvailable) {
          throw Exception('Not enough inventory available');
        }

        // Add new item
        await _supabase.from('cart_items').insert({
          'user_id': user.id,
          'item_id': itemId,
          'item_type': 'fixed_price',
          'quantity': quantity,
          'price': fixedPriceListing.price,
          'title': fixedPriceListing.title,
          'image_url': fixedPriceListing.imageUrls.isNotEmpty ? fixedPriceListing.imageUrls[0] : null,
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

  /// Add auction item to cart (for won auctions)
  Future<bool> addAuctionToCart(String auctionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get auction details
      final auctionData = await _supabase
          .from('auctions')
          .select()
          .eq('id', auctionId)
          .single();

      final auction = Auction.fromMap(auctionData);

      // Verify user has won this auction
      if (auction.highestBidderId != user.id) {
        throw Exception('You are not the winner of this auction');
      }

      // Check if auction is already in cart
      final existingItem = await _supabase
          .from('cart_items')
          .select()
          .eq('user_id', user.id)
          .eq('item_id', auctionId)
          .eq('item_type', 'auction')
          .maybeSingle();

      if (existingItem != null) {
        // Already in cart, nothing to do
        return true;
      }

      // Add auction to cart
      await _supabase.from('cart_items').insert({
        'user_id': user.id,
        'item_id': auctionId,
        'item_type': 'auction',
        'quantity': 1, // Auctions always have quantity 1
        'price': auction.highestBid,
        'title': auction.title,
        'image_url': auction.imageUrls.isNotEmpty ? auction.imageUrls[0] : null,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      log('✅ Added won auction to cart: $auctionId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error adding auction to cart: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get all items in user's cart
  Future<List<CartItem>> getCartItems() async {
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
      
      return response.map((item) => CartItem.fromMap(item)).toList();
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

      // Get the cart item
      final cartItem = await _supabase
          .from('cart_items')
          .select('item_id, item_type')
          .eq('id', cartItemId)
          .single();

      // If it's a fixed price item, check inventory
      if (cartItem['item_type'] == 'fixed_price') {
        final listing = await _supabase
            .from('fixed_price_listings')
            .select('quantity_available')
            .eq('id', cartItem['item_id'])
            .single();

        if (quantity > (listing['quantity_available'] as int)) {
          throw Exception('Not enough inventory available');
        }
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

  /// Get auction details
  Future<Auction?> getAuction(String auctionId) async {
    try {
      final response = await _supabase
          .from('auctions')
          .select()
          .eq('id', auctionId)
          .maybeSingle();
      
      if (response == null) {
        return null;
      }
      
      return Auction.fromMap(response);
    } catch (e, stackTrace) {
      log('❌ Error getting auction: $e', error: e, stackTrace: stackTrace);
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

  /// Calculate cart totals
  Future<Map<String, double>> calculateCartTotals() async {
    try {
      final cartItems = await getCartItems();
      
      double subtotal = 0.0;
      for (final item in cartItems) {
        subtotal += item.price * item.quantity;
      }
      
      // Calculate tax and shipping
      final shippingFee = subtotal > 100 ? 0.0 : 10.0; // Free shipping over $100
      final tax = subtotal * 0.05; // 5% tax
      final total = subtotal + shippingFee + tax;
      
      return {
        'subtotal': subtotal,
        'shipping': shippingFee,
        'tax': tax,
        'total': total,
      };
    } catch (e, stackTrace) {
      log('❌ Error calculating cart totals: $e', error: e, stackTrace: stackTrace);
      return {
        'subtotal': 0.0,
        'shipping': 0.0,
        'tax': 0.0,
        'total': 0.0,
      };
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