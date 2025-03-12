import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/routes.dart'; // Add this import
import 'core/utils/constants.dart';
import 'features/auth/screens/login_screen.dart';
import 'providers/auth_provider.dart';

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Run with error handling
  runZonedGuarded(() async {
    try {
      // Initialize Supabase first, with proper error handling
      await initializeSupabase();
      
      // Run the app
      runApp(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const MyApp(),
        ),
      );
    } catch (e, stackTrace) {
      log('❌ Critical error: $e', error: e, stackTrace: stackTrace);
      // Display the error screen
      runApp(ErrorApp(error: e.toString()));
    }
  }, (error, stack) {
    log('❌ Uncaught error: $error', error: error, stackTrace: stack);
    if (kDebugMode) {
      print('Stack trace: $stack');
    }
  });
}

/// Initialize Supabase with proper error handling
Future<void> initializeSupabase() async {
  if (kDebugMode) {
    log('Initializing Supabase...');
  }

  try {
    // Wait for Supabase initialization to complete before continuing
    await Supabase.initialize(
      url: 'https://dcjycjiqelcftxbymley.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjanljamlxZWxjZnR4YnltbGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAyMTIwNTksImV4cCI6MjA1NTc4ODA1OX0.DmLByHHoWeRPusRD2EoYLxxk5F_soscl3jKg7mE4pPM',
      debug: kDebugMode,
    );
    
    if (kDebugMode) {
      log('✅ Supabase initialized successfully');
    }
  } catch (e, stackTrace) {
    log('❌ Supabase initialization error', error: e, stackTrace: stackTrace);
    if (kDebugMode) {
      print('Supabase Error: $e');
    }
    rethrow; // Let the caller handle this error
  }
}

/// Main application
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
      routes: appRoutes, // Add this line to register all routes
      home: const LoginScreen(),
    );
  }
}

/// Error screen shown when app initialization fails
class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
              Text('Error: $error'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => main(), // Try to restart the app
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}