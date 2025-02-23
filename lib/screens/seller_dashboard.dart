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

  Future<void> _switchToBuyer() async {
    bool success = await _apiService.switchRole('seller');
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
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator()),
    );
    await supabase.auth.signOut(); // ✅ Use Supabase Auth for logout
    await SessionService.clearSession();
    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
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
            onPressed: _switchToBuyer,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
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
                    onPressed: () async {
                      bool? confirmDelete = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Auction"),
                          content: const Text(
                              "Are you sure you want to delete this auction? This action cannot be undone."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete",
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirmDelete == true) {
                        if (!mounted) return;

                        // ✅ Show dialog before async operation starts
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator()),
                        );

                        // Perform the deletion process asynchronously
                        await auctionService.deleteAuction(auction.id);

                        // ✅ Ensure the widget is still mounted before closing the dialog
                        if (!mounted) return;
                        Navigator.pop(context); // Close loading dialog
                      }
                    },
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


