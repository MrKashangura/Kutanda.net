// lib/features/support/screens/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/app_config.dart';
import '../../../shared/services/session_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../auth/screens/login_screen.dart';
import '../widgets/admin_drawer.dart';
import 'admin_user_management_screen.dart';
import 'admin_csr_management_screen.dart';
import 'admin_content_moderation_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_system_config_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic> _dashboardStats = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get user stats
      final usersResponse = await _supabase
          .from('users')
          .select('role', count: CountOption.exact);
      
      final userCount = usersResponse.count ?? 0;
      
      // Get seller verification stats
      final pendingVerifications = await _supabase
          .from('sellers')
          .select('id')
          .eq('kyc_status', 'pending')
          .count();
      
      // Get content moderation stats
      final pendingAuctions = await _supabase
          .from('auctions')
          .select('id')
          .eq('is_approved', false)
          .eq('is_active', true)
          .count();
      
      // Get support ticket stats
      final openTickets = await _supabase
          .from('support_tickets')
          .select('id')
          .eq('status', 'open')
          .count();
      
      // Get report stats
      final pendingReports = await _supabase
          .from('content_reports')
          .select('id')
          .eq('status', 'pending')
          .count();
      
      setState(() {
        _dashboardStats = {
          'totalUsers': userCount,
          'pendingVerifications': pendingVerifications,
          'pendingAuctions': pendingAuctions,
          'openTickets': openTickets,
          'pendingReports': pendingReports,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard data: $e')),
        );
      }
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
            tooltip: "Refresh Data",
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
            tooltip: "Logout",
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Platform Overview",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Stats Cards Row
            _buildStatsRow(),
            const SizedBox(height: 24),
            
            // Action Cards Section
            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Cards Grid
            _buildActionCardsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
            title: "Total Users",
            value: _dashboardStats['totalUsers'].toString(),
            icon: Icons.people,
            color: AppColors.primary,
          ),
          _buildStatCard(
            title: "Pending Verifications",
            value: _dashboardStats['pendingVerifications'].toString(),
            icon: Icons.verified_user,
            color: AppColors.warning,
          ),
          _buildStatCard(
            title: "Pending Auctions",
            value: _dashboardStats['pendingAuctions'].toString(),
            icon: Icons.gavel,
            color: AppColors.info,
          ),
          _buildStatCard(
            title: "Open Tickets",
            value: _dashboardStats['openTickets'].toString(),
            icon: Icons.support_agent,
            color: AppColors.accent,
          ),
          _buildStatCard(
            title: "Pending Reports",
            value: _dashboardStats['pendingReports'].toString(),
            icon: Icons.report_problem,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(right: 16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCardsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          title: "User Management",
          description: "Manage users, roles, and permissions",
          icon: Icons.manage_accounts,
          color: AppColors.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminUserManagementScreen(),
              ),
            );
          },
        ),
        _buildActionCard(
          title: "CSR Management",
          description: "Manage support staff and performance",
          icon: Icons.support_agent,
          color: AppColors.accent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminCsrManagementScreen(),
              ),
            );
          },
        ),
        _buildActionCard(
          title: "Content Moderation",
          description: "Review and moderate platform content",
          icon: Icons.content_paste,
          color: AppColors.warning,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminContentModerationScreen(),
              ),
            );
          },
        ),
        _buildActionCard(
          title: "Analytics",
          description: "View platform metrics and reports",
          icon: Icons.analytics,
          color: AppColors.info,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminAnalyticsScreen(),
              ),
            );
          },
        ),
        _buildActionCard(
          title: "System Configuration",
          description: "Configure platform settings",
          icon: Icons.settings,
          color: AppColors.success,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminSystemConfigScreen(),
              ),
            );
          },
        ),
        _buildActionCard(
          title: "Security",
          description: "Manage security and audit logs",
          icon: Icons.security,
          color: AppColors.error,
          onTap: () {
            // Navigate to security page (to be implemented)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Security module coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
