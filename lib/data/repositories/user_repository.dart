// lib/data/repositories/user_repository.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';

class UserRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user profile by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('uid', userId)
          .maybeSingle();
      
      if (response == null) return null;
      
      return UserModel.fromJson(response);
    } catch (e, stackTrace) {
      log('❌ Error fetching user: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get user role
  Future<String?> getUserRole(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('role')
          .eq('uid', userId)
          .maybeSingle();

      if (response != null) {
        return response['role'] as String?;
      }
      return null;
    } catch (e, stackTrace) {
      log('❌ Error fetching user role: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Create a new user
  Future<bool> createUser(UserModel user) async {
    try {
      await _supabase.from('users').insert({
        'uid': user.uid,
        'email': user.email,
        'phone': user.phone,
        'role': user.activeRole,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      log('✅ User created: ${user.uid}');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error creating user: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateUser(UserModel user) async {
    try {
      await _supabase
          .from('users')
          .update({
            'email': user.email,
            'phone': user.phone,
            'role': user.activeRole,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('uid', user.uid);
      
      log('✅ User updated: ${user.uid}');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error updating user: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      await _supabase
          .from('users')
          .delete()
          .eq('uid', userId);
      
      log('✅ User deleted: $userId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error deleting user: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get all users (admin/CSR function)
  Future<List<UserModel>> getAllUsers({
    String? searchQuery, 
    String? roleFilter
  }) async {
    try {
      var query = _supabase.from('users').select();
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('email.ilike.%$searchQuery%,phone.ilike.%$searchQuery%');
      }
      
      if (roleFilter != null && roleFilter.isNotEmpty) {
        query = query.eq('role', roleFilter);
      }
      
      final response = await query;
      
      return response.map((json) => UserModel.fromJson(json)).toList();
    } catch (e, stackTrace) {
      log('❌ Error fetching users: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final response = await _supabase
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();
      
      return response != null;
    } catch (e, stackTrace) {
      log('❌ Error checking email: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Check if phone exists
  Future<bool> phoneExists(String phone) async {
    try {
      final response = await _supabase
          .from('users')
          .select('phone')
          .eq('phone', phone)
          .maybeSingle();
      
      return response != null;
    } catch (e, stackTrace) {
      log('❌ Error checking phone: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}