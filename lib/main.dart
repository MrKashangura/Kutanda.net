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
    // For web, also log to console for better visibility
    if (kIsWeb) {
      // ignore: avoid_print
      print('Uncaught error: $error\n$stack');
    }
  });
}

Future<void> _initializeSupabase() async {
  // URL and key should ideally come from .env file
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://dcjycjiqelcftxbymley.supabase.co';
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjanljamlxZWxjZnR4YnltbGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAyMTIwNTksImV4cCI6MjA1NTc4ODA1OX0.DmLByHHoWeRPusRD2EoYLxxk5F_soscl3jKg7mE4pPM';
  
  log('🔄 Initializing Supabase with URL: $supabaseUrl');
  
  // Initialize Supabase with proper error handling
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
      debug: kDebugMode,
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
      
      // Log the session check for debugging
      log('🔄 Checking user session...');
      
      // Get session data
      final sessionData = await SessionService.getUserSession();
      final hasSession = sessionData.isNotEmpty;
      
      log('📝 Session data: $sessionData');
      
      // Check if user is authenticated
      if (hasSession) {
        final uid = sessionData['uid'];
        final role = sessionData['role'];
        
        if (uid != null && role != null) {
          log('✅ Valid session found for user $uid with role $role');
          setState(() {
            _isAuthenticated = true;
            _userRole = role;
          });
        } else {
          // No valid session data found
          log('⚠️ Incomplete session data found');
          setState(() {
            _isAuthenticated = false;
            _userRole = null;
          });
        }
      } else {
        // No session found
        log('⚠️ No session found, redirecting to login');
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
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading...'),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                Text('Debug: Checking session state...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ],
          ),
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