// lib/widgets/ticket_distribution_chart.dart
import 'package:flutter/material.dart';

/// A widget that displays the distribution of tickets by status in a pie chart-like visualization
class TicketDistributionChart extends StatelessWidget {
  final Map<String, int> statusCounts;
  
  const TicketDistributionChart({
    super.key,
    required this.statusCounts,
  });

  @override
  Widget build(BuildContext context) {
    if (statusCounts.isEmpty) {
      return const Center(
        child: Text('No ticket data available'),
      );
    }
    
    // Calculate total tickets
    final int totalTickets = statusCounts.values.fold(0, (sum, count) => sum + count);
    
    // Get statuses in correct order
    final List<String> statuses = [
      'open',
      'inProgress',
      'pendingUser',
      'resolved',
      'closed',
    ].where((status) => statusCounts.containsKey(status)).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ticket Distribution by Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Chart
            Expanded(
              child: Row(
                children: [
                  // Status bars
                  Expanded(
                    flex: 3,
                    child: ListView.builder(
                      itemCount: statuses.length,
                      itemBuilder: (context, index) {
                        final status = statuses[index];
                        final count = statusCounts[status] ?? 0;
                        final percentage = totalTickets > 0
                            ? (count / totalTickets * 100)
                            : 0.0;
                        
                        return _buildStatusBar(
                          context, 
                          status, 
                          count, 
                          percentage,
                        );
                      },
                    ),
                  ),
                  
                  // Circular representation
                  Expanded(
                    flex: 2,
                    child: _buildCircularChart(context, statuses),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusBar(
    BuildContext context,
    String status,
    int count,
    double percentage,
  ) {
    final Color statusColor = _getStatusColor(status);
    final String statusLabel = _getStatusLabel(status);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status label and count
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '$count (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCircularChart(BuildContext context, List<String> statuses) {
    // Calculate total for percentage calculations
    final int total = statusCounts.values.fold(0, (sum, count) => sum + count);
    
    // Stack colored segments to create a pie chart-like view
    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        children: [
          // Placeholder circle
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Status segments (simplified representation)
          for (int i = 0; i < statuses.length; i++)
            _buildStatusSegment(context, statuses[i], i, statuses.length, total),
          
          // Center with total count
          Center(
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusSegment(
    BuildContext context,
    String status,
    int index,
    int totalStatuses,
    int totalTickets,
  ) {
    final Color statusColor = _getStatusColor(status);
    final count = statusCounts[status] ?? 0;
    final percentage = totalTickets > 0 ? count / totalTickets : 0;
    
    // For simplicity, divide the circle into equal segments
    // In a real app, you'd calculate accurate arc segments based on percentages
    final double startAngle = index * (360 / totalStatuses);
    final double sweepAngle = 360 / totalStatuses * percentage * totalStatuses;
    
    return Center(
      child: CustomPaint(
        size: const Size(150, 150),
        painter: _SegmentPainter(
          color: statusColor,
          startAngle: startAngle,
          sweepAngle: sweepAngle,
        ),
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'inProgress':
        return Colors.orange;
      case 'pendingUser':
        return Colors.purple;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
  
  String _getStatusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'inProgress':
        return 'In Progress';
      case 'pendingUser':
        return 'Pending User';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }
}

/// Custom painter for drawing segments of the circle
class _SegmentPainter extends CustomPainter {
  final Color color;
  final double startAngle;
  final double sweepAngle;
  
  _SegmentPainter({
    required this.color,
    required this.startAngle,
    required this.sweepAngle,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    );
    
    canvas.drawArc(
      rect,
      startAngle * (3.14159 / 180), // Convert to radians
      sweepAngle * (3.14159 / 180), // Convert to radians
      true,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(_SegmentPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.startAngle != startAngle ||
        oldDelegate.sweepAngle != sweepAngle;
  }
}