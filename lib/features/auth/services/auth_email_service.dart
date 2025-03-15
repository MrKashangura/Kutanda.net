// lib/features/auth/services/auth_email_service.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/services/session_service.dart';

class AuthEmailService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmail(String email, String password) async {
  try {
    // Log the actual auth response
    print('Attempting login for: $email');
    
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    final user = response.user;
    print('Auth response: ${user?.id}');
    
    if (user == null) {
      return {'success': false, 'message': 'Invalid login credentials'};
    }
    
    // Get role from users table with detailed error handling
    try {
      final userData = await _supabase
          .from('users')
          .select('role')
          .eq('uid', user.id) // Verify this column name!
          .single();
      
      print('User data: $userData');
      return {'success': true, 'role': userData['role']};
    } catch (e) {
      print('Role lookup error: $e');
      return {'success': false, 'message': 'Failed to retrieve user role'};
    }
  } catch (e) {
    print('Auth error: $e');
    return {'success': false, 'message': e.toString()};
  }
}

  /// Sign up with email and password
  Future<Map<String, dynamic>> signUpWithEmail(
    String email, 
    String password, 
    String displayName
  ) async {
    try {
      // Attempt to sign up with email and password
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      final User? user = response.user;
      
      if (user == null) {
        return {
          'success': false,
          'message': 'Failed to create account',
        };
      }
      
      // Create a user record in the users table
      await _supabase.from('users').insert({
        'id': user.id,
        'email': user.email,
        'display_name': displayName,
        'role': 'buyer', // Default role
        'auth_provider': 'email',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Create a buyer profile
      await _supabase.from('buyers').insert({
        'user_id': user.id,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Save the session
      await SessionService.saveUserSession(user.id, 'buyer');
      
      return {
        'success': true,
        'user': user,
        'role': 'buyer',
      };
    } catch (e) {
      log('❌ Email sign up error: $e');
      return {
        'success': false,
        'message': 'Error creating account: $e',
      };
    }
  }

  /// Send password reset email
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      
      return {
        'success': true,
        'message': 'Password reset email sent',
      };
    } catch (e) {
      log('❌ Password reset error: $e');
      return {
        'success': false,
        'message': 'Error sending password reset email: $e',
      };
    }
  }

  /// Update password
  Future<Map<String, dynamic>> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
      
      return {
        'success': true,
        'message': 'Password updated successfully',
      };
    } catch (e) {
      log('❌ Password update error: $e');
      return {
        'success': false,
        'message': 'Error updating password: $e',
      };
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await SessionService.clearSession();
      log('✅ User signed out successfully');
    } catch (e) {
      log('❌ Sign out error: $e');
    }
  }
}