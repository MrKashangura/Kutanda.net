// lib/features/auth/services/deep_link_handler.dart
import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Only import uni_links if not on web
import 'package:uni_links/uni_links.dart' if (dart.library.html) './web_links_stub.dart';

import '/shared/services/session_service.dart';

class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription? _linkStreamSubscription;
  bool _isInitialized = false;
  
  /// Initialize the deep link handler
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Skip deep link handling on web
    if (kIsWeb) {
      _isInitialized = true;
      log('Deep link handler skipped (not supported on web)');
      return;
    }
    
    try {
      // Handle deep links only on mobile platforms
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
      
      _linkStreamSubscription = linkStream.listen((String? link) {
        if (link != null) {
          _handleDeepLink(link);
        }
      }, onError: (error) {
        log('Deep link error: $error');
      });
      
      _isInitialized = true;
      log('Deep link handler initialized');
    } catch (e) {
      log('Deep link initialization error: $e');
    }
  }
  
  /// Handle incoming deep links
  Future<void> _handleDeepLink(String link) async {
    log('🔗 Received deep link: $link');
    
    // Handle OAuth redirects
    if (link.startsWith('io.supabase.kutanda://login-callback')) {
      log('🔒 Handling OAuth callback');
      
      // The Supabase SDK should automatically handle this callback
      // Just wait a moment for the session to be established
      await Future.delayed(const Duration(seconds: 1));
      
      // Check if we have a valid session
      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;
      
      if (session != null && user != null) {
        // Look up the user role
        final userRole = await _getUserRole(user.id);
        
        // Save the session locally
        await SessionService.saveUserSession(user.id, userRole ?? 'buyer');
        
        log('✅ OAuth authentication completed successfully');
      } else {
        log('❌ No valid session after OAuth callback');
      }
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
  
  /// Dispose resources
  void dispose() {
    _linkStreamSubscription?.cancel();
  }
}