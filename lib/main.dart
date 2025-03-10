import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/utils/constants.dart';
import 'features/auctions/screens/buyer_dashboard.dart';
import 'features/auctions/screens/seller_dashboard.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/support/screens/admin_dashboard.dart';
import 'features/support/screens/csr_dashboard.dart';
import 'shared/services/session_service.dart';

void main() async {
  // This ensures the Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Run the app with error handling
  runZonedGuarded(() async {
    try {
      // Load environment variables if using .env (optional)
      try {
        await dotenv.load();
      } catch (e) {
        log('⚠️ Failed to load .env file: $e');
        // Continue anyway as we'll use hardcoded values as fallback
      }

      // Initialize Supabase
      await _initializeSupabase();

      // Run the app
      runApp(const MyApp());
    } catch (e, stackTrace) {
      log('❌ Critical initialization error: $e', error: e, stackTrace: stackTrace);
      // Run a minimal error reporting widget
      runApp(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Application Initialization Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Error: $e'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => main(), // Try to restart the app
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ));
    }
  }, (error, stack) {
    log('❌ Uncaught error: $error', error: error, stackTrace: stack);
  });
}

Future<void> _initializeSupabase() async {
  // URL and key should ideally come from .env file
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://dcjycjiqelcftxbymley.supabase.co';
  final supabaseKey = dotenv.env['SUPABASE_KEY'] ?? 'YOUR_SUPABASE_ANON_KEY';
  
  // Initialize Supabase with proper error handling
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
      debug: kDebugMode,
      localStorage: kIsWeb 
          ? const EmptyLocalStorage() // Use empty for web initially to avoid issues
          : null, // Use default for mobile
    );
    log('✅ Supabase initialized successfully');
  } catch (e) {
    log('❌ Supabase initialization error: $e');
    rethrow; // Let the caller handle this error
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppTheme.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryColor,
          primary: AppTheme.primaryColor,
          secondary: AppTheme.accentColor,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// Handles authentication flow and role-based routing
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _userRole;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    try {
      setState(() => _isLoading = true);
      
      // Get session data
      final sessionData = await SessionService.getUserSession();
      final hasSession = sessionData.isNotEmpty;
      
      // Check if user is authenticated
      if (hasSession) {
        final uid = sessionData['uid'];
        final role = sessionData['role'];
        
        if (uid != null && role != null) {
          setState(() {
            _isAuthenticated = true;
            _userRole = role;
          });
        } else {
          // No valid session data found
          setState(() {
            _isAuthenticated = false;
            _userRole = null;
          });
        }
      } else {
        // No session found
        setState(() {
          _isAuthenticated = false;
          _userRole = null;
        });
      }
    } catch (e) {
      log('❌ Error checking session: $e');
      setState(() {
        _errorMessage = 'Session error: $e';
        _isAuthenticated = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking session
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error if there was a problem
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _checkUserSession(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Route based on authentication state and role
    if (_isAuthenticated) {
      switch (_userRole) {
        case 'buyer':
          return const BuyerDashboard();
        case 'seller':
          return const SellerDashboard();
        case 'admin':
          return const AdminDashboard();
        case 'csr':
          return const CSRDashboard();
        default:
          return const LoginScreen(); // Fallback to login
      }
    } else {
      return const LoginScreen();
    }
  }
}

// Used for web to avoid secure storage issues initially
class EmptyLocalStorage extends LocalStorage {
  const EmptyLocalStorage();

  @override
  Future<String?> getItem({required String key}) async => null;

  @override
  Future<void> removeItem({required String key}) async {}

  @override
  Future<void> setItem({required String key, required String value}) async {}
}