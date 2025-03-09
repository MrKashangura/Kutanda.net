import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart' show AppConfig;
import 'core/utils/constants.dart';
import 'features/auctions/screens/buyer_dashboard.dart';
import 'features/auctions/screens/seller_dashboard.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/support/screens/admin_dashboard.dart';
import 'features/support/screens/csr_dashboard.dart';
import 'shared/services/session_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables if using dotenv
  await dotenv.load(fileName: ".env");
  
  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('FLUTTER ERROR: ${details.exception}');
    print('STACK TRACE: ${details.stack}');
  };
  
  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  
  runApp(const KutandaApp());
}

class KutandaApp extends StatelessWidget {
  const KutandaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ThemeData(
        primaryColor: AppTheme.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryColor,
          secondary: AppTheme.accentColor,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/buyer_dashboard': (context) => const BuyerDashboard(),
        '/seller_dashboard': (context) => const SellerDashboard(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/csr_dashboard': (context) => const CSRDashboard(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser != null) {
      // User is logged in, check session and route based on role
      return FutureBuilder<Map<String, String?>>(
        future: SessionService.getUserSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          final session = snapshot.data ?? {};
          final role = session['role'];
          
          if (role == null || role.isEmpty) {
            // No role found, redirect to login
            return const LoginScreen();
          }
          
          switch (role) {
            case 'buyer':
              return const BuyerDashboard();
            case 'seller':
              return const SellerDashboard();
            case 'admin':
              return const AdminDashboard();
            case 'csr':
              return const CSRDashboard();
            default:
              return const LoginScreen();
          }
        },
      );
    } else {
      // User is not logged in
      return const LoginScreen();
    }
  }
}