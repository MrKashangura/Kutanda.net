// lib/providers/auth_provider.dart
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/services/session_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  User? _user;
  String? _role;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get role => _role;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initialize();
  }

  /// Initialize the provider and listen to auth changes
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check current session
      final currentUser = supabase.auth.currentUser;
      if (kDebugMode) {
        log('Current Supabase user: ${currentUser?.id}');
      }

      if (currentUser != null) {
        _user = currentUser;
        
        // Get role from session service
        final sessionData = await SessionService.getUserSession();
        _role = sessionData['role'];
        
        if (kDebugMode) {
          log('Session data retrieved: $sessionData');
        }
      }

      // Listen to auth state changes
      _listenToAuthChanges();
    } catch (e) {
      _error = e.toString();
      log('❌ Error initializing AuthProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Listen to authentication state changes
  void _listenToAuthChanges() {
    supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (kDebugMode) {
        log('Auth state changed: $event, User: ${session?.user.id}');
      }

      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        _user = session?.user;
        
        if (_user != null) {
          try {
            // Fetch and save user role
            final userResponse = await supabase
                .from('users')
                .select('role')
                .eq('id', _user!.id)
                .maybeSingle();
            
            if (kDebugMode) {
              log('User data response: $userResponse');
            }

            if (userResponse != null) {
              _role = userResponse['role'];
              await SessionService.saveUserSession(_user!.id, _role!);
            }
          } catch (e) {
            log('❌ Error fetching user role: $e');
          }
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        _role = null;
        await SessionService.clearSession();
      }

      notifyListeners();
    });
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        log('Attempting sign in for: $email');
      }

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _user = response.user;
      
      if (_user != null) {
        // Fetch user role
        final userResponse = await supabase
            .from('users')
            .select('role')
            .eq('id', _user!.id)
            .maybeSingle();

        if (kDebugMode) {
          log('User data response: $userResponse');
        }

        if (userResponse != null) {
          _role = userResponse['role'];
          await SessionService.saveUserSession(_user!.id, _role!);
          
          if (kDebugMode) {
            log('✅ Successfully signed in and saved session. User: ${_user!.id}, Role: $_role');
          }
          
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      
      _error = 'Could not retrieve user role';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      log('❌ Error signing in: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out the user
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await SessionService.clearSession();
      await supabase.auth.signOut();
      _user = null;
      _role = null;
    } catch (e) {
      _error = e.toString();
      log('❌ Error signing out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register a new user
  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      _user = response.user;
      
      if (_user != null) {
        // Create user record in database with default buyer role
        await supabase.from('users').insert({
          'id': _user!.id,
          'email': email,
          'role': 'buyer',
          'created_at': DateTime.now().toIso8601String(),
        });

        _role = 'buyer';
        await SessionService.saveUserSession(_user!.id, _role!);
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _error = 'Registration failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      log('❌ Error registering: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}