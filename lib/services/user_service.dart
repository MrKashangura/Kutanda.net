import 'dart:developer'; // ✅ Use proper logging

import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// **Fetch user role from Supabase**
  Future<String?> getUserRole(String uid) async {
    try {
      final response = await supabase
          .from('users')
          .select('role')
          .eq('uid', uid)
          .maybeSingle(); // ✅ Use maybeSingle() to prevent errors

      if (response != null) {
        return response['role'] as String?;
      }
    } catch (e) {
      log("❌ Error fetching user role: $e");
    }
    return null;
  }
}
