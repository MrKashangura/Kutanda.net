import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/auction_model.dart';
import '../services/auction_service.dart';

class AuctionScreen extends StatelessWidget {
  const AuctionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AuctionService auctionService = AuctionService();

    return Scaffold(
      appBar: AppBar(title: const Text("Auctions")),
      body: StreamBuilder<List<Auction>>(
        stream: auctionService.getAllAuctions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No auctions available."));
          }

          List<Auction> auctions = snapshot.data!;
          return ListView.builder(
            itemCount: auctions.length,
            itemBuilder: (context, index) {
              Auction auction = auctions[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(auction.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Starting Price: \$${auction.startingPrice}"),
                      Text(
                        "Current Bid: \$${auction.highestBid ?? auction.startingPrice}", // ✅ Fixed null-safe check
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      Text("Highest Bidder: ${auction.highestBidderId ?? 'None'}"),
                      Text(
                        "Ends on: ${auction.endTime.toDate()}",
                      ), // ✅ Removed unnecessary type check
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _placeBid(context, auction),
                    child: const Text("Bid"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _placeBid(BuildContext context, Auction auction) {
    TextEditingController bidController = TextEditingController();
    String bidderId = FirebaseAuth.instance.currentUser?.uid ?? "anonymous";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Place Bid on ${auction.title}"),
        content: TextField(
          controller: bidController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Enter your bid amount"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              double? bidAmount = double.tryParse(bidController.text);
              if (bidAmount == null || bidAmount <= (auction.highestBid ?? auction.startingPrice)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter a valid higher bid.")),
                  );
                }
                return;
              }

              await AuctionService().placeBid(auction.id, bidAmount, bidderId);

              if (!context.mounted) return; // ✅ Prevents use of invalid context
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Bid placed successfully!")),
              );
            },
            child: const Text("Place Bid"),
          ),
        ],
      ),
    );
  }
}

