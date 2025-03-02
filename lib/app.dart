// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'routes.dart';
import 'screens/admin_dashboard.dart';
import 'screens/buyer_dashboard.dart';
import 'screens/csr_dashboard.dart';
import 'screens/login_screen.dart';
import 'screens/seller_dashboard.dart';


class App extends StatelessWidget {
  final Map<String, String?> session;

  const App({required this.session, super.key});

  @override
  Widget build(BuildContext context) {
    Widget initialScreen;

    if (session['uid'] != null && session['role'] != null) {
      debugPrint("Authenticated User UID: ${session['uid']}");
      debugPrint("User Role Fetched: ${session['role']}");

      switch (session['role']) {
        case "buyer":
          initialScreen = const BuyerDashboard();
          break;
        case "seller":
          initialScreen = const SellerDashboard();
          break;
        case "admin":
          initialScreen = const AdminDashboard();
          break;
        case "csr":
          initialScreen = const CSRDashboard();
          break;
        default:
          debugPrint("⚠️ Unknown role: ${session['role']} - Redirecting to LoginScreen");
          initialScreen = const LoginScreen();
      }
    } else {
      debugPrint("⚠️ No valid session found - Redirecting to LoginScreen");
      initialScreen = const LoginScreen();
    }

    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: 'Kutanda Plant Auction',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        routes: appRoutes,
        home: initialScreen,
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: Colors.green[700],
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        primary: Colors.green[700]!,
        secondary: Colors.teal,
        tertiary: Colors.lightGreen,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.green[700],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.green[700]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardTheme(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
    );
  }
}

// Update main.dart to use the new App widget:
/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'your-supabase-url',
    anonKey: 'your-anon-key',
  );

  runApp(const AppInitializer());
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  AppInitializerState createState() => AppInitializerState();
}

class AppInitializerState extends State<AppInitializer> {
  Future<Map<String, String?>> _loadSession() async {
    return await SessionService.getUserSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String?>>(
      future: _loadSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return App(session: snapshot.data ?? {});
      },
    );
  }
}
*/