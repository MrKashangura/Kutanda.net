// lib/screens/csr_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/csr_analytics_service.dart';
import '../services/user_management_service.dart';
import '../utils/helpers.dart';
import '../widgets/csr_drawer.dart';
import '../widgets/csr_performance_chart.dart';
import '../widgets/resolution_time_chart.dart';
import '../widgets/ticket_distribution_chart.dart';

class CSRAnalyticsScreen extends StatefulWidget {
  const CSRAnalyticsScreen({super.key});

  @override
  State<CSRAnalyticsScreen> createState() => _CSRAnalyticsScreenState();
}

class _CSRAnalyticsScreenState extends State<CSRAnalyticsScreen> {
  final CsrAnalyticsService _analyticsService = CsrAnalyticsService();
  final UserManagementService _userService = UserManagementService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  String _timeRange = '7'; // Default to 7 days
  String? _currentCsrId;
  
  // Analytics data
  Map<String, dynamic> _ticketStats = {};
  Map<String, dynamic> _resolutionTimeStats = {};
  List<Map<String, dynamic>> _commonIssueTypes = [];
  Map<String, dynamic> _csrPerformance = {};
  List<Map<String, dynamic>> _allCsrPerformance = [];
  Map<int, int> _ticketVolumeByHour = {};
  Map<String, dynamic> _userRegistrationStats = {};
  Map<String, dynamic> _satisfactionStats = {};

  @override
  void initState() {
    super.initState();
    _getCurrentCsrId();
    _loadAnalyticsData();
  }
  
  Future<void> _getCurrentCsrId() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentCsrId = user.id;
      });
    }
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    
    try {
      final days = int.tryParse(_timeRange);
      
      // Load all analytics data in parallel for better performance
      final futureTicketStats = _analyticsService.getTicketStats(lastDays: days);
      final futureResolutionTimeStats = _analyticsService.getResolutionTimeStats(lastDays: days);
      final futureCommonIssueTypes = _analyticsService.getCommonIssueTypes(lastDays: days);
      final futureAllCsrPerformance = _analyticsService.getAllCsrPerformance(lastDays: days);
      final futureTicketVolumeByHour = _analyticsService.getTicketVolumeByHour(lastDays: days);
      final futureUserRegistrationStats = _userService.getUserRegistrationStats(lastDays: days);
      final futureSatisfactionStats = _analyticsService.getCustomerSatisfactionStats(lastDays: days);
      
      // Load CSR-specific performance if ID is available
      Future<Map<String, dynamic>>? futureCsrPerformance;
      if (_currentCsrId != null) {
        futureCsrPerformance = _analyticsService.getCsrPerformance(_currentCsrId!, lastDays: days);
      }
      
      // Wait for all futures to complete
      final results = await Future.wait([
        futureTicketStats,
        futureResolutionTimeStats,
        futureCommonIssueTypes,
        futureAllCsrPerformance,
        futureTicketVolumeByHour,
        futureUserRegistrationStats,
        futureSatisfactionStats,
      ]);
      
      Map<String, dynamic> csrPerformance = {};
      if (futureCsrPerformance != null) {
        csrPerformance = await futureCsrPerformance;
      }
      
      setState(() {
        _ticketStats = results[0] as Map<String, dynamic>;
        _resolutionTimeStats = results[1] as Map<String, dynamic>;
        _commonIssueTypes = results[2] as List<Map<String, dynamic>>;
        _allCsrPerformance = results[3] as List<Map<String, dynamic>>;
        _ticketVolumeByHour = results[4] as Map<int, int>;
        _userRegistrationStats = results[5] as Map<String, dynamic>;
        _satisfactionStats = results[6] as Map<String, dynamic>;
        _csrPerformance = csrPerformance;
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
      return Scaffold(
        appBar: AppBar(title: const Text("Analytics Dashboard")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics Dashboard"),
        actions: [
          // Time range selector
          DropdownButton<String>(
            value: _timeRange,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            style: const TextStyle(color: Colors.white),
            underline: Container(height: 0),
            dropdownColor: Theme.of(context).primaryColor,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _timeRange = newValue;
                });
                _loadAnalyticsData();
              }
            },
            items: const [
              DropdownMenuItem(value: '7', child: Text('Last 7 Days')),
              DropdownMenuItem(value: '30', child: Text('Last 30 Days')),
              DropdownMenuItem(value: '90', child: Text('Last 90 Days')),
              DropdownMenuItem(value: '365', child: Text('Last Year')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      drawer: const CSRDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key metrics summary
            _buildKeyMetricsSummary(),
            
            const SizedBox(height: 24),
            
            // Ticket distribution chart
            const Text(
              'Ticket Distribution by Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: TicketDistributionChart(
                statusCounts: _ticketStats['tickets_by_status'] ?? {},
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Resolution time chart
            const Text(
              'Average Resolution Time by Priority',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: ResolutionTimeChart(
                resolutionTimes: _resolutionTimeStats['by_priority'] ?? {},
              ),
            ),
            
            const SizedBox(height: 24),
            
            // CSR performance comparison
            const Text(
              'CSR Performance Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: _buildCsrPerformanceTable(),
            ),
            
            const SizedBox(height: 24),
            
            // Your performance (if available)
            if (_csrPerformance.isNotEmpty) ...[
              const Text(
                'Your Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 250,
                child: CSRPerformanceChart(
                  csrPerformance: _csrPerformance,
                  teamAverage: _calculateTeamAverages(),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Common issue types
            const Text(
              'Common Issue Types',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildCommonIssuesTable(),
            
            const SizedBox(height: 24),
            
            // Customer satisfaction
            const Text(
              'Customer Satisfaction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildSatisfactionSummary(),
            
            const SizedBox(height: 24),
            
            // Ticket volume by hour
            const Text(
              'Ticket Volume by Hour',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: _buildTicketVolumeByHourChart(),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildKeyMetricsSummary() {
    final totalTickets = _ticketStats['total_tickets'] ?? 0;
    final resolvedTickets = _ticketStats['tickets_by_status']?['resolved'] ?? 0;
    final openTickets = _ticketStats['tickets_by_status']?['open'] ?? 0;
    final inProgressTickets = _ticketStats['tickets_by_status']?['inProgress'] ?? 0;
    final averageResolutionTime = _ticketStats['average_resolution_time'] as Duration?;
    
    // Calculate resolution rate
    double resolutionRate = 0;
    if (totalTickets > 0) {
      resolutionRate = resolvedTickets / totalTickets * 100;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(
              Colors.grey.red,
              Colors.grey.green,
              Colors.grey.blue,
              0.2
            ),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Metrics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCard(
                icon: Icons.confirmation_number,
                title: 'Total Tickets',
                value: totalTickets.toString(),
                color: Colors.blue,
              ),
              _buildMetricCard(
                icon: Icons.check_circle,
                title: 'Resolution Rate',
                value: '${resolutionRate.toStringAsFixed(1)}%',
                color: Colors.green,
              ),
              _buildMetricCard(
                icon: Icons.timer,
                title: 'Avg. Resolution Time',
                value: _formatDuration(averageResolutionTime),
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCard(
                icon: Icons.inbox,
                title: 'Open Tickets',
                value: openTickets.toString(),
                color: Colors.orange,
              ),
              _buildMetricCard(
                icon: Icons.pending_actions,
                title: 'In Progress',
                value: inProgressTickets.toString(),
                color: Colors.amber,
              ),
              _buildMetricCard(
                icon: Icons.done_all,
                title: 'Resolved',
                value: resolvedTickets.toString(),
                color: Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCsrPerformanceTable() {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('CSR')),
            DataColumn(label: Text('Tickets')),
            DataColumn(label: Text('Resolution Rate')),
            DataColumn(label: Text('Avg. Time')),
          ],
          rows: _allCsrPerformance.map((csr) {
            final name = csr['display_name'] ?? csr['email'] ?? 'Unknown';
            final totalTickets = csr['total_tickets'] ?? 0;
            final resolutionRate = csr['resolution_rate'] ?? 0.0;
            final resolutionTime = csr['average_resolution_time'] as Duration?;
            
            return DataRow(
              cells: [
                DataCell(Text(name)),
                DataCell(Text(totalTickets.toString())),
                DataCell(Text('${(resolutionRate * 100).toStringAsFixed(1)}%')),
                DataCell(Text(_formatDuration(resolutionTime))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Map<String, dynamic> _calculateTeamAverages() {
  if (_allCsrPerformance.isEmpty) {
    return {
      'total_tickets': 0,
      'resolution_rate': 0.0,
      'average_resolution_time': null,
    };
  }
  
  int totalTickets = 0;
  int resolvedTickets = 0;
  List<Duration> resolutionTimes = [];
  
  for (final csr in _allCsrPerformance) {
    totalTickets += (csr['total_tickets'] as num?)?.toInt() ?? 0;
    resolvedTickets += (csr['resolved_tickets'] as num?)?.toInt() ?? 0;
    
    if (csr['average_resolution_time'] != null) {
      resolutionTimes.add(csr['average_resolution_time'] as Duration);
    }
  }
  
  double resolutionRate = totalTickets > 0 ? resolvedTickets / totalTickets : 0;
  
  Duration? averageResolutionTime;
  if (resolutionTimes.isNotEmpty) {
    final totalMilliseconds = resolutionTimes
        .map((d) => d.inMilliseconds)
        .reduce((a, b) => a + b);
    averageResolutionTime = Duration(
        milliseconds: totalMilliseconds ~/ resolutionTimes.length);
  }
  
  return {
    'total_tickets': totalTickets,
    'resolution_rate': resolutionRate,
    'average_resolution_time': averageResolutionTime,
  };
}
  
  Widget _buildCommonIssuesTable() {
    if (_commonIssueTypes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No data available'),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _commonIssueTypes.map((issue) {
            final type = issue['type'] as String;
            final count = issue['count'] as int;
            final percentage = issue['percentage'] as double;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(type.capitalize()),
                  ),
                  Expanded(
                    flex: 7,
                    child: Stack(
                      children: [
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage / 100,
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                '$count (${percentage.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildSatisfactionSummary() {
    final averageRating = _satisfactionStats['average_rating'] ?? 0.0;
    final ratingCounts = _satisfactionStats['rating_counts'] as Map<String, dynamic>? ?? {};
    final totalRatings = _satisfactionStats['total_ratings'] ?? 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Average Satisfaction Rating',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 24),
                    ),
                    Text(
                      'Based on ${ratingCounts.values.fold<int>(0, (sum, count) => sum + (count as int))} ratings',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Rating distribution
            ...['5', '4', '3', '2', '1'].map((rating) {
              final count = ratingCounts[rating] ?? 0;
              final percentage = totalRatings > 0 ? (count / totalRatings) * 100 : 0.0;
              
              // Select color based on rating
              Color ratingColor;
              switch (rating) {
                case '5':
                case '4':
                  ratingColor = Colors.green;
                  break;
                case '3':
                  ratingColor = Colors.amber;
                  break;
                default:
                  ratingColor = Colors.red;
              }
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Row(
                        children: [
                          Text(
                            rating,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        children: [
                          // Background bar
                          Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          // Value bar
                          FractionallySizedBox(
                            widthFactor: percentage / 100,
                            child: Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: ratingColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${count.toString().padLeft(2)} (${percentage.toStringAsFixed(1)}%)',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            const SizedBox(height: 20),
            
            // Legend row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 12, height: 12, color: Colors.green),
                const SizedBox(width: 4),
                const Text('Good (4-5)'),
                const SizedBox(width: 16),
                Container(width: 12, height: 12, color: Colors.amber),
                const SizedBox(width: 4),
                const Text('Average (3)'),
                const SizedBox(width: 16),
                Container(width: 12, height: 12, color: Colors.red),
                const SizedBox(width: 4),
                const Text('Poor (1-2)'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTicketVolumeByHourChart() {
    if (_ticketVolumeByHour.isEmpty) {
      return const Center(
        child: Text('No ticket volume data available'),
      );
    }
    
    // Find the max value for scaling the bars
    int maxVolume = 0;
    _ticketVolumeByHour.values.forEach((value) {
      if (value > maxVolume) maxVolume = value;
    });
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hourly Ticket Distribution',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Y-axis labels
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$maxVolume'),
                      Text('${(maxVolume / 2).round()}'),
                      const Text('0'),
                    ],
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Bars
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(24, (hour) {
                        final count = _ticketVolumeByHour[hour] ?? 0;
                        final double height = maxVolume > 0 
                            ? (count / maxVolume) * 160
                            : 0;
                            
                        // Determine time of day for color coding
                        Color barColor;
                        if (hour >= 9 && hour < 17) {
                          barColor = Colors.blue; // Business hours
                        } else if ((hour >= 17 && hour < 22) || (hour >= 6 && hour < 9)) {
                          barColor = Colors.orange; // Evening/Morning
                        } else {
                          barColor = Colors.purple; // Night
                        }
                        
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Bar with count on hover
                            Tooltip(
                              message: 'Hour $hour:00: $count tickets',
                              child: Container(
                                width: 10,
                                height: height > 0 ? height : 1,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // X-axis label
                            Text(hour % 3 == 0 ? '${hour.toString().padLeft(2, '0')}:00' : ''),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 12, height: 12, color: Colors.blue),
                const SizedBox(width: 4),
                const Text('Business Hours (9-17)'),
                const SizedBox(width: 16),
                Container(width: 12, height: 12, color: Colors.orange),
                const SizedBox(width: 4),
                const Text('Morning/Evening (6-9, 17-22)'),
                const SizedBox(width: 16),
                Container(width: 12, height: 12, color: Colors.purple),
                const SizedBox(width: 4),
                const Text('Night (22-6)'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}