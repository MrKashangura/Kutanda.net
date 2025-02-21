import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/session_service.dart';
import 'login_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Dashboard"),
      actions: [ // ✅ Add the logout button to the AppBar actions
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await SessionService.clearSession();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(child: Text("Welcome Admin")),
    );
  }
}
