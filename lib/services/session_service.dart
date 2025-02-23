import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService {
  static final supabase = Supabase.instance.client;

  /// **Retrieve user session from Supabase**
  static Future<Map<String, String?>> getUserSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uid = prefs.getString('uid');
    String? role = prefs.getString('role');

    final user = supabase.auth.currentUser;
    if (user == null || uid == null) {
      log("⚠️ No active session found.");
      return {};
    }

    if (role != null) {
      log("✅ Returning cached session: UID=$uid, Role=$role");
      return {'uid': uid, 'role': role};
    }

    try {
      final response = await supabase
          .from('users')
          .select('role')
          .eq('auth_id', user.id)
          .maybeSingle(); // ✅ FIXED: Access response directly

      if (response == null) {
        log("⚠️ User role not found in database.");
        return {};
      }

      role = response['role'] ?? "unknown"; // ✅ Access data directly
      await prefs.setString('role', role!);
      log("✅ Session retrieved from Supabase: UID=$uid, Role=$role");
      return {'uid': uid, 'role': role};
    } catch (e) {
      log("❌ Supabase fetch error: $e");
      return {};
    }
  }
  static Future<void> saveUserSession(String uid, String role) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
    await prefs.setString('role', role);
    log("✅ Session saved: UID=$uid, Role=$role");
  }

  /// **Clear user session**
  static Future<void> clearSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await supabase.auth.signOut(); // ✅ Ensure Supabase sign-out
    log("✅ Session cleared.");
  }
}


