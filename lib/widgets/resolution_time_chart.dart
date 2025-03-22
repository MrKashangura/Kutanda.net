// lib/widgets/resolution_time_chart.dart
import 'package:flutter/material.dart';

/// A widget that displays a bar chart of resolution times by priority level
class ResolutionTimeChart extends StatelessWidget {
  final Map<String, Duration> resolutionTimes;
  
  const ResolutionTimeChart({
    super.key,
    required this.resolutionTimes,
  });

  @override
  Widget build(BuildContext context) {
    if (resolutionTimes.isEmpty) {
      return const Center(
        child: Text('No resolution time data available'),
      );
    }
    
    // Get priorities in correct order
    final List<String> priorities = [
      'low',
      'medium',
      'high',
      'urgent',
    ].where((priority) => resolutionTimes.containsKey(priority)).toList();
    
    // Get max resolution time for scale
    final int maxMinutes = resolutionTimes.values
        .map((duration) => duration.inMinutes)
        .fold(0, (max, minutes) => minutes > max ? minutes : max);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Average Resolution Time by Priority',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Chart
            Expanded(
              child: ListView.builder(
                itemCount: priorities.length,
                itemBuilder: (context, index) {
                  final priority = priorities[index];
                  final duration = resolutionTimes[priority]!;
                  
                  return _buildBarEntry(
                    context,
                    priority,
                    duration,
                    maxMinutes,
                  );
                },
              ),
            ),
            
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.watch_later_outlined, size: 16),
                const SizedBox(width: 4),
                const Text(
                  'Time in hours and minutes',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBarEntry(
    BuildContext context,
    String priority,
    Duration duration,
    int maxMinutes,
  ) {
    final Color barColor = _getPriorityColor(priority);
    final double barWidth = maxMinutes > 0 ? duration.inMinutes / maxMinutes : 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority label
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: barColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${priority.substring(0, 1).toUpperCase()}${priority.substring(1)} Priority',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                _formatDuration(duration),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Bar
          Stack(
            children: [
              // Background
              Container(
                height: 24,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              
              // Value bar
              FractionallySizedBox(
                widthFactor: barWidth,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours h $minutes m';
    } else {
      return '$minutes m';
    }
  }
}