import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/services/session_service.dart';
import '../../../shared/services/user_service.dart';
import '../../auctions/screens/buyer_dashboard.dart';
import '../../auctions/screens/seller_dashboard.dart';
import '../../support/screens/admin_dashboard.dart';
import '../../support/screens/csr_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final UserService _userService = UserService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final response = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = response.user;
      if (user != null) {
        debugPrint("✅ Authenticated User UID: ${user.id}");

        String? role = await _userService.getUserRole(user.id);
        debugPrint("✅ User role fetched: $role");

        if (role != null) {
          await SessionService.saveUserSession(user.id, role);
          navigateBasedOnRole(role);
        } else {
          showErrorMessage("⚠️ Role not found. Contact support.");
        }
      }
    } on AuthException catch (e) {
      showErrorMessage("❌ Login failed: ${e.message}");
    } catch (e) {
      showErrorMessage("❌ Unexpected error: $e");
    }
  }

  void navigateBasedOnRole(String role) {
    if (!mounted) return;

    Widget screen;
    switch (role) {
      case "buyer":
        screen = const BuyerDashboard();
        break;
      case "seller":
        screen = const SellerDashboard();
        break;
      case "admin":
        screen = const AdminDashboard();
        break;
      case "csr":
        screen = const CSRDashboard();
      break;
      default:
        debugPrint("⚠️ Unknown role.");
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Please enter your email" : null,
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) =>
                    value == null || value.isEmpty ? "Please enter your password" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loginUser,
                child: const Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
