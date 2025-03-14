import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/user_management_service.dart';
import '../../../shared/services/onesignal_service.dart';
import '../../../shared/services/session_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../auth/screens/login_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_content_moderation_screen.dart';
import 'admin_csr_management_screen.dart';
import 'admin_system_config_screen.dart';
import 'admin_user_management_screen.dart';


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
  List<Map<String, dynamic>> _recentActivity = [];
  String? _error;
  String _adminName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final userData = await _supabase
            .from('users')
            .select('display_name, email')
            .eq('id', user.id)
            .maybeSingle();
            
        if (userData != null && mounted) {
          setState(() {
            _adminName = userData['display_name'] ?? userData['email'] ?? 'Admin';
          });
        }
      }
    } catch (e) {
      log('Error loading admin info: $e');
    }
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
      
      // Fetch users by role
      final buyersResponse = await _supabase
          .from('users')
          .select('id')
          .eq('role', 'buyer');
      final buyers = buyersResponse.length;
      
      final sellersResponse = await _supabase
          .from('users')
          .select('id')
          .eq('role', 'seller');
      final sellers = sellersResponse.length;
      
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

      // Load recent activity
      await _loadRecentActivity();

      setState(() {
        _dashboardStats = {
          'totalUsers': totalUsers,
          'buyers': buyers,
          'sellers': sellers,
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
  
  Future<void> _loadRecentActivity() async {
    try {
      // Get the most recent moderation logs
      final moderationLogs = await _supabase
          .from('moderation_logs')
          .select('*, moderator:users!moderator_id(display_name, email)')
          .order('timestamp', ascending: false)
          .limit(10);
      
      // Get the most recent user actions
      final userActions = await _supabase
          .from('user_action_history')
          .select('*, admin:users!action_by(display_name, email)')
          .order('timestamp', ascending: false)
          .limit(10);
      
      // Combine and sort
      List<Map<String, dynamic>> recentActivity = [];
      
      for (var log in moderationLogs) {
        recentActivity.add({
          'type': 'moderation',
          'action': log['action_type'],
          'content_type': log['content_type'],
          'timestamp': log['timestamp'],
          'user': log['moderator']['display_name'] ?? log['moderator']['email'] ?? 'Unknown',
        });
      }
      
      for (var action in userActions) {
        recentActivity.add({
          'type': 'user_action',
          'action': action['action_type'],
          'user_id': action['user_id'],
          'timestamp': action['timestamp'],
          'admin': action['admin']['display_name'] ?? action['admin']['email'] ?? 'Unknown',
        });
      }
      
      // Sort by timestamp
      recentActivity.sort((a, b) => 
        DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
      
      // Keep only the most recent 5
      if (recentActivity.length > 5) {
        recentActivity = recentActivity.sublist(0, 5);
      }
      
      setState(() {
        _recentActivity = recentActivity;
      });
    } catch (e) {
      log('Error loading recent activity: $e');
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
            onPressed: _logout,
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
            // Welcome section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, $_adminName',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Platform Overview',
              style: TextStyle(
                fontSize: 20, 
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
                    icon: Icons.person,
                    iconColor: Colors.blue,
                    title: 'Buyers',
                    value: _dashboardStats['buyers'].toString(),
                    width: 180,
                  ),
                  _buildStatCard(
                    icon: Icons.store,
                    iconColor: Colors.purple,
                    title: 'Sellers',
                    value: _dashboardStats['sellers'].toString(),
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
                    iconColor: Colors.teal,
                    title: 'Pending Auctions',
                    value: _dashboardStats['pendingAuctions'].toString(),
                    width: 180,
                  ),
                  _buildStatCard(
                    icon: Icons.support_agent,
                    iconColor: Colors.indigo,
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
            
            const SizedBox(height: 24),
            
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20, 
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
                  iconColor: Colors.indigo,
                  title: 'CSR Management',
                  description: 'Manage support staff and performance',
                  onTap: () => _navigateToCSRManagement(),
                ),
                _buildActionCard(
                  icon: Icons.content_paste,
                  iconColor: Colors.teal,
                  title: 'Content Moderation',
                  description: 'Review auctions, reports and content',
                  onTap: () => _navigateToContentModeration(),
                ),
                _buildActionCard(
                  icon: Icons.analytics,
                  iconColor: Colors.purple,
                  title: 'Analytics Dashboard',
                  description: 'View platform performance metrics',
                  onTap: () => _navigateToAnalytics(),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent Activity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full activity log
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRecentActivityList(),
            
            const SizedBox(height: 24),
            
            // System Status Section
            const Text(
              'System Status',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSystemStatusCard(),
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
    // Using string_extensions.dart for .capitalize()
    String formatContentType(String type) => type.capitalize();
    
    if (_recentActivity.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No recent activity to display'),
          ),
        ),
      );
    }
    
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentActivity.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final activity = _recentActivity[index];
          IconData icon;
          Color iconColor;
          String title;
          
          final timestamp = DateTime.parse(activity['timestamp']);
          final timeAgo = _getTimeAgo(timestamp);
          
          if (activity['type'] == 'moderation') {
            // Handle moderation activity
            switch (activity['action']) {
              case 'approve':
                icon = Icons.check_circle;
                iconColor = Colors.green;
                title = '${activity['content_type'].toString().capitalize()} approved';
                break;
              case 'reject':
                icon = Icons.cancel;
                iconColor = Colors.red;
                title = '${activity['content_type'].toString().capitalize()} rejected';
                break;
              default:
                icon = Icons.content_paste;
                iconColor = Colors.blue;
                title = '${activity['action'].toString().capitalize()} ${activity['content_type']}';
            }
          } else {
            // Handle user action
            switch (activity['action']) {
              case 'suspend':
                icon = Icons.block;
                iconColor = Colors.orange;
                title = 'User suspended';
                break;
              case 'ban':
                icon = Icons.delete_forever;
                iconColor = Colors.red;
                title = 'User banned';
                break;
              case 'warn':
                icon = Icons.warning;
                iconColor = Colors.amber;
                title = 'User warned';
                break;
              default:
                icon = Icons.person;
                iconColor = Colors.blue;
                title = '${activity['action'].toString().capitalize()} user';
            }
          }
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.2),
              child: Icon(icon, color: iconColor),
            ),
            title: Text(title),
            subtitle: Text(
              activity['type'] == 'moderation'
                ? 'By ${activity['user']} • $timeAgo'
                : 'By ${activity['admin']} • $timeAgo'
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              // Navigate to specific activity detail
            },
          );
        },
      ),
    );
  }
  
  Widget _buildSystemStatusCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'All Systems Operational',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to system settings
                    _navigateToPlatformSettings();
                  },
                  child: const Text('Settings'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Status of individual services
            _buildStatusRow('Database', 'Operational', Colors.green),
            const SizedBox(height: 8),
            _buildStatusRow('Authentication', 'Operational', Colors.green),
            const SizedBox(height: 8),
            _buildStatusRow('Storage', 'Operational', Colors.green),
            const SizedBox(height: 8),
            _buildStatusRow('Payment Processing', 'Operational', Colors.green),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    // Toggle maintenance mode
                    _showMaintenanceModeDialog();
                  },
                  child: const Text('Maintenance Mode'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusRow(String service, String status, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          service,
          style: const TextStyle(fontSize: 14),
        ),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              status,
              style: TextStyle(
                fontSize: 14,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings, size: 30, color: Colors.green),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _adminName,
                  style: const TextStyle(
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
            leading: const Icon(Icons.verified_user),
            title: const Text('Seller Verification'),
            onTap: () {
              Navigator.pop(context);
              _navigateToSellerVerification();
            },
          ),
          ListTile(
            leading: const Icon(Icons.content_paste),
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
            title: const Text('System Settings'),
            onTap: () {
              Navigator.pop(context);
              _navigateToPlatformSettings();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Documentation'),
            onTap: () {
              Navigator.pop(context);
              _showHelpDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }
  
  void _showMaintenanceModeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final durationController = TextEditingController(text: '30');
        final messageController = TextEditingController(
          text: 'The system is currently undergoing scheduled maintenance. Please check back soon.',
        );
        
        return AlertDialog(
          title: const Text('Enter Maintenance Mode'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Warning: This will make the platform inaccessible to all users except administrators.',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Maintenance Message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement maintenance mode activation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Maintenance mode activated for ${durationController.text} minutes',
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('ACTIVATE'),
            ),
          ],
        );
      },
    );
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Admin Help & Documentation'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quick Reference Guide',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 10),
                Text('• User Management: Manage platform users and their roles.'),
                Text('• CSR Management: Oversee customer support representatives.'),
                Text('• Content Moderation: Review and approve platform content.'),
                Text('• Analytics: View platform performance metrics.'),
                Text('• System Settings: Configure platform settings.'),
                SizedBox(height: 15),
                Text(
                  'Need More Help?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 10),
                Text('Refer to the full documentation for detailed instructions.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Helper methods for formatting and display
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
  
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).round()} months ago';
    } else {
      return '${(difference.inDays / 365).round()} years ago';
    }
  }
  
  // Navigation methods for each section
  void _navigateToUserManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminUserManagementScreen()),
    );
  }

  void _navigateToCSRManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminCsrManagementScreen()),
    );
  }

  void _navigateToContentModeration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminContentModerationScreen()),
    );
  }

  void _navigateToSellerVerification() {
    // This could redirect to a specific tab in the Content Moderation screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminContentModerationScreen()),
    );
  }

  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminAnalyticsScreen()),
    );
  }

  void _navigateToPlatformSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminSystemConfigScreen()),
    );
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
}