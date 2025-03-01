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
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _switchToSeller() async {
    setState(() => _isLoading = true);
    
    try {
      // Pass 'buyer' as the current role to switch from
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error switching role: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    
    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }
      
      await supabase.auth.signOut();
      await SessionService.clearSession();
      
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Try to close dialog if open
      Navigator.of(context, rootNavigator: true).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buyer Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: _isLoading ? null : _switchToSeller,
            tooltip: 'Switch to Seller Mode',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLoading ? null : _logout,
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(
            child: Text(
              "Welcome Buyer",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Navigate to auction browsing screen (to be implemented)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Browse Auctions feature coming soon!')),
                );
              },
              child: const Text("Browse Auctions"),
            ),
          ),
        ],
      ),
    );
  }
}