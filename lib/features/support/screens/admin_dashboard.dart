import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/user_management_service.dart';
import '../../../shared/services/session_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../auth/screens/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserManagementService _userService = UserManagementService();
  
  bool _isLoading = true;
  Map<String, dynamic> _dashboardStats = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch total users count
      final usersResponse = await _supabase.from('users').select('id');
      final totalUsers = usersResponse.length;
      
      // Fetch pending verifications count
      final pendingVerificationsResponse = await _supabase
          .from('sellers')
          .select('id')
          .eq('kyc_status', 'pending');
      final pendingVerifications = pendingVerificationsResponse.length;
      
      // Fetch pending auctions count
      final pendingAuctionsResponse = await _supabase
          .from('auctions')
          .select('id')
          .eq('is_approved', false)
          .eq('is_active', true);
      final pendingAuctions = pendingAuctionsResponse.length;
      
      // Fetch open tickets count
      final openTicketsResponse = await _supabase
          .from('support_tickets')
          .select('id')
          .eq('status', 'open');
      final openTickets = openTicketsResponse.length;
      
      // Fetch pending reports count
      final pendingReportsResponse = await _supabase
          .from('content_reports')
          .select('id')
          .eq('status', 'pending');
      final pendingReports = pendingReportsResponse.length;

      setState(() {
        _dashboardStats = {
          'totalUsers': totalUsers,
          'pendingVerifications': pendingVerifications,
          'pendingAuctions': pendingAuctions,
          'openTickets': openTickets,
          'pendingReports': pendingReports,
        };
        _isLoading = false;
      });
    } catch (e) {
      log('Error loading dashboard data: $e');
      setState(() {
        _error = 'Error loading dashboard data. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              await SessionService.clearSession();

              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildAdminDrawer(),
      body: _isLoading ? 
        const Center(child: CircularProgressIndicator()) : 
        _error != null ? 
          _buildErrorView() : 
          _buildDashboardContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(
            _error ?? 'An error occurred',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Try Again',
            onPressed: _loadDashboardData,
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Platform Overview',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Stats Cards Row
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildStatCard(
                    icon: Icons.people,
                    iconColor: Colors.green,
                    title: 'Total Users',
                    value: _dashboardStats['totalUsers'].toString(),
                    width: 180,
                  ),
                  _buildStatCard(
                    icon: Icons.verified_user,
                    iconColor: Colors.orange,
                    title: 'Pending Verifications',
                    value: _dashboardStats['pendingVerifications'].toString(),
                    width: 180,
                  ),
                  _buildStatCard(
                    icon: Icons.gavel,
                    iconColor: Colors.blue,
                    title: 'Pending Auctions',
                    value: _dashboardStats['pendingAuctions'].toString(),
                    width: 180,
                  ),
                  _buildStatCard(
                    icon: Icons.support_agent,
                    iconColor: Colors.teal,
                    title: 'Open Tickets',
                    value: _dashboardStats['openTickets'].toString(),
                    width: 180,
                  ),
                  _buildStatCard(
                    icon: Icons.report_problem,
                    iconColor: Colors.red,
                    title: 'Pending Reports',
                    value: _dashboardStats['pendingReports'].toString(),
                    width: 180,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Quick Actions Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActionCard(
                  icon: Icons.people,
                  iconColor: Colors.green,
                  title: 'User Management',
                  description: 'Manage users, roles, and permissions',
                  onTap: () => _navigateToUserManagement(),
                ),
                _buildActionCard(
                  icon: Icons.support_agent,
                  iconColor: Colors.teal,
                  title: 'CSR Management',
                  description: 'Manage support staff and performance',
                  onTap: () => _navigateToCSRManagement(),
                ),
                _buildActionCard(
                  icon: Icons.gavel,
                  iconColor: Colors.blue,
                  title: 'Auction Approval',
                  description: 'Review and approve auction listings',
                  onTap: () => _navigateToAuctionApproval(),
                ),
                _buildActionCard(
                  icon: Icons.settings,
                  iconColor: Colors.purple,
                  title: 'Platform Settings',
                  description: 'Configure platform-wide settings',
                  onTap: () => _navigateToPlatformSettings(),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Recent Activity Section (Placeholder)
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRecentActivityList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    double width = 160,
  }) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 40),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    // This is a placeholder for recent activity
    // You can replace this with actual data from your backend
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          String title;
          String subtitle;
          IconData icon;
          Color iconColor;
          
          switch (index) {
            case 0:
              title = 'New user registered';
              subtitle = '2 minutes ago';
              icon = Icons.person_add;
              iconColor = Colors.green;
              break;
            case 1:
              title = 'Auction listing approved';
              subtitle = '15 minutes ago';
              icon = Icons.gavel;
              iconColor = Colors.blue;
              break;
            case 2:
              title = 'Support ticket resolved';
              subtitle = '1 hour ago';
              icon = Icons.check_circle;
              iconColor = Colors.teal;
              break;
            case 3:
              title = 'Seller verification approved';
              subtitle = '3 hours ago';
              icon = Icons.verified_user;
              iconColor = Colors.orange;
              break;
            case 4:
              title = 'Content report handled';
              subtitle = '5 hours ago';
              icon = Icons.report_problem;
              iconColor = Colors.red;
              break;
            default:
              title = 'Activity item';
              subtitle = 'Time ago';
              icon = Icons.info;
              iconColor = Colors.grey;
          }
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.2),
              child: Icon(icon, color: iconColor),
            ),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              // Navigate to specific activity detail
            },
          );
        },
      ),
    );
  }

  Widget _buildAdminDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings, size: 30, color: Colors.green),
                ),
                SizedBox(height: 10),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Kutanda Plant Auction',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('User Management'),
            onTap: () {
              Navigator.pop(context);
              _navigateToUserManagement();
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('CSR Management'),
            onTap: () {
              Navigator.pop(context);
              _navigateToCSRManagement();
            },
          ),
          ListTile(
            leading: const Icon(Icons.gavel),
            title: const Text('Auction Approval'),
            onTap: () {
              Navigator.pop(context);
              _navigateToAuctionApproval();
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('Seller Verification'),
            onTap: () {
              Navigator.pop(context);
              _navigateToSellerVerification();
            },
          ),
          ListTile(
            leading: const Icon(Icons.report_problem),
            title: const Text('Content Moderation'),
            onTap: () {
              Navigator.pop(context);
              _navigateToContentModeration();
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            onTap: () {
              Navigator.pop(context);
              _navigateToAnalytics();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Platform Settings'),
            onTap: () {
              Navigator.pop(context);
              _navigateToPlatformSettings();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              await Supabase.instance.client.auth.signOut();
              await SessionService.clearSession();

              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // Navigation methods for each section
  void _navigateToUserManagement() {
    // Navigate to user management screen
    // This is a placeholder and should be replaced with actual navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User Management feature coming soon')),
    );
  }

  void _navigateToCSRManagement() {
    // Navigate to CSR management screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSR Management feature coming soon')),
    );
  }

  void _navigateToAuctionApproval() {
    // Navigate to auction approval screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Auction Approval feature coming soon')),
    );
  }

  void _navigateToSellerVerification() {
    // Navigate to seller verification screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seller Verification feature coming soon')),
    );
  }

  void _navigateToContentModeration() {
    // Navigate to content moderation screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Content Moderation feature coming soon')),
    );
  }

  void _navigateToAnalytics() {
    // Navigate to analytics screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analytics feature coming soon')),
    );
  }

  void _navigateToPlatformSettings() {
    // Navigate to platform settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Platform Settings feature coming soon')),
    );
  }
}