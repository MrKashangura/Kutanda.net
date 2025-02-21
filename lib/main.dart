import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/admin_dashboard.dart';
import 'screens/buyer_dashboard.dart';
import 'screens/csr_dashboard.dart';
import 'screens/login_screen.dart';
import 'screens/seller_dashboard.dart';
import 'services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Ensure Firebase is initialized with the correct options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AppInitializer()); // ✅ Handle session loading before rendering MyApp
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