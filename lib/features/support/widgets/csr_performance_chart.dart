// lib/widgets/csr_performance_chart.dart
import 'package:flutter/material.dart';

/// A widget that displays a CSR's performance metrics compared to team averages
class CSRPerformanceChart extends StatelessWidget {
  final Map<String, dynamic> csrPerformance;
  final Map<String, dynamic> teamAverage;
  
  const CSRPerformanceChart({
    super.key,
    required this.csrPerformance,
    required this.teamAverage,
  });

  @override
  Widget build(BuildContext context) {
    // Extract values from the performance maps with defaults for safety
    final int csrTotalTickets = csrPerformance['total_tickets'] as int? ?? 0;
    final int csrResolvedTickets = csrPerformance['resolved_tickets'] as int? ?? 0;
    final double csrResolutionRate = csrPerformance['resolution_rate'] as double? ?? 0.0;
    final Duration? csrAvgResolutionTime = csrPerformance['average_resolution_time'] as Duration?;
    
    final int teamTotalTickets = teamAverage['total_tickets'] as int? ?? 0;
    final double teamResolutionRate = teamAverage['resolution_rate'] as double? ?? 0.0;
    final Duration? teamAvgResolutionTime = teamAverage['average_resolution_time'] as Duration?;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(  // Using ListView instead of Column to handle overflow
          shrinkWrap: true, // Ensure the ListView takes only the space it needs
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Total Tickets comparison
            _buildMetricComparisonRow(
              context,
              'Total Tickets',
              csrTotalTickets.toString(),
              teamTotalTickets.toString(),
              csrTotalTickets >= teamTotalTickets,
            ),
            
            const SizedBox(height: 16),
            
            // Resolution Rate comparison
            _buildMetricComparisonRow(
              context,
              'Resolution Rate',
              '${(csrResolutionRate * 100).toStringAsFixed(1)}%',
              '${(teamResolutionRate * 100).toStringAsFixed(1)}%',
              csrResolutionRate >= teamResolutionRate,
            ),
            
            const SizedBox(height: 16),
            
            // Average Resolution Time comparison
            _buildMetricComparisonRow(
              context,
              'Avg. Resolution Time',
              _formatDuration(csrAvgResolutionTime),
              _formatDuration(teamAvgResolutionTime),
              csrAvgResolutionTime == null ? false : 
                teamAvgResolutionTime == null ? true :
                csrAvgResolutionTime.inMinutes <= teamAvgResolutionTime.inMinutes,
              reverseComparison: true, // Lower is better for resolution time
            ),
            
            const SizedBox(height: 16),
            
            // Resolved Tickets
            Row(
              children: [
                const Text('Resolved Tickets: '),
                Text(
                  '$csrResolvedTickets',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text('Your Performance'),
                const SizedBox(width: 24),
                Container(
                  width: 16,
                  height: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text('Team Average'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricComparisonRow(
    BuildContext context,
    String metricName, 
    String yourValue, 
    String teamValue,
    bool isHigher,
    {bool reverseComparison = false}
  ) {
    final bool isPositive = reverseComparison ? !isHigher : isHigher;
    final Color comparisonColor = isPositive ? Colors.green : Colors.red;
    final IconData comparisonIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metricName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Your metric
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    yourValue,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Comparison indicator
            Icon(comparisonIcon, color: comparisonColor, size: 16),
            const SizedBox(width: 4),
            Text(
              reverseComparison
                  ? isHigher ? 'Faster' : 'Slower'
                  : isHigher ? 'Higher' : 'Lower',
              style: TextStyle(color: comparisonColor, fontSize: 12),
            ),
            
            // Team metric
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Team Average',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teamValue,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
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
}