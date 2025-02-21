import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/auction_model.dart';
import '../screens/create_auction_screen.dart';
import '../services/auction_service.dart';
import '../services/session_service.dart';
import 'login_screen.dart';

class SellerDashboard extends StatelessWidget {
  const SellerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    String sellerId = FirebaseAuth.instance.currentUser!.uid;
    AuctionService auctionService = AuctionService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Seller Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              await FirebaseAuth.instance.signOut();
              await SessionService.clearSession();

              if (!context.mounted) return;

              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateAuctionScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Auction>>(
        stream: auctionService.getSellerAuctions(sellerId),
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
                  subtitle: Text("Current Bid: \$${auction.highestBid ?? auction.startingPrice}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      bool? confirmDelete = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Auction"),
                          content: const Text("Are you sure you want to delete this auction? This action cannot be undone."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirmDelete == true) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator()),
                        );

                        await auctionService.deleteAuction(auction.id);

                        if (!context.mounted) return; // ✅ Ensure context is still valid
                        Navigator.pop(context); // ✅ Close loading dialog
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


