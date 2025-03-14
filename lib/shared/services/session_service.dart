// lib/shared/services/session_service.dart
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService {
  static final supabase = Supabase.instance.client;

  /// **Retrieve user session from Supabase**
  static Future<Map<String, String?>> getUserSession() async {
    try {
      // Get from shared preferences first
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? uid = prefs.getString('uid');
      String? role = prefs.getString('role');

      // Debug log for web
      if (kDebugMode) {
        log("🔍 Checking stored session - UID: $uid, Role: $role");
      }

      // Get current user from Supabase
      final user = supabase.auth.currentUser;
      
      // Debug the current authenticated user
      if (kDebugMode) {
        log("🔍 Current Supabase user: ${user?.id}");
      }

      // If no user or no stored UID, return empty
      if (user == null) {
        log("⚠️ No active session found in Supabase.");
        return {};
      }

      // If we have both uid and role cached, return them
      if (uid != null && role != null) {
        log("✅ Returning cached session: UID=$uid, Role=$role");
        return {'uid': uid, 'role': role};
      }

      // We have a user but not the complete session - let's fetch from database
      try {
        // FIXED: Use user.id instead of uid for database query
        final response = await supabase
            .from('users')
            .select('role')
            .eq('id', user.id)  // Changed from 'uid' to 'id' to match database schema
            .maybeSingle();

        if (kDebugMode) {
          log("🔍 Database response: $response");
        }

        if (response == null) {
          log("⚠️ User role not found in database.");
          return {};
        }

        role = (response['role'] ?? "unknown").toString();
        uid = user.id;  // Set uid from the supabase user id
        
        // Save to preferences
        await prefs.setString('uid', uid);
        await prefs.setString('role', role);
        
        log("✅ Session retrieved from Supabase: UID=$uid, Role=$role");
        return {'uid': uid, 'role': role};
      } catch (e) {
        log("❌ Supabase fetch error: $e");
        return {};
      }
    } catch (e) {
      log("❌ Session service error: $e");
      return {};
    }
  }

  static Future<void> saveUserSession(String uid, String role) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', uid);
      await prefs.setString('role', role);
      log("✅ Session saved: UID=$uid, Role=$role");
    } catch (e) {
      log("❌ Error saving session: $e");
    }
  }

  /// **Clear user session**
  static Future<void> clearSession() async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await supabase.auth.signOut();
    log("✅ Session cleared.");
  } catch (e) {
    log("❌ Error clearing session: $e");
    rethrow; // Rethrow to handle in UI
  }
}
}