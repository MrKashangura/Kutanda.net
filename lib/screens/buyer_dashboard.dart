import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/api_service.dart';
import '../services/session_service.dart';
import 'login_screen.dart';
import 'seller_dashboard.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  final ApiService _apiService = ApiService();

  Future<void> _switchToSeller() async {
    bool success = await _apiService.switchRole('buyer');
    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SellerDashboard()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Switched to Seller mode')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to switch role')),
      );
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut(); // ✅ Use Supabase logout
    await SessionService.clearSession();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buyer Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: _switchToSeller,
            tooltip: 'Switch to Seller Mode',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: const Center(child: Text("Welcome Buyer")),
    );
  }
}
