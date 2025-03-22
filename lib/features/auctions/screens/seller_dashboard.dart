// lib/screens/seller_dashboard.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/auction_model.dart';
import '../../../shared/services/role_service.dart';
import '../../../shared/services/session_service.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import '../../auth/screens/login_screen.dart';
import '../../profile/screens/kyc_submission_screen.dart';
import '../services/auction_service.dart';
import 'buyer_dashboard.dart';
import 'create_auction_screen.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final AuctionService auctionService = AuctionService();
  final RoleService _roleService = RoleService();
  final SupabaseClient supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  bool _isVerified = false;
  String _kycStatus = 'unknown';
  NavDestination _currentDestination = NavDestination.dashboard;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final kycData = await _roleService.checkKycStatus();
      if (!mounted) return;
      setState(() {
        _kycStatus = kycData['status'];
        _isVerified = kycData['status'] == 'verified' && kycData['is_active'];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking verification status: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _switchToBuyer() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      bool success = await _roleService.switchRole('buyer');
      
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
    if (!mounted) return;
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
      
      // Try to close dialog if open
      Navigator.of(context, rootNavigator: true).pop();
      
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

    if (confirmDelete == true && mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Perform the deletion process asynchronously
        await auctionService.deleteAuction(auction.id);
        
        if (!mounted) return;
        
        // Close the loading dialog
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Auction deleted successfully")),
        );
      } catch (e) {
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


  Widget _buildVerificationStatus() {
    IconData statusIcon;
    Color statusColor;
    String statusText;
    
    switch (_kycStatus) {
      case 'verified':
        statusIcon = Icons.verified;
        statusColor = Colors.green;
        statusText = 'Verified Seller';
        break;
      case 'pending':
        statusIcon = Icons.hourglass_top;
        statusColor = Colors.orange;
        statusText = 'Verification Pending';
        break;
      case 'rejected':
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        statusText = 'Verification Rejected';
        break;
      default:
        statusIcon = Icons.person_add;
        statusColor = Colors.blue;
        statusText = 'Verification Required';
    }
    
    // Fix for deprecated color usage
    final Color textColor = Color.fromRGBO(
      statusColor.red, 
      statusColor.green, 
      statusColor.blue, 
      1.0
    );
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Text(
                statusText,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _kycStatus == 'verified'
                ? 'You can now create plant auctions and sell on Kutanda.'
                : _kycStatus == 'pending'
                    ? 'Your verification is being reviewed. This usually takes 1-2 business days.'
                    : _kycStatus == 'rejected'
                        ? 'Your verification was rejected. Please submit again with correct information.'
                        : 'You need to complete seller verification before you can create auctions.',
            style: TextStyle(color: Colors.grey[800]),
          ),
          const SizedBox(height: 16),
          if (_kycStatus != 'verified' && _kycStatus != 'pending')
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const KycSubmissionScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Verification'),
            ),
          if (_kycStatus == 'rejected')
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const KycSubmissionScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Resubmit Verification'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final String sellerId = user?.id ?? '';

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Verification Status Banner
                if (!_isVerified)
                  _buildVerificationStatus(),
                
                // Your Auctions Title
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Auctions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isVerified)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const CreateAuctionScreen()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('New Auction'),
                        ),
                    ],
                  ),
                ),
                
                // Auctions List
                Expanded(
                  child: _isVerified
                      ? StreamBuilder<List<Auction>>(
                          stream: auctionService.getSellerAuctions(sellerId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            }
                            
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'You haven\'t created any auctions yet',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => const CreateAuctionScreen()),
                                        );
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('Create Your First Auction'),
                                    ),
                                  ],
                                ),
                              );
                            }

                            List<Auction> auctions = snapshot.data!;
                            return ListView.builder(
                              itemCount: auctions.length,
                              itemBuilder: (context, index) {
                                Auction auction = auctions[index];
                                
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
                                          height: 150,
                                          width: double.infinity,
                                          child: Image.network(
                                            auction.imageUrls.first,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
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
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    auction.title,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () => _deleteAuction(auction),
                                                ),
                                              ],
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
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                OutlinedButton.icon(
                                                  onPressed: () {
                                                    // View auction details or edit
                                                  },
                                                  icon: const Icon(Icons.edit),
                                                  label: const Text('Edit'),
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
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'Complete verification to create auctions',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: _isVerified
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateAuctionScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigation(
        currentDestination: _currentDestination,
        onDestinationSelected: (destination) {
          setState(() {
            _currentDestination = destination;
          });
          
          if (destination == NavDestination.create && !_isVerified) {
            // If not verified, redirect to KYC screen instead of create
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const KycSubmissionScreen()),
            );
          } else {
            handleNavigation(context, destination, true);
          }
        },
        isSellerMode: true,
      ),
    );
  }
}