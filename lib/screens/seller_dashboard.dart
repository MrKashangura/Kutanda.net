import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auction_model.dart';
import '../screens/buyer_dashboard.dart';
import '../screens/create_auction_screen.dart';
import '../screens/login_screen.dart';
import '../services/api_service.dart';
import '../services/auction_service.dart';
import '../services/session_service.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final AuctionService auctionService = AuctionService();
  final ApiService _apiService = ApiService();
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _switchToBuyer() async {
    setState(() => _isLoading = true);
    
    try {
      bool success = await _apiService.switchRole('seller');
      
      // Ensure the widget is still mounted before using context
      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BuyerDashboard()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Switched to Buyer mode')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to switch role')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
        );
      }
      
      await supabase.auth.signOut();
      await SessionService.clearSession();
      
      // Important: Check if still mounted before using context
      if (!mounted) return;
      
      // Close loading dialog first
      Navigator.of(context).pop();
      
      // Navigate to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Close loading dialog if open
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAuction(Auction auction) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Auction"),
        content: const Text(
            "Are you sure you want to delete this auction? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Delete",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (loadingContext) => const Center(child: CircularProgressIndicator()),
        );
      }

      try {
        // Perform the deletion process asynchronously
        await auctionService.deleteAuction(auction.id);
        
        // Check if widget is still mounted before proceeding
        if (!mounted) return;
        
        // Close the loading dialog
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Auction deleted successfully")),
        );
      } catch (e) {
        // Check if widget is still mounted before proceeding
        if (!mounted) return;
        
        // Close the loading dialog
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting auction: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final String sellerId = user?.id ?? ''; // ✅ Safely retrieve seller ID

    return Scaffold(
      appBar: AppBar(
        title: const Text("Seller Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch to Buyer Mode',
            onPressed: _isLoading ? null : _switchToBuyer,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLoading ? null : _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CreateAuctionScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Auction>>(
        stream: auctionService.getSellerAuctions(sellerId), // ✅ Supabase realtime stream
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No auctions yet"));
          }

          List<Auction> auctions = snapshot.data!;
          return ListView.builder(
            itemCount: auctions.length,
            itemBuilder: (context, index) {
              Auction auction = auctions[index];
              return Card(
                child: ListTile(
                  title: Text(auction.title),
                  subtitle: Text("Current Bid: \$${auction.highestBid}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteAuction(auction),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

