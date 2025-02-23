import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  User? _user;

  User? get user => _user;

  AuthProvider() {
    _listenToAuthChanges();
  }

  /// Listen to authentication state changes
  void _listenToAuthChanges() {
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        log('✅ User logged in: ${data.session?.user}');
        _user = data.session?.user;
      } else if (event == AuthChangeEvent.signedOut) {
        log('❌ User logged out');
        _user = null;
      }
      notifyListeners();
    });
  }

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  /// Sign out the user
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
