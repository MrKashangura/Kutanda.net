import 'package:flutter/material.dart';

class CreateAuctionScreen extends StatelessWidget {
  const CreateAuctionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Auction")),
      body: Center(child: Text("Create Auction Screen")),
    );
  }
}