import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleService {
  final _storage = const FlutterSecureStorage();
  final SupabaseClient supabase = Supabase.instance.client;

  /// Get the user's active role (which profile they're currently using)
  Future<String> getActiveRole() async {
    try {
      // First check if we have a stored active role
      String? activeRole = await _storage.read(key: 'activeRole');
      
      // Default to buyer if no stored role
      return activeRole ?? 'buyer';
    } catch (e) {
      log("❌ Error getting active role: $e");
      return 'buyer'; // Default to buyer on error
    }
  }

  /// Get the user's buyer profile
  Future<Map<String, dynamic>?> getBuyerProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        log("❌ No authenticated user found");
        return null;
      }
      
      final response = await supabase
          .from('buyers')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();
      
      return response;
    } catch (e) {
      log("❌ Error getting buyer profile: $e");
      return null;
    }
  }

  /// Get the user's seller profile including KYC status
  Future<Map<String, dynamic>?> getSellerProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        log("❌ No authenticated user found");
        return null;
      }
      
      final response = await supabase
          .from('sellers')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();
      
      return response;
    } catch (e) {
      log("❌ Error getting seller profile: $e");
      return null;
    }
  }

  /// Switch between buyer and seller profiles
  Future<bool> switchRole(String targetRole) async {
    try {
      // Validate the target role
      if (targetRole != 'buyer' && targetRole != 'seller') {
        log("❌ Invalid role: $targetRole. Can only switch to 'buyer' or 'seller'");
        return false;
      }
      
      log("⏳ Attempting to switch to $targetRole role");
      
      final user = supabase.auth.currentUser;
      if (user == null) {
        log("❌ No authenticated user found");
        return false;
      }
      
      // If switching to seller, check if it's verified and active
      if (targetRole == 'seller') {
        final sellerProfile = await getSellerProfile();
        if (sellerProfile == null) {
          log("❌ No seller profile found");
          return false;
        }
        
        bool isActive = sellerProfile['is_active'] ?? false;
        String kycStatus = sellerProfile['kyc_status'] ?? 'not_submitted';
        
        if (!isActive || kycStatus != 'verified') {
          log("❌ Seller profile is not verified or not active");
          return false;
        }
      }
      
      // Store the new active role
      await _storage.write(key: 'activeRole', value: targetRole);
      log("✅ Successfully switched to $targetRole role");
      return true;
    } catch (e) {
      log("❌ Error switching role: $e");
      return false;
    }
  }

  /// Submit or update KYC information for seller verification
  Future<bool> submitSellerKYC(Map<String, dynamic> sellerData, List<String> documentUrls) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        log("❌ No authenticated user found");
        return false;
      }
      
      // Get the seller profile ID
      final sellerProfile = await getSellerProfile();
      if (sellerProfile == null) {
        log("❌ No seller profile found");
        return false;
      }
      
      // Update the seller profile with KYC data
      await supabase.from('sellers').update({
        'business_name': sellerData['business_name'],
        'business_id': sellerData['business_id'],
        'address': sellerData['address'],
        'tax_id': sellerData['tax_id'],
        'document_urls': documentUrls,
        'kyc_status': 'pending', // Set to pending for admin review
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', sellerProfile['id']);
      
      log("✅ Seller KYC information submitted successfully");
      return true;
    } catch (e) {
      log("❌ Error submitting seller KYC: $e");
      return false;
    }
  }
  
  /// Create both buyer and seller profiles for an existing user
  /// Only use this if the automatic trigger didn't work
  Future<bool> createUserProfiles() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        log("❌ No authenticated user found");
        return false;
      }
      
      // Check if profiles already exist
      final buyerProfile = await getBuyerProfile();
      final sellerProfile = await getSellerProfile();
      
      // Create buyer profile if it doesn't exist
      if (buyerProfile == null) {
        await supabase.from('buyers').insert({
          'id': supabase.auth.currentUser!.id,
          'user_id': user.id,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String()
        });
      }
      
      // Create seller profile if it doesn't exist
      if (sellerProfile == null) {
        await supabase.from('sellers').insert({
          'id': supabase.auth.currentUser!.id,
          'user_id': user.id,
          'kyc_status': 'not_submitted',
          'is_active': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String()
        });
      }
      
      log("✅ User profiles created successfully");
      return true;
    } catch (e) {
      log("❌ Error creating user profiles: $e");
      return false;
    }
  }
}