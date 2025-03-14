// lib/features/auth/services/auth_google_service.dart
import 'dart:developer';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/services/session_service.dart';

class AuthGoogleService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Begin Google sign in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // If user cancels sign in process
      if (googleUser == null) {
        return {
          'success': false,
          'message': 'Sign in canceled by user',
        };
      }
      
      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Sign in with Supabase using the Google credential
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      
      final User? user = response.user;
      
      if (user == null) {
        return {
          'success': false,
          'message': 'Failed to sign in with Google',
        };
      }
      
      // Check if this is a new user by comparing the current time with user creation time
      final isNewUser = DateTime.now().difference(DateTime.parse(user.createdAt)).inSeconds.abs() < 5;
      
      if (isNewUser) {
        // Create a new user profile in the users table
        await _supabase.from('users').insert({
          'id': user.id,
          'email': user.email,
          'display_name': googleUser.displayName,
          'role': 'buyer', // Default role
          'auth_provider': 'google',
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
      log('❌ Google sign in error: $e');
      return {
        'success': false,
        'message': 'Error signing in with Google: $e',
      };
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      log('❌ Google sign out error: $e');
    }
  }
}