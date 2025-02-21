import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../services/user_service.dart';
import 'admin_dashboard.dart';
import 'buyer_dashboard.dart';
import 'seller_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // ✅ Form validation key

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return; // ✅ Ensure form is valid before login

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        debugPrint("Authenticated User UID: ${user.uid}"); // ✅ Debug UID

        String? role = await _userService.getUserRole(user.uid);
        debugPrint("User role fetched: $role");  // ✅ Debug role

        if (role != null) {
          await SessionService.saveUserSession(user.uid, role);
          navigateBasedOnRole(role);
        } else {
          showErrorMessage("Role not found. Contact support.");
        }
      }
    } catch (e) {
      showErrorMessage("Login failed: $e");
    }
  }

  void navigateBasedOnRole(String role) {
    if (!mounted) return; // ✅ Fix: Prevent navigation errors when widget is disposed

    if (role == "buyer") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BuyerDashboard()));
    } else if (role == "seller") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SellerDashboard()));
    } else if (role == "admin") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
    } else {
      debugPrint("Unknown role.");
    }
  }

  void showErrorMessage(String message) {
    if (!mounted) return; // ✅ Fix: Ensure context is available before showing Snackbar

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) { // ✅ Fix: Add missing build method
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // ✅ Attach the form key
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your email";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your password";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loginUser, // ✅ Fix: Ensure function reference is correct
                child: const Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
} // ✅ Fix: Ensure class is properly closed
