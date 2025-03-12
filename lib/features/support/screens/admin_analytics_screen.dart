// lib/features/support/screens/admin_analytics_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../services/content_moderation_service.dart';
import '../../../services/csr_analytics_service.dart';
import '../../../services/user_management_service.dart';
import '../widgets/admin_drawer.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final CsrAnalyticsService _csrAnalyticsService = CsrAnalyticsService();
  final ContentModerationService _moderationService = ContentModerationService();
  final UserManagementService _userService = UserManagementService();
  
  bool _isLoading = true;
  int _selectedTimeRange = 30; // Default to 30 days
  
  // Analytics data
  Map<String, dynamic> _ticketStats = {};
  List<Map<String, dynamic>> _commonIssueTypes = [];
  Map<String, dynamic> _userStats = {};
  Map<String, dynamic> _moderationStats = {};
  Map<String, dynamic> _verificationStats = {};
  Map<int, int> _ticketVolumeByHour = {};
  
  final List<int> _timeRangeOptions = [7, 30, 90];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load ticket and support analytics
      final ticketStats = await _csrAnalyticsService.getTicketStats(
        lastDays: _selectedTimeRange,
      );
      
      final commonIssues = await _csrAnalyticsService.getCommonIssueTypes(
        lastDays: _selectedTimeRange,
        limit: 5,
      );
      
      final ticketVolumeByHour = await _csrAnalyticsService.getTicketVolumeByHour(
        lastDays: _selectedTimeRange,
      );
      
      // Load user analytics
      final userStats = await _userService.getUserRegistrationStats(
        lastDays: _selectedTimeRange,
      );
      
      // Load moderation analytics
      final moderationStats = await _moderationService.getModerationStats(
        lastDays: _selectedTimeRange,
      );
      
      // Load verification analytics
      final verificationStats = await _userService.getVerificationStats(
        lastDays: _selectedTimeRange,
      );
      
      setState(() {
        _ticketStats = ticketStats;
        _commonIssueTypes = commonIssues;
        _ticketVolumeByHour = ticketVolumeByHour;
        _userStats = userStats;
        _moderationStats = moderationStats;
        _verificationStats = verificationStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
            tooltip: "Refresh Data",
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAnalyticsContent(),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time range selector
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Time Period:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  SegmentedButton<int>(
                    segments: _timeRangeOptions.map((days) {
                      return ButtonSegment<int>(
                        value: days,
                        label: Text('$days days'),
                      );
                    }).toList(),
                    selected: {_selectedTimeRange},
                    onSelectionChanged: (Set<int> newSelection) {
                      setState(() {
                        _selectedTimeRange = newSelection.first;
                      });
                      _loadAnalyticsData();
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadAnalyticsData,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Main analytics sections
          _buildUserAnalyticsSection(),
          _buildSupportAnalyticsSection(),
          _buildModerationAnalyticsSection(),
          _buildVerificationAnalyticsSection(),
        ],
      ),
    );
  }
  
  Widget _buildUserAnalyticsSection() {
    // Extract user stats if available
    final totalUsers = _userStats['total_users'] ?? 0;
    final registrationsByRole = _userStats['registrations_by_role'] as Map<String, dynamic>? ?? {};
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'User Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    // TODO: Export user analytics
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export feature coming soon')),
                    );
                  },
                  tooltip: 'Export Data',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAnalyticsTile(
              title: 'Total Registrations',
              value: totalUsers.toString(),
              icon: Icons.people,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildAnalyticsGrid(
              title: 'Registrations by Role',
              items: [
                _buildAnalyticsTile(
                  title: 'Buyers',
                  value: (registrationsByRole['buyer'] ?? 0).toString(),
                  icon: Icons.person,
                  color: Colors.green,
                ),
                _buildAnalyticsTile(
                  title: 'Sellers',
                  value: (registrationsByRole['seller'] ?? 0).toString(),
                  icon: Icons.store,
                  color: Colors.orange,
                ),
                _buildAnalyticsTile(
                  title: 'CSRs',
                  value: (registrationsByRole['csr'] ?? 0).toString(),
                  icon: Icons.support_agent,
                  color: Colors.purple,
                ),
                _buildAnalyticsTile(
                  title: 'Admins',
                  value: (registrationsByRole['admin'] ?? 0).toString(),
                  icon: Icons.admin_panel_settings,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSupportAnalyticsSection() {
    // Extract ticket stats if available
    final totalTickets = _ticketStats['total_tickets'] ?? 0;
    final resolvedTickets = _ticketStats['resolved_tickets'] ?? 0;
    final unassignedTickets = _ticketStats['unassigned_tickets'] ?? 0;
    final ticketsByStatus = _ticketStats['tickets_by_status'] as Map<String, dynamic>? ?? {};
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Support Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    // TODO: Export support analytics
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export feature coming soon')),
                    );
                  },
                  tooltip: 'Export Data',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsTile(
                    title: 'Total Tickets',
                    value: totalTickets.toString(),
                    icon: Icons.confirmation_number,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsTile(
                    title: 'Resolved Tickets',
                    value: resolvedTickets.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsTile(
                    title: 'Unassigned Tickets',
                    value: unassignedTickets.toString(),
                    icon: Icons.assignment_late,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsTile(
                    title: 'Resolution Rate',
                    value: totalTickets > 0 
                        ? '${(resolvedTickets / totalTickets * 100).toStringAsFixed(1)}%' 
                        : '0%',
                    icon: Icons.trending_up,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Tickets by Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Simple ticket status bar
            Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  _buildStatusBar('Open', ticketsByStatus['open'] ?? 0, totalTickets, Colors.blue),
                  _buildStatusBar('In Progress', ticketsByStatus['inProgress'] ?? 0, totalTickets, Colors.orange),
                  _buildStatusBar('Pending', ticketsByStatus['pendingUser'] ?? 0, totalTickets, Colors.amber),
                  _buildStatusBar('Resolved', ticketsByStatus['resolved'] ?? 0, totalTickets, Colors.green),
                  _buildStatusBar('Closed', ticketsByStatus['closed'] ?? 0, totalTickets, Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatusLegend('Open', Colors.blue),
                const SizedBox(width: 8),
                _buildStatusLegend('In Progress', Colors.orange),
                const SizedBox(width: 8),
                _buildStatusLegend('Pending', Colors.amber),
                const SizedBox(width: 8),
                _buildStatusLegend('Resolved', Colors.green),
                const SizedBox(width: 8),
                _buildStatusLegend('Closed', Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Common Issue Types',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Common issue types
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _commonIssueTypes.length,
              itemBuilder: (context, index) {
                final issue = _commonIssueTypes[index];
                final type = issue['type'] as String;
                final count = issue['count'] as int;
                final percentage = issue['percentage'] as double;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${type.capitalize()}: $count (${percentage.toStringAsFixed(1)}%)'),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getIssueTypeColor(type),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildModerationAnalyticsSection() {
    // Extract moderation stats if available
    final totalActions = _moderationStats['total_actions'] ?? 0;
    final auctionApprovalRate = _moderationStats['auction_approval_rate'] ?? 0.0;
    final actionsByType = _moderationStats['actions_by_type'] as Map<String, dynamic>? ?? {};
    final actionsByContentType = _moderationStats['actions_by_content_type'] as Map<String, dynamic>? ?? {};
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Moderation Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    // TODO: Export moderation analytics
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export feature coming soon')),
                    );
                  },
                  tooltip: 'Export Data',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsTile(
                    title: 'Total Actions',
                    value: totalActions.toString(),
                    icon: Icons.content_paste,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsTile(
                    title: 'Auction Approval Rate',
                    value: '${(auctionApprovalRate * 100).toStringAsFixed(1)}%',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAnalyticsGrid(
              title: 'Actions by Type',
              items: actionsByType.entries.map((entry) {
                final actionType = entry.key;
                final count = entry.value as int;
                
                return _buildAnalyticsTile(
                  title: actionType.capitalize(),
                  value: count.toString(),
                  icon: _getActionTypeIcon(actionType),
                  color: _getActionTypeColor(actionType),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _buildAnalyticsGrid(
              title: 'Actions by Content Type',
              items: actionsByContentType.entries.map((entry) {
                final contentType = entry.key;
                final count = entry.value as int;
                
                return _buildAnalyticsTile(
                  title: contentType.capitalize(),
                  value: count.toString(),
                  icon: _getContentTypeIcon(contentType),
                  color: _getContentTypeColor(contentType),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVerificationAnalyticsSection() {
    // Extract verification stats if available
    final totalVerifications = _verificationStats['total_verifications'] ?? 0;
    final approved = _verificationStats['approved'] ?? 0;
    final rejected = _verificationStats['rejected'] ?? 0;
    final approvalRate = _verificationStats['approval_rate'] ?? 0.0;
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Verification Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    // TODO: Export verification analytics
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export feature coming soon')),
                    );
                  },
                  tooltip: 'Export Data',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsTile(
                    title: 'Total Verifications',
                    value: totalVerifications.toString(),
                    icon: Icons.verified_user,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsTile(
                    title: 'Approval Rate',
                    value: '${(approvalRate * 100).toStringAsFixed(1)}%',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsTile(
                    title: 'Approved',
                    value: approved.toString(),
                    icon: Icons.thumb_up,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsTile(
                    title: 'Rejected',
                    value: rejected.toString(),
                    icon: Icons.thumb_down,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnalyticsTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnalyticsGrid({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text('No data available')
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            childAspectRatio: 2.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            physics: const NeverScrollableScrollPhysics(),
            children: items,
          ),
      ],
    );
  }
  
  Widget _buildStatusBar(String status, int count, int total, Color color) {
    final double percentage = total > 0 ? count / total : 0;
    
    return Tooltip(
      message: '$status: $count (${(percentage * 100).toStringAsFixed(1)}%)',
      child: Container(
        width: percentage > 0 ? MediaQuery.of(context).size.width * percentage * 0.8 : 0,
        color: color,
      ),
    );
  }
  
  Widget _buildStatusLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
  
  Color _getIssueTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'general':
        return Colors.blue;
      case 'auction':
        return Colors.green;
      case 'payment':
        return Colors.purple;
      case 'shipping':
        return Colors.orange;
      case 'account':
        return Colors.teal;
      case 'dispute':
        return Colors.red;
      case 'verification':
        return Colors.amber;
      case 'report':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getActionTypeIcon(String? actionType) {
    switch (actionType) {
      case 'approve':
        return Icons.check;
      case 'reject':
        return Icons.close;
      case 'approve_report':
        return Icons.report_problem;
      case 'reject_report':
        return Icons.remove_circle;
      default:
        return Icons.edit;
    }
  }
  
  Color _getActionTypeColor(String? actionType) {
    switch (actionType) {
      case 'approve':
        return Colors.green;
      case 'reject':
        return Colors.red;
      case 'approve_report':
        return Colors.orange;
      case 'reject_report':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getContentTypeIcon(String contentType) {
    switch (contentType) {
      case 'auction':
        return Icons.gavel;
      case 'review':
        return Icons.star;
      case 'user':
        return Icons.person;
      case 'message':
        return Icons.message;
      default:
        return Icons.content_paste;
    }
  }
  
  Color _getContentTypeColor(String contentType) {
    switch (contentType) {
      case 'auction':
        return Colors.green;
      case 'review':
        return Colors.amber;
      case 'user':
        return Colors.blue;
      case 'message':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}