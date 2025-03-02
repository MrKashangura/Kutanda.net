// lib/services/auth_facebook.dart
import 'dart:developer';

import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling Facebook authentication with Supabase
class FacebookAuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Sign in with Facebook and authenticate with Supabase
  Future<AuthResponse?> signInWithFacebook() async {
    try {
      // Start the Facebook login process
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        log('Facebook login was canceled by the user');
        return null;
      }

      if (result.status == LoginStatus.failed) {
        throw Exception('Facebook login failed: ${result.message}');
      }

      // Get access token
      final String? accessToken = result.accessToken?.token;
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      // Get user data from Facebook
      final userData = await FacebookAuth.instance.getUserData();
      log('Facebook user data: $userData');

      // Sign in to Supabase with Facebook OAuth
      final AuthResponse response = await supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'io.supabase.kutanda://login-callback/',
      );

      log('✅ Facebook Auth Successful');
      return response;
    } catch (e) {
      log('❌ Facebook Auth Error: $e');
      rethrow;
    }
  }

  /// Sign out from Facebook
  Future<void> signOutFacebook() async {
    try {
      await FacebookAuth.instance.logOut();
      log('✅ Logged out from Facebook');
    } catch (e) {
      log('❌ Error logging out from Facebook: $e');
      rethrow;
    }
  }

  /// Check if user is logged in with Facebook
  Future<bool> isLoggedInWithFacebook() async {
    try {
      final AccessToken? accessToken = await FacebookAuth.instance.accessToken;
      return accessToken != null;
    } catch (e) {
      log('❌ Error checking Facebook login status: $e');
      return false;
    }
  }

  /// Get Facebook user data
  Future<Map<String, dynamic>?> getFacebookUserData() async {
    try {
      if (await isLoggedInWithFacebook()) {
        return await FacebookAuth.instance.getUserData();
      }
      return null;
    } catch (e) {
      log('❌ Error getting Facebook user data: $e');
      return null;
    }
  }
}