// lib/services/role_service.dart
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleService {
  final _storage = const FlutterSecureStorage();
  final SupabaseClient supabase = Supabase.instance.client;

  /// Get the user's active role
  Future<String?> getActiveRole() async {
    try {
      // Get stored active role
      final activeRole = await _storage.read(key: 'activeRole');
      
      // If no active role is stored, use the default role based on user type
      if (activeRole == null) {
        final user = supabase.auth.currentUser;
        if (user != null) {
          final userResponse = await supabase
              .from('users')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();
              
          if (userResponse != null) {
            final defaultRole = userResponse['role'];
            await _storage.write(key: 'activeRole', value: defaultRole);
            return defaultRole;
          }
        }
        
        // Default to 'buyer' if no role found
        return 'buyer';
      }
      
      return activeRole;
    } catch (e) {
      log('❌ Error getting active role: $e');
      return 'buyer'; // Default fallback
    }
  }

  /// Check the status of a user's KYC verification
  Future<Map<String, dynamic>> checkKycStatus() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        log("❌ No authenticated user found");
        return {'status': 'unknown', 'is_active': false};
      }
      
      final response = await supabase
          .from('sellers')
          .select('kyc_status, is_active')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (response == null) {
        log("⚠️ No seller profile found for user");
        return {'status': 'unknown', 'is_active': false};
      }
      
      return {
        'status': response['kyc_status'] ?? 'unknown',
        'is_active': response['is_active'] ?? false
      };
    } catch (e) {
      log("❌ Error checking KYC status: $e");
      return {'status': 'error', 'is_active': false};
    }
  }

  /// Request verification to become a seller
  Future<bool> requestSellerRole(Map<String, dynamic> sellerData, List<String> documentUrls) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        log("❌ No authenticated user found");
        return false;
      }
      
      // First get the seller record ID
      final sellerRecord = await supabase
          .from('sellers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (sellerRecord == null) {
        log("❌ No seller profile found for user");
        return false;
      }
      
      // Update the seller's information with the KYC data
      await supabase.from('sellers').update({
        'business_name': sellerData['business_name'],
        'business_id': sellerData['business_registration_number'],
        'tax_id': sellerData['tax_id'],
        'address': sellerData['address'],
        'document_urls': documentUrls,
        'kyc_status': 'pending',
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', sellerRecord['id']);
      
      log("✅ Seller verification request submitted successfully");
      return true;
    } catch (e) {
      log("❌ Error requesting seller verification: $e");
      return false;
    }
  }

  /// Switch the user's active role between buyer and seller
  Future<bool> switchRole(String newRole) async {
    try {
      if (newRole != 'buyer' && newRole != 'seller') {
        log("❌ Invalid role: $newRole");
        return false;
      }
      
      final user = supabase.auth.currentUser;
      if (user == null) {
        log("❌ No authenticated user found");
        return false;
      }
      
      // If switching to seller, verify KYC status
      if (newRole == 'seller') {
        final kycStatus = await checkKycStatus();
        if (kycStatus['status'] != 'verified' || !kycStatus['is_active']) {
          log("❌ Seller verification required or not active");
          return false;
        }
      }
      
      // Save the active role
      await _storage.write(key: 'activeRole', value: newRole);
      
      log("✅ Switched to $newRole role");
      return true;
    } catch (e) {
      log("❌ Error switching role: $e");
      return false;
    }
  }

  /// Get the user's available roles and their status
  Future<Map<String, dynamic>> getUserRoles() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        log("❌ No authenticated user found");
        return {'buyer': true, 'seller': false};
      }
      
      // Get buyer status - should always be active
      final buyerProfile = await supabase
          .from('buyers')
          .select('is_active')
          .eq('user_id', user.id)
          .maybeSingle();
      
      bool buyerActive = buyerProfile?['is_active'] ?? true;
      
      // Get seller status - requires KYC verification
      final sellerProfile = await supabase
          .from('sellers')
          .select('is_active, kyc_status')
          .eq('user_id', user.id)
          .maybeSingle();
      
      bool sellerActive = false;
      String sellerStatus = 'not_submitted';
      
      if (sellerProfile != null) {
        sellerActive = sellerProfile['is_active'] ?? false;
        sellerStatus = sellerProfile['kyc_status'] ?? 'not_submitted';
      }
      
      return {
        'buyer': buyerActive,
        'seller': sellerActive,
        'seller_status': sellerStatus
      };
    } catch (e) {
      log("❌ Error getting user roles: $e");
      return {'buyer': true, 'seller': false, 'seller_status': 'error'};
    }
  }
}