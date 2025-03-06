import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/admin_dashboard.dart';
import 'screens/buyer_dashboard.dart';
import 'screens/csr_dashboard.dart';
import 'screens/login_screen.dart';
import 'screens/seller_dashboard.dart';
import 'services/onesignal_service.dart';
import 'services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://dcjycjiqelcftxbymley.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjanljamlxZWxjZnR4YnltbGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAyMTIwNTksImV4cCI6MjA1NTc4ODA1OX0.DmLByHHoWeRPusRD2EoYLxxk5F_soscl3jKg7mE4pPM',
  );

  // Initialize services
  final oneSignalService = OneSignalService();
  await oneSignalService.initialize();

  runApp(const AppInitializer()); // ✅ Properly initialize session
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  AppInitializerState createState() => AppInitializerState();
}

class AppInitializerState extends State<AppInitializer> {
  Future<Map<String, String?>> _loadSession() async {
    return await SessionService.getUserSession(); // ✅ Load session asynchronously
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String?>>(
      future: _loadSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()), // ✅ Show loading screen while fetching session
            ),
          );
        }

        return MyApp(session: snapshot.data ?? {}); // ✅ Pass session data to MyApp
      },
    );
  }
}

class MyApp extends StatelessWidget {
  final Map<String, String?> session;

  const MyApp({required this.session, super.key});

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
        case "csr": // ✅ NEW: Handle CSR role
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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: initialScreen,
    );
  }
}