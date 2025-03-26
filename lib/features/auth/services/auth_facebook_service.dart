// lib/features/auth/services/auth_facebook_service.dart
import 'dart:developer';

import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/services/session_service.dart';

class AuthFacebookService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign in with Facebook
  Future<Map<String, dynamic>> signInWithFacebook() async {
    try {
      // Begin Facebook sign in process
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      
      // Check if login was successful
      if (result.status != LoginStatus.success) {
        return {
          'success': false,
          'message': 'Facebook sign in failed: ${result.message}',
        };
      }
      
      // Get access token
      final String? accessToken = result.accessToken?.token;
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'Failed to get Facebook access token',
        };
      }
      
      // Get user data from Facebook
      final userData = await FacebookAuth.instance.getUserData();
      
      // Sign in with Supabase using the Facebook access token
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.facebook,
        idToken: accessToken, // For Facebook, we use the access token here
      );
      
      final User? user = response.user;
      
      if (user == null) {
        return {
          'success': false,
          'message': 'Failed to sign in with Facebook',
        };
      }
      
      // Check if this is a new user
      final isNewUser = DateTime.now().difference(DateTime.parse(user.createdAt)).inSeconds.abs() < 5;
      
      if (isNewUser) {
        // Create a new user profile in the users table
        await _supabase.from('users').insert({
          'id': user.id,
          'email': user.email,
          'display_name': userData['name'] ?? user.email?.split('@')[0],
          'role': 'buyer', // Default role
          'auth_provider': 'facebook',
          'created_at': DateTime.now().toIso8601String(),
        });
        
        // Also create a buyer profile
        await _supabase.from('buyers').insert({
          'user_id': user.id,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      // Save the session
      await SessionService.saveUserSession(user.id, 'buyer');
      
      return {
        'success': true,
        'user': user,
        'isNewUser': isNewUser,
      };
    } catch (e) {
      log('❌ Facebook sign in error: $e');
      return {
        'success': false,
        'message': 'Error signing in with Facebook: $e',
      };
    }
  }

  /// Sign out from Facebook
  Future<void> signOut() async {
    try {
      await FacebookAuth.instance.logOut();
    } catch (e) {
      log('❌ Facebook sign out error: $e');
    }
  }
}