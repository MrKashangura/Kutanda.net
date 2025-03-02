// lib/widgets/csr_stats_summary.dart
import 'package:flutter/material.dart';

import '../services/csr_analytics_service.dart';
import '../services/support_ticket_service.dart';

class CSRStatsSummary extends StatefulWidget {
  const CSRStatsSummary({super.key});

  @override
  State<CSRStatsSummary> createState() => _CSRStatsSummaryState();
}

class _CSRStatsSummaryState extends State<CSRStatsSummary> {
  final CsrAnalyticsService _analyticsService = CsrAnalyticsService();
  final SupportTicketService _ticketService = SupportTicketService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      // Get ticket stats
      final ticketStats = await _analyticsService.getTicketStats(lastDays: 7);
      
      // Get resolution time
      final resolutionTime = await _ticketService.getAverageResolutionTime(lastDays: 7);
      
      // Get common issues
      final commonIssues = await _analyticsService.getCommonIssueTypes(lastDays: 7, limit: 3);
      
      setState(() {
        _stats = {
          'total_tickets': ticketStats['total_tickets'] ?? 0,
          'tickets_by_status': ticketStats['tickets_by_status'] ?? {},
          'average_resolution_time': resolutionTime,
          'common_issues': commonIssues,
          'unassigned_tickets': ticketStats['unassigned_tickets'] ?? 0,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stats: $e')),
        );
      }
    }
  }
  
  String _formatDuration(Duration? duration) {
    if (duration == null) return 'N/A';
    
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with refresh button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Stats (Last 7 Days)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadStats,
                tooltip: 'Refresh Stats',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats cards in a horizontal row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Total Tickets Card
                _buildStatCard(
                  icon: Icons.confirmation_num,
                  title: 'Total Tickets',
                  value: _stats['total_tickets'].toString(),
                  color: Colors.blue,
                ),
                
                // Unassigned Tickets
                _buildStatCard(
                  icon: Icons.assignment_late,
                  title: 'Unassigned',
                  value: _stats['unassigned_tickets'].toString(),
                  color: Colors.orange,
                ),
                
                // Average Resolution Time
                _buildStatCard(
                  icon: Icons.timer,
                  title: 'Avg. Resolution',
                  value: _formatDuration(_stats['average_resolution_time']),
                  color: Colors.green,
                ),
                
                // Top Issue Category
                _buildStatCard(
                  icon: Icons.category,
                  title: 'Top Issue Type',
                  value: _stats['common_issues'].isNotEmpty 
                      ? _stats['common_issues'][0]['type']
                      : 'N/A',
                  color: Colors.purple,
                ),
                
                // Active CSRs (placeholder)
                _buildStatCard(
                  icon: Icons.support_agent,
                  title: 'Active CSRs',
                  value: '3', // Placeholder
                  color: Colors.teal,
                ),
                
                // Customer Satisfaction (placeholder)
                _buildStatCard(
                  icon: Icons.thumb_up,
                  title: 'CSAT Score',
                  value: '4.5/5', // Placeholder
                  color: Colors.amber,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(right: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}