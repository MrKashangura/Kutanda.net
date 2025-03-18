// lib/features/auth/services/auth_google_service.dart
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/services/session_service.dart';

/// Service for handling Google authentication with Supabase
class AuthGoogleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign in with Google using Supabase OAuth
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Start the Google sign-in process via Supabase OAuth
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.kutanda://login-callback/',
      );

      if (!response) {
        // User may have cancelled the flow or authentication failed
        log('Google sign-in was cancelled or failed');
        return {
          'success': false,
          'message': 'Google sign-in was cancelled or failed',
        };
      }

      // At this point, the user has been redirected and should now be logged in
      // We need to wait for the session to be established
      await Future.delayed(const Duration(seconds: 1));
      
      // Check if we have a valid session and user
      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;
      
      if (session == null || user == null) {
        return {
          'success': false,
          'message': 'Failed to establish session after Google authentication',
        };
      }

      // Check if this is a new user
      final isNewUser = await _isNewUser(user.id);
      
      // If this is a new user, create necessary records in our database
      if (isNewUser) {
        await _createUserRecord(user);
      }
      
      // Get user role
      final userRole = await _getUserRole(user.id);
      
      // Save session locally
      await SessionService.saveUserSession(user.id, userRole ?? 'buyer');

      log('✅ Google Auth Successful through Supabase OAuth');
      return {
        'success': true,
        'user': user,
        'isNewUser': isNewUser,
        'role': userRole,
      };
    } catch (e) {
      log('❌ Google Auth Error: $e');
      return {
        'success': false,
        'message': 'Error signing in with Google: $e',
      };
    }
  }

  /// Check if this is a new user (no record in users table)
  Future<bool> _isNewUser(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      return response == null;
    } catch (e) {
      log('❌ Error checking if user exists: $e');
      return true; // Assume new user if error
    }
  }
  
  /// Create a new user record with default role
  Future<void> _createUserRecord(User user) async {
    try {
      await _supabase.from('users').insert({
        'id': user.id,
        'email': user.email,
        'display_name': user.userMetadata?['full_name'] ?? user.email?.split('@').first,
        'role': 'buyer', // Default role
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Also create buyer profile
      await _supabase.from('buyers').insert({
        'user_id': user.id,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      log('✅ New user record created for: ${user.email}');
    } catch (e) {
      log('❌ Error creating user record: $e');
      // Continue anyway - user is authenticated
    }
  }
  
  /// Get user role from database
  Future<String?> _getUserRole(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      
      return response?['role'] as String?;
    } catch (e) {
      log('❌ Error getting user role: $e');
      return 'buyer'; // Default to buyer role if error
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await SessionService.clearSession();
      log('✅ Signed out successfully');
    } catch (e) {
      log('❌ Error signing out: $e');
      rethrow;
    }
  }
}