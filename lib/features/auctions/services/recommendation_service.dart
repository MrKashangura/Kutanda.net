// lib/features/auctions/services/recommendation_service.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/auction_model.dart';
import '../../../data/models/fixed_price_listing_model.dart';

class RecommendationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get personalized auction recommendations based on user's bidding history and watchlist
  Future<List<Auction>> getRecommendedAuctions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      // Step 1: Get user's bid history to identify interests
      final userBids = await _supabase
          .from('bids')
          .select('auction_id')
          .eq('bidder_id', user.id)
          .order('created_at', ascending: false)
          .limit(20);
      
      // Step 2: Get user's watchlisted auctions
      final watchlistedAuctions = await _supabase
          .from('watchlist')
          .select('item_id')
          .eq('user_id', user.id)
          .eq('item_type', 'auction')
          .order('created_at', ascending: false)
          .limit(20);
      
      // Step 3: Extract auction IDs from bids and watchlist
      final bidAuctionIds = userBids.map((bid) => bid['auction_id'] as String).toList();
      final watchlistAuctionIds = watchlistedAuctions
          .map((item) => item['item_id'] as String)
          .toList();
      
      // Step 4: Get details of these auctions to identify categories/interests
      final auctionsOfInterest = await _supabase
          .from('auctions')
          .select('title, description')
          .inFilter('id', [...bidAuctionIds, ...watchlistAuctionIds])
          .limit(30);
      
      // Step 5: Extract keywords from titles and descriptions
      final List<String> keywordsOfInterest = [];
      for (final auction in auctionsOfInterest) {
        final title = (auction['title'] as String).toLowerCase();
        final description = (auction['description'] as String).toLowerCase();
        
        // Add significant words from title and description
        keywordsOfInterest.addAll(_extractKeywords(title));
        keywordsOfInterest.addAll(_extractKeywords(description));
      }
      
      // Count keyword frequencies
      final Map<String, int> keywordCounts = {};
      for (final keyword in keywordsOfInterest) {
        keywordCounts[keyword] = (keywordCounts[keyword] ?? 0) + 1;
      }
      
      // Sort keywords by frequency
      final sortedKeywords = keywordCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Step 6: Get top keywords (limit to top 10)
      final topKeywords = sortedKeywords
          .take(10)
          .map((e) => e.key)
          .toList();
      
      if (topKeywords.isEmpty) {
        // If no preferences found, return popular/trending auctions
        final popularAuctions = await _supabase
            .from('auctions')
            .select()
            .eq('is_active', true)
            .gt('end_time', DateTime.now().toIso8601String())
            .order('highest_bid', ascending: false)
            .limit(10);
        
        return popularAuctions.map((data) => Auction.fromMap(data)).toList();
      }
      
      // Step 7: Get active auctions matching user interests
      final recommendedAuctions = await _supabase
          .from('auctions')
          .select()
          .eq('is_active', true)
          .gt('end_time', DateTime.now().toIso8601String())
          .not('id', 'in', [...bidAuctionIds, ...watchlistAuctionIds]) // Exclude already bid/watchlisted
          .or(_generateKeywordFilters(topKeywords))
          .order('created_at', ascending: false)
          .limit(10);
      
      // Step 8: If not enough recommendations, fill with trending auctions
      if (recommendedAuctions.length < 5) {
        final additionalAuctions = await _supabase
            .from('auctions')
            .select()
            .eq('is_active', true)
            .gt('end_time', DateTime.now().toIso8601String())
            .not('id', 'in', [
              ...bidAuctionIds, 
              ...watchlistAuctionIds,
              ...recommendedAuctions.map((a) => a['id'])
            ])
            .order('highest_bid', ascending: false)
            .limit(10 - recommendedAuctions.length);
        
        recommendedAuctions.addAll(additionalAuctions);
      }
      
      return recommendedAuctions.map((data) => Auction.fromMap(data)).toList();
    } catch (e, stackTrace) {
      log('❌ Error getting recommended auctions: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get recommended fixed price listings based on user's purchases and saves
  Future<List<FixedPriceListing>> getRecommendedFixedPriceListings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      // Step 1: Get user's purchase history
      final purchaseHistory = await _supabase
          .from('order_items')
          .select('item_id, orders!inner(user_id)')
          .eq('orders.user_id', user.id)
          .limit(20);
      
      // Step 2: Get user's saved fixed price listings
      final savedListings = await _supabase
          .from('watchlist')
          .select('item_id')
          .eq('user_id', user.id)
          .eq('item_type', 'fixedPrice')
          .limit(20);
      
      // Step 3: Extract item IDs
      final purchasedItemIds = purchaseHistory
          .map((item) => item['item_id'] as String)
          .toList();
      
      final savedItemIds = savedListings
          .map((item) => item['item_id'] as String)
          .toList();
      
      // Step 4: Get details of these items
      final itemsOfInterest = await _supabase
          .from('fixed_price_listings')
          .select('title, description')
          .inFilter('id', [...purchasedItemIds, ...savedItemIds])
          .limit(30);
      
      // Step 5: Extract keywords from titles and descriptions
      final List<String> keywordsOfInterest = [];
      for (final item in itemsOfInterest) {
        final title = (item['title'] as String).toLowerCase();
        final description = (item['description'] as String).toLowerCase();
        
        keywordsOfInterest.addAll(_extractKeywords(title));
        keywordsOfInterest.addAll(_extractKeywords(description));
      }
      
      // Count keyword frequencies
      final Map<String, int> keywordCounts = {};
      for (final keyword in keywordsOfInterest) {
        keywordCounts[keyword] = (keywordCounts[keyword] ?? 0) + 1;
      }
      
      // Sort keywords by frequency
      final sortedKeywords = keywordCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Step 6: Get top keywords
      final topKeywords = sortedKeywords
          .take(10)
          .map((e) => e.key)
          .toList();
      
      if (topKeywords.isEmpty) {
        // If no preferences found, return featured listings
        final featuredListings = await _supabase
            .from('fixed_price_listings')
            .select()
            .eq('is_active', true)
            .eq('is_featured', true)
            .gt('quantity_available', 0)
            .order('created_at', ascending: false)
            .limit(10);
        
        return featuredListings.map((data) => 
          FixedPriceListing.fromMap(_normalizeColumns(data))
        ).toList();
      }
      
      // Step 7: Get active listings matching user interests
      final recommendedListings = await _supabase
          .from('fixed_price_listings')
          .select()
          .eq('is_active', true)
          .gt('quantity_available', 0)
          .not('id', 'in', [...purchasedItemIds, ...savedItemIds])
          .or(_generateKeywordFilters(topKeywords))
          .order('created_at', ascending: false)
          .limit(10);
      
      // Step 8: If not enough recommendations, fill with featured listings
      if (recommendedListings.length < 5) {
        final additionalListings = await _supabase
            .from('fixed_price_listings')
            .select()
            .eq('is_active', true)
            .gt('quantity_available', 0)
            .eq('is_featured', true)
            .not('id', 'in', [
              ...purchasedItemIds,
              ...savedItemIds,
              ...recommendedListings.map((a) => a['id'])
            ])
            .limit(10 - recommendedListings.length);
        
        recommendedListings.addAll(additionalListings);
      }
      
      return recommendedListings.map((data) => 
        FixedPriceListing.fromMap(_normalizeColumns(data))
      ).toList();
    } catch (e, stackTrace) {
      log('❌ Error getting recommended fixed price listings: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get similar auctions to a specific auction
  Future<List<Auction>> getSimilarAuctions(String auctionId) async {
    try {
      // Step 1: Get auction details
      final auction = await _supabase
          .from('auctions')
          .select()
          .eq('id', auctionId)
          .single();
      
      // Step 2: Extract keywords from title and description
      final title = (auction['title'] as String).toLowerCase();
      final description = (auction['description'] as String).toLowerCase();
      
      final keywords = [
        ..._extractKeywords(title),
        ..._extractKeywords(description),
      ];
      
      if (keywords.isEmpty) {
        return [];
      }
      
      // Step 3: Get similar active auctions
      final similarAuctions = await _supabase
          .from('auctions')
          .select()
          .eq('is_active', true)
          .gt('end_time', DateTime.now().toIso8601String())
          .neq('id', auctionId)
          .or(_generateKeywordFilters(keywords.take(5).toList()))
          .order('created_at', ascending: false)
          .limit(5);
      
      return similarAuctions.map((data) => Auction.fromMap(data)).toList();
    } catch (e, stackTrace) {
      log('❌ Error getting similar auctions: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Extract meaningful keywords from text
  List<String> _extractKeywords(String text) {
    // Split text into words
    final words = text.split(RegExp(r'\s+'));
    
    // Filter out common words and short words
    final stopWords = [
      'a', 'an', 'the', 'and', 'or', 'but', 'is', 'in', 'on', 'at', 'to', 'for', 
      'with', 'by', 'about', 'as', 'into', 'like', 'of', 'from', 'that', 'this', 
      'these', 'those', 'it', 'its', 'they', 'them', 'their', 'has', 'have', 'had',
      'will', 'would', 'should', 'could', 'may', 'might', 'can', 'do', 'does', 'did',
    ];
    
    return words
        .where((word) => word.length > 3 && !stopWords.contains(word))
        .toList();
  }

  /// Generate SQL filter string for keyword search
  String _generateKeywordFilters(List<String> keywords) {
    final filters = keywords.map((keyword) {
      return "title.ilike.%$keyword% , description.ilike.%$keyword%";
    }).join(',');
    
    return filters;
  }

  /// Normalize database column names to match model field names
  Map<String, dynamic> _normalizeColumns(Map<String, dynamic> dbData) {
    final normalizedData = <String, dynamic>{};
    
    // Convert uid/id field
    normalizedData['id'] = dbData['id'] ?? dbData['uid'];
    
    // Convert seller_uid/seller_id field
    normalizedData['sellerId'] = dbData['seller_id'] ?? dbData['seller_uid'];
    
    // Copy other fields
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
  }