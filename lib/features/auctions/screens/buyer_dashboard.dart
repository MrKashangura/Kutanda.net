// lib/screens/buyer_dashboard.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/auction_model.dart';
import '../../../services/api_service.dart';
import '../../../shared/services/onesignal_service.dart';
import '../../../shared/services/role_service.dart';
import '../../../shared/services/session_service.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import '../../auth/screens/login_screen.dart';
import '../../profile/screens/kyc_submission_screen.dart';
import '../services/auction_service.dart';
import 'seller_dashboard.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  final ApiService _apiService = ApiService();
  final RoleService _roleService = RoleService();
  final AuctionService _auctionService = AuctionService();
  final SupabaseClient supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  NavDestination _currentDestination = NavDestination.dashboard;
  String _searchQuery = '';
  bool _showOnlyActive = true;

  Future<void> _switchToSeller() async {
    setState(() => _isLoading = true);
    
    try {
      // First check if seller profile is verified and active
      final roleStatus = await _roleService.getUserRoles();
      
      if (!mounted) return;
      
      if (!roleStatus['seller'] || roleStatus['seller_status'] != 'verified') {
        // Show dialog explaining they need to complete KYC
        final bool goToKyc = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Seller Verification Required'),
            content: Text(
              roleStatus['seller_status'] == 'pending' 
                ? 'Your seller verification is pending approval. Please check back later.'
                : 'You need to complete seller verification before you can switch to seller mode.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              if (roleStatus['seller_status'] != 'pending')
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Start Verification'),
                ),
            ],
          ),
        ) ?? false;
        
        if (!mounted) return;
        
        if (goToKyc) {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const KycSubmissionScreen())
          );
        }
        
        setState(() => _isLoading = false);
        return;
      }
      
      // If verified, attempt to switch roles
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
  setState(() => _isLoading = true); // Show loading indicator
  
  try {
    // Clear OneSignal data first if you're using it
    final oneSignalService = OneSignalService();
    await oneSignalService.clearUserData();
    
    // Clear session using only SessionService to avoid double signOut calls
    await SessionService.clearSession();
    
    if (!mounted) return;
    
    // Navigate to login screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false, // Remove all previous routes
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
      setState(() => _isLoading = false); // Hide loading indicator
    }
  }
}
  Stream<List<Auction>> _getAuctionsStream() {
    if (_showOnlyActive) {
      return _auctionService.getActiveAuctions();
    } else {
      return _auctionService.getAllAuctions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kutanda Plant Auction"),
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
        children: [
          // Search and filter area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search plants...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Active auctions only'),
                        value: _showOnlyActive,
                        onChanged: (value) {
                          setState(() {
                            _showOnlyActive = value;
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // Show more filter options
                      },
                      icon: const Icon(Icons.filter_list),
                      label: const Text('Filters'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Auction listings
          Expanded(
            child: StreamBuilder<List<Auction>>(
              stream: _getAuctionsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No auctions available'),
                  );
                }
                
                final auctions = snapshot.data!;
                
                // Filter by search query if provided
                final filteredAuctions = _searchQuery.isEmpty
                    ? auctions
                    : auctions.where((auction) =>
                        auction.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        auction.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                
                if (filteredAuctions.isEmpty) {
                  return const Center(
                    child: Text('No matching auctions found'),
                  );
                }
                
                return ListView.builder(
                  itemCount: filteredAuctions.length,
                  itemBuilder: (context, index) {
                    final auction = filteredAuctions[index];
                    
                    // Calculate time remaining
                    final now = DateTime.now();
                    final difference = auction.endTime.difference(now);
                    final timeRemaining = difference.isNegative
                        ? 'Auction ended'
                        : '${difference.inDays}d ${difference.inHours % 24}h ${difference.inMinutes % 60}m';
                    
                    return Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Display the first image if available
                          if (auction.imageUrls.isNotEmpty)
                            SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: Image.network(
                                auction.imageUrls.first,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return const Center(
                                    child: Icon(Icons.image_not_supported, size: 50),
                                  );
                                },
                              ),
                            ),
                          
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auction.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  auction.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Current Bid: \$${auction.highestBid.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        Text(
                                          'Starting: \$${auction.startingPrice.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          timeRemaining,
                                          style: TextStyle(
                                            color: difference.isNegative ? Colors.red : Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'End: ${auction.endTime.day}/${auction.endTime.month}/${auction.endTime.year}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        // View auction details
                                      },
                                      icon: const Icon(Icons.visibility),
                                      label: const Text('Details'),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: difference.isNegative
                                          ? null  // Disable if auction ended
                                          : () {
                                              // Place a bid 
                                              _placeBid(auction);
                                            },
                                      icon: const Icon(Icons.gavel),
                                      label: const Text('Place Bid'),
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
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        currentDestination: _currentDestination,
        onDestinationSelected: (destination) {
          setState(() {
            _currentDestination = destination;
          });
          handleNavigation(context, destination, false);
        },
        isSellerMode: false,
      ),
    );
  }
  
  void _placeBid(Auction auction) {
    TextEditingController bidController = TextEditingController();
    final minimumBid = auction.highestBid + auction.bidIncrement;
    
    // Use a local context to avoid using context across async gaps
    final localContext = context;
    
    showDialog(
      context: localContext,
      builder: (dialogContext) => AlertDialog(
        title: Text("Place Bid on ${auction.title}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current highest bid: \$${auction.highestBid.toStringAsFixed(2)}'),
            Text('Minimum bid: \$${minimumBid.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: bidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Your bid amount",
                prefixText: "\$",
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validate and place bid
              final bidAmount = double.tryParse(bidController.text);
              
              if (bidAmount == null || bidAmount < minimumBid) {
                // Show error in the dialog context
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Bid must be at least \$${minimumBid.toStringAsFixed(2)}')),
                );
                return;
              }
              
              final user = supabase.auth.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('You must be logged in to place a bid')),
                );
                return;
              }
              
              Navigator.pop(dialogContext);
              
              // Store context for later use
              final originalContext = localContext;
              
              // Show loading indicator
              if (!mounted) return;
              showDialog(
                context: originalContext,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              
              try {
                await _auctionService.placeBid(auction.id, bidAmount, user.id);
                
                if (!mounted) return;
                Navigator.pop(originalContext); // Close loading dialog
                
                ScaffoldMessenger.of(originalContext).showSnackBar(
                  SnackBar(content: Text('Bid of \$${bidAmount.toStringAsFixed(2)} placed successfully!')),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(originalContext); // Close loading dialog
                
                ScaffoldMessenger.of(originalContext).showSnackBar(
                  SnackBar(content: Text('Error placing bid: $e')),
                );
              }
            },
            child: const Text("Place Bid"),
          ),
        ],
      ),
    );
  }
}