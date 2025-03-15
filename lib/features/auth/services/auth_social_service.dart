// lib/features/auth/services/auth_social_service.dart
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/services/session_service.dart';

class AuthSocialService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Initialize Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      
      // Start the interactive sign-in process
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in flow
        return {'success': false, 'message': 'Sign in canceled by user'};
      }
      
      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Use the idToken to authenticate with Supabase
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      
      final session = response.session;
      final user = response.user;
      
      if (session == null || user == null) {
        return {'success': false, 'message': 'Failed to sign in with Google'};
      }
      
      // Check if this is a new user (no record in users table yet)
      final isNewUser = await _isNewUser(user.id);
      
      if (isNewUser) {
        // Create a new user record with default role
        await _createUserRecord(
          id: user.id,
          email: user.email ?? googleUser.email,
          displayName: user.userMetadata?['full_name'] ?? googleUser.displayName ?? '',
        );
      }
      
      // Get user role
      final userRole = await _getUserRole(user.id);
      
      // Save session locally
      await SessionService.saveUserSession(user.id, userRole ?? 'buyer');
      
      return {
        'success': true,
        'isNewUser': isNewUser,
        'user': user,
        'role': userRole,
      };
    } catch (e) {
      log('❌ Google sign in error: $e');
      return {'success': false, 'message': 'Error signing in with Google: $e'};
    }
  }
  
  /// Sign in with Facebook
  Future<Map<String, dynamic>> signInWithFacebook() async {
    try {
      // Start the sign-in process
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      
      if (result.status != LoginStatus.success) {
        return {'success': false, 'message': 'Facebook sign in was not successful'};
      }
      
      // Get access token
      final AccessToken? accessToken = result.accessToken;
      
      if (accessToken == null) {
        return {'success': false, 'message': 'Failed to get Facebook access token'};
      }
      
      // Sign in to Supabase with Facebook token
      final bool success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb ? null : 'io.supabase.kutanda://login-callback/',
      );
      
      // For Facebook, we need to check the response differently as the sign in
      // might involve a redirect flow, especially on web
      if (success && !(_supabase.auth.currentSession?.isExpired ?? true)) {
        final user = _supabase.auth.currentUser;
      
        if (user == null) {
          return {'success': false, 'message': 'Failed to get user after Facebook sign in'};
        }
      
        // Check if this is a new user
        final isNewUser = await _isNewUser(user.id);
      
        if (isNewUser) {
          // Get user info from Facebook
          final userData = await FacebookAuth.instance.getUserData();
          
          // Create a new user record
          await _createUserRecord(
            id: user.id,
            email: user.email ?? userData['email'] ?? '',
            displayName: user.userMetadata?['full_name'] ?? userData['name'] ?? '',
          );
        }
      
        // Get user role
        final userRole = await _getUserRole(user.id);
      
        // Save session locally
        await SessionService.saveUserSession(user.id, userRole ?? 'buyer');
      
        return {
          'success': true,
          'isNewUser': isNewUser,
          'user': user,
          'role': userRole,
        };
      } else {
        return {'success': false, 'message': 'Facebook authentication failed'};
      }
    } catch (e) {
      log('❌ Facebook sign in error: $e');
      return {'success': false, 'message': 'Error signing in with Facebook: $e'};
    }
  }
  
  /// Check if this is a new user (no record in users table)
  Future<bool> _isNewUser(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('uid')
          .eq('id', userId)
          .maybeSingle();
      
      return response == null;
    } catch (e) {
      log('❌ Error checking if user exists: $e');
      return true; // Assume new user if error
    }
  }
  
  /// Create a new user record with default role
  Future<void> _createUserRecord({
    required String id, 
    required String email,
    String? displayName,
  }) async {
    try {
      await _supabase.from('users').insert({
        'id': id,
        'email': email,
        'display_name': displayName ?? email.split('@').first,
        'role': 'buyer', // Default role
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Also create buyer profile
      await _supabase.from('buyers').insert({
        'user_id': id,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      log('✅ New user record created for: $email');
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
      return null;
    }
  }
}