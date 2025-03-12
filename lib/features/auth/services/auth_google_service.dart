// lib/services/auth_google.dart
import 'dart:developer';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling Google authentication with Supabase
class GoogleAuthService {
  final SupabaseClient supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google and authenticate with Supabase
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // Start the Google sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in flow
        log('Google sign-in was canceled by the user');
        return null;
      }

      // Obtain Google auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('Could not get ID token from Google');
      }

      // Sign in to Supabase with Google OAuth credentials
      final AuthResponse response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      log('✅ Google Auth Successful: ${googleUser.email}');
      return response;
    } catch (e) {
      log('❌ Google Auth Error: $e');
      rethrow;
    }
  }

  /// Disconnect Google account
  Future<void> disconnectGoogle() async {
    try {
      await _googleSignIn.disconnect();
      log('✅ Google account disconnected');
    } catch (e) {
      log('❌ Error disconnecting Google account: $e');
      rethrow;
    }
  }

  /// Check if user is currently signed in with Google
  Future<bool> isSignedInWithGoogle() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      log('❌ Error checking Google sign-in status: $e');
      return false;
    }
  }
}