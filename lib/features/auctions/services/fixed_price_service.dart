// lib/features/auctions/services/fixed_price_service.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/fixed_price_listing_model.dart';

class FixedPriceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all active fixed price listings
  Future<List<FixedPriceListing>> getActiveListings() async {
    try {
      final response = await _supabase
          .from('fixed_price_listings')
          .select()
          .eq('is_active', true)
          .gt('quantity_available', 0)
          .order('created_at', ascending: false);
      
      return response.map<FixedPriceListing>((data) => 
        FixedPriceListing.fromMap(_normalizeColumns(data))
      ).toList();
    } catch (e, stackTrace) {
      log('❌ Error getting active fixed price listings: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get featured fixed price listings
  Future<List<FixedPriceListing>> getFeaturedListings() async {
    try {
      final response = await _supabase
          .from('fixed_price_listings')
          .select()
          .eq('is_active', true)
          .eq('is_featured', true)
          .gt('quantity_available', 0)
          .order('created_at', ascending: false);
      
      return response.map<FixedPriceListing>((data) => 
        FixedPriceListing.fromMap(_normalizeColumns(data))
      ).toList();
    } catch (e, stackTrace) {
      log('❌ Error getting featured fixed price listings: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get fixed price listing by ID
  Future<FixedPriceListing?> getListingById(String id) async {
    try {
      final response = await _supabase
          .from('fixed_price_listings')
          .select()
          .eq('uid', id) // Using 'uid' as primary key in database
          .maybeSingle();
      
      if (response == null) return null;
      
      return FixedPriceListing.fromMap(_normalizeColumns(response));
    } catch (e, stackTrace) {
      log('❌ Error getting fixed price listing: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get listings by seller ID
  Future<List<FixedPriceListing>> getListingsBySeller(String sellerId) async {
    try {
      final response = await _supabase
          .from('fixed_price_listings')
          .select()
          .eq('seller_uid', sellerId) // Using 'seller_uid' in database
          .order('created_at', ascending: false);
      
      return response.map<FixedPriceListing>((data) => 
        FixedPriceListing.fromMap(_normalizeColumns(data))
      ).toList();
    } catch (e, stackTrace) {
      log('❌ Error getting seller fixed price listings: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Create a new fixed price listing
  Future<String?> createListing(FixedPriceListing listing) async {
    try {
      // Convert model to map, normalizing column names for database
      final listingMap = _denormalizeColumns(listing.toMap());
      
      // Insert into database
      final response = await _supabase
          .from('fixed_price_listings')
          .insert(listingMap)
          .select('uid')
          .single();
      
      final listingId = response['uid'] as String;
      log('✅ Fixed price listing created: $listingId');
      return listingId;
    } catch (e, stackTrace) {
      log('❌ Error creating fixed price listing: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Update a fixed price listing
  Future<bool> updateListing(FixedPriceListing listing) async {
    try {
      // Convert model to map, normalizing column names for database
      final listingMap = _denormalizeColumns(listing.toMap());
      
      // Update in database
      await _supabase
          .from('fixed_price_listings')
          .update(listingMap)
          .eq('uid', listing.id); // Using 'uid' as primary key in database
      
      log('✅ Fixed price listing updated: ${listing.id}');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error updating fixed price listing: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Delete a fixed price listing
  Future<bool> deleteListing(String id) async {
    try {
      await _supabase
          .from('fixed_price_listings')
          .delete()
          .eq('uid', id); // Using 'uid' as primary key in database
      
      log('✅ Fixed price listing deleted: $id');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error deleting fixed price listing: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Search fixed price listings
  Future<List<FixedPriceListing>> searchListings({
    String? query,
    double? minPrice,
    double? maxPrice,
    List<String>? categories,
  }) async {
    try {
      // Start with base query
      var queryBuilder = _supabase
          .from('fixed_price_listings')
          .select()
          .eq('is_active', true)
          .gt('quantity_available', 0);
      
      // Apply text search filter if provided
      if (query != null && query.isNotEmpty) {
        queryBuilder = queryBuilder.or('title.ilike.%$query%,description.ilike.%$query%');
      }
      
      // Apply price filters
      if (minPrice != null) {
        queryBuilder = queryBuilder.gte('price', minPrice);
      }
      if (maxPrice != null) {
        queryBuilder = queryBuilder.lte('price', maxPrice);
      }
      
      // Execute query
      final response = await queryBuilder.order('created_at', ascending: false);
      
      // Process and return results
      final listings = response.map<FixedPriceListing>((data) => 
        FixedPriceListing.fromMap(_normalizeColumns(data))
      ).toList();
      
      // Apply category filter in Dart (assuming categories might be in description)
      if (categories != null && categories.isNotEmpty) {
        return listings.where((listing) {
          for (final category in categories) {
            if (listing.description.toLowerCase().contains(category.toLowerCase())) {
              return true;
            }
          }
          return false;
        }).toList();
      }
      
      return listings;
    } catch (e, stackTrace) {
      log('❌ Error searching fixed price listings: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Toggle featured status for a listing
  Future<bool> toggleFeatured(String id, bool isFeatured, {DateTime? featuredUntil}) async {
    try {
      final updateData = {
        'is_featured': isFeatured,
        'featured_until': featuredUntil?.toIso8601String(),
      };
      
      await _supabase
          .from('fixed_price_listings')
          .update(updateData)
          .eq('uid', id); // Using 'uid' as primary key in database
      
      log('✅ Fixed price listing featured status updated: $id');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error updating featured status: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Update listing quantity
  Future<bool> updateQuantity(String id, int newQuantity) async {
    try {
      await _supabase
          .from('fixed_price_listings')
          .update({'quantity_available': newQuantity})
          .eq('uid', id); // Using 'uid' as primary key in database
      
      log('✅ Fixed price listing quantity updated: $id');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error updating quantity: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Normalize database column names to match model field names
  Map<String, dynamic> _normalizeColumns(Map<String, dynamic> dbData) {
    final normalizedData = <String, dynamic>{};
    
    // Convert uid to id
    normalizedData['id'] = dbData['uid'];
    
    // Convert seller_uid to sellerId
    normalizedData['sellerId'] = dbData['seller_uid'];
    
    // Copy other fields directly
    normalizedData['title'] = dbData['title'];
    normalizedData['description'] = dbData['description'];
    normalizedData['price'] = dbData['price'] is num 
        ? (dbData['price'] as num).toDouble() 
        : 0.0;
    normalizedData['quantityAvailable'] = dbData['quantity_available'] ?? 0;
    normalizedData['quantitySold'] = dbData['quantity_sold'] ?? 0;
    normalizedData['imageUrls'] = dbData['image_urls'] ?? [];
    normalizedData['isFeatured'] = dbData['is_featured'] ?? false;
    normalizedData['createdAt'] = dbData['created_at'] != null 
        ? DateTime.parse(dbData['created_at']) 
        : DateTime.now();
    normalizedData['featuredUntil'] = dbData['featured_until'] != null 
        ? DateTime.parse(dbData['featured_until']) 
        : null;
    normalizedData['isActive'] = dbData['is_active'] ?? true;
    
    return normalizedData;
  }

  /// Denormalize model field names to match database column names
  Map<String, dynamic> _denormalizeColumns(Map<String, dynamic> modelData) {
    final denormalizedData = <String, dynamic>{};
    
    // Convert id to uid if provided
    if (modelData.containsKey('id')) {
      denormalizedData['uid'] = modelData['id'];
    }
    
    // Convert sellerId to seller_uid
    if (modelData.containsKey('sellerId')) {
      denormalizedData['seller_uid'] = modelData['sellerId'];
    }
    
    // Copy other fields with appropriate transformations
    if (modelData.containsKey('title')) {
      denormalizedData['title'] = modelData['title'];
    }
    if (modelData.containsKey('description')) {
      denormalizedData['description'] = modelData['description'];
    }
    if (modelData.containsKey('price')) {
      denormalizedData['price'] = modelData['price'];
    }
    if (modelData.containsKey('quantityAvailable')) {
      denormalizedData['quantity_available'] = modelData['quantityAvailable'];
    }
    if (modelData.containsKey('quantitySold')) {
      denormalizedData['quantity_sold'] = modelData['quantitySold'];
    }
    if (modelData.containsKey('imageUrls')) {
      denormalizedData['image_urls'] = modelData['imageUrls'];
    }
    if (modelData.containsKey('isFeatured')) {
      denormalizedData['is_featured'] = modelData['isFeatured'];
    }
    if (modelData.containsKey('createdAt')) {
      denormalizedData['created_at'] = modelData['createdAt'] is DateTime
          ? modelData['createdAt'].toIso8601String()
          : modelData['createdAt'];
    }
    if (modelData.containsKey('featuredUntil')) {
      denormalizedData['featured_until'] = modelData['featuredUntil'] is DateTime
          ? modelData['featuredUntil'].toIso8601String()
          : modelData['featuredUntil'];
    }
    if (modelData.containsKey('isActive')) {
      denormalizedData['is_active'] = modelData['isActive'];
    }
    
    return denormalizedData;
  }
}