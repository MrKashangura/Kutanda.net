import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/auction_model.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/services/onesignal_service.dart';
import '../../auth/widgets/countdown_timer.dart';
import '../services/auction_service.dart';

class EnhancedAuctionScreen extends StatefulWidget {
  const EnhancedAuctionScreen({super.key});

  @override
  State<EnhancedAuctionScreen> createState() => _EnhancedAuctionScreenState();
}

class _EnhancedAuctionScreenState extends State<EnhancedAuctionScreen> {
  final AuctionService _auctionService = AuctionService();
  final NotificationService _notificationService = NotificationService();
  final OneSignalService _oneSignalService = OneSignalService();
  late StreamSubscription<List<Auction>> _auctionSubscription;
  StreamSubscription<Map<String, dynamic>>? _outbidSubscription;
  
  bool _isLoading = true;
  List<Auction> _auctions = [];
  String? _searchQuery;
  bool _onlyActiveAuctions = true;
  Timer? _auctionCheckTimer;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _subscribeToAuctions();
    _startPeriodicChecks();
  }
  
  @override
  void dispose() {
    _auctionSubscription.cancel();
    _outbidSubscription?.cancel();
    _auctionCheckTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _initializeServices() async {
    await _notificationService.initialize();
    await _oneSignalService.initialize();
  }
  
  void _subscribeToAuctions() {
    // Listen for auctions with real-time updates
    _auctionSubscription = _auctionService.getAllAuctions().listen((auctions) {
      if (mounted) {
        setState(() {
          _auctions = auctions;
          _isLoading = false;
        });
      }
    });
    
    // Listen for outbids on auctions the user has bid on
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _outbidSubscription = _auctionService.listenForOutbids(user.id).listen((data) {
        // The notification is handled directly in the service
      });
    }
  }
  
  void _startPeriodicChecks() {
    // Check for auctions ending soon every minute
    _auctionCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _auctionService.checkEndingSoonAuctions();
      _auctionService.checkEndedAuctions();
    });
  }

  void _placeBid(Auction auction) {
    TextEditingController bidController = TextEditingController();
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in to place a bid.")),
      );
      return;
    }

    final minimumBid = auction.highestBid + auction.bidIncrement;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Place Bid on ${auction.title}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Bid: \$${auction.highestBid.toStringAsFixed(2)}'),
            Text('Minimum Bid: \$${minimumBid.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: bidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Your Bid Amount",
                prefixText: "\$",
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              double? bidAmount = double.tryParse(bidController.text);
              if (bidAmount == null || bidAmount < minimumBid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Bid must be at least \$${minimumBid.toStringAsFixed(2)}"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => const Center(child: CircularProgressIndicator()),
              );

              try {
                await _auctionService.placeBid(auction.id, bidAmount, user.id);
                
                if (!mounted) return;
                
                // Close loading dialog
                Navigator.of(context).pop();
                
                // Close bid dialog
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Bid placed successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                
                // Close loading dialog
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error placing bid: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Place Bid"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Auction> filteredAuctions = _auctions;
    
    // Apply search filter
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filteredAuctions = filteredAuctions.where((auction) {
        return auction.title.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
               auction.description.toLowerCase().contains(_searchQuery!.toLowerCase());
      }).toList();
    }
    
    // Filter active auctions if selected
    if (_onlyActiveAuctions) {
      final now = DateTime.now();
      filteredAuctions = filteredAuctions.where((auction) {
        return auction.isActive && auction.endTime.isAfter(now);
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Auctions")),
      body: Column(
        children: [
          // Search and filter
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Search auctions",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _onlyActiveAuctions,
                      onChanged: (value) {
                        setState(() {
                          _onlyActiveAuctions = value ?? true;
                        });
                      },
                    ),
                    const Text("Show only active auctions"),
                  ],
                ),
              ],
            ),
          ),
          
          // Auctions list
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : filteredAuctions.isEmpty
                    ? const Center(child: Text("No auctions found"))
                    : ListView.builder(
                        itemCount: filteredAuctions.length,
                        itemBuilder: (context, index) {
                          final auction = filteredAuctions[index];
                          final now = DateTime.now();
                          final isEnded = now.isAfter(auction.endTime);
                          
                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Display image if available
                                if (auction.imageUrls.isNotEmpty)
                                  SizedBox(
                                    height: 200,
                                    width: double.infinity,
                                    child: Image.network(
                                      auction.imageUrls[0],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => 
                                          const Center(child: Icon(Icons.image_not_supported, size: 64)),
                                    ),
                                  ),
                                
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              auction.title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Status badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isEnded ? Colors.red : Colors.green,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              isEnded ? "Ended" : "Active",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 8),
                                      
                                      Text(
                                        auction.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Bid information
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Current bid: \$${auction.highestBid.toStringAsFixed(2)}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                "Starting price: \$${auction.startingPrice.toStringAsFixed(2)}",
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (!isEnded)
                                                Text(
                                                  "Min next bid: \$${(auction.highestBid + auction.bidIncrement).toStringAsFixed(2)}",
                                                  style: TextStyle(
                                                    color: Colors.grey[800],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          
                                          // Time remaining with live countdown
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text(
                                                "Time remaining:",
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              CountdownTimer(
                                                endTime: auction.endTime,
                                                textStyle: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                onTimerEnd: () {
                                                  // Refresh to update UI when timer ends
                                                  if (mounted) {
                                                    setState(() {});
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Action buttons
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              // View details functionality
                                            },
                                            icon: const Icon(Icons.visibility),
                                            label: const Text("Details"),
                                          ),
                                          
                                          ElevatedButton.icon(
                                            onPressed: isEnded ? null : () => _placeBid(auction),
                                            icon: const Icon(Icons.gavel),
                                            label: const Text("Place Bid"),
                                            style: ElevatedButton.styleFrom(
                                              disabledBackgroundColor: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}