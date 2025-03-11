// lib/features/support/screens/admin_csr_management_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/csr_analytics_service.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/csr_performance_chart.dart';

class AdminCsrManagementScreen extends StatefulWidget {
  const AdminCsrManagementScreen({super.key});

  @override
  State<AdminCsrManagementScreen> createState() => _AdminCsrManagementScreenState();
}

class _AdminCsrManagementScreenState extends State<AdminCsrManagementScreen> with SingleTickerProviderStateMixin {
  final CsrAnalyticsService _analyticsService = CsrAnalyticsService();
  late TabController _tabController;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _csrPerformance = [];
  Map<String, dynamic> _teamAverage = {};
  int _selectedTimeRange = 7; // Default to 7 days
  
  final List<int> _timeRangeOptions = [7, 30, 90];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCsrData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCsrData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get CSR performance data
      final performance = await _analyticsService.getAllCsrPerformance(
        lastDays: _selectedTimeRange,
      );
      
      // Calculate team averages
      final teamAverage = _calculateTeamAverage(performance);
      
      setState(() {
        _csrPerformance = performance;
        _teamAverage = teamAverage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading CSR data: $e')),
        );
      }
    }
  }
  
  Map<String, dynamic> _calculateTeamAverage(List<Map<String, dynamic>> performance) {
    if (performance.isEmpty) {
      return {
        'total_tickets': 0,
        'resolved_tickets': 0,
        'resolution_rate': 0.0,
        'average_resolution_time': null,
      };
    }
    
    int totalTickets = 0;
    int resolvedTickets = 0;
    int totalResolutionMilliseconds = 0;
    int csrsWithResolutionTime = 0;
    
    for (final csr in performance) {
      totalTickets += csr['total_tickets'] as int;
      resolvedTickets += csr['resolved_tickets'] as int;
      
      final resolutionTime = csr['average_resolution_time'] as Duration?;
      if (resolutionTime != null) {
        totalResolutionMilliseconds += resolutionTime.inMilliseconds;
        csrsWithResolutionTime++;
      }
    }
    
    double resolutionRate = totalTickets > 0 ? resolvedTickets / totalTickets : 0;
    
    Duration? averageResolutionTime;
    if (csrsWithResolutionTime > 0) {
      averageResolutionTime = Duration(
        milliseconds: totalResolutionMilliseconds ~/ csrsWithResolutionTime,
      );
    }
    
    return {
      'total_tickets': totalTickets,
      'resolved_tickets': resolvedTickets,
      'resolution_rate': resolutionRate,
      'average_resolution_time': averageResolutionTime,
    };
  }
  
  Future<void> _createNewCsr() async {
    // Show dialog to create new CSR
    final Map<String, String>? formData = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _buildCreateCsrDialog(),
    );
    
    if (formData == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // First, create the auth account
      final AuthResponse response = await Supabase.instance.client.auth.signUp(
        email: formData['email']!,
        password: formData['password']!,
      );
      
      if (response.user == null) {
        throw Exception('Failed to create user account');
      }
      
      // Then, insert the user record with CSR role
      await Supabase.instance.client.from('users').insert({
        'id': response.user!.id,
        'email': formData['email'],
        'display_name': formData['displayName'],
        'role': 'csr',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Reload CSR data
      await _loadCsrData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSR account created successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating CSR account: $e')),
        );
      }
    }
  }
  
  Widget _buildCreateCsrDialog() {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final displayNameController = TextEditingController();
    final passwordController = TextEditingController();
    
    return AlertDialog(
      title: const Text('Create New CSR Account'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a display name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'email': emailController.text,
                'displayName': displayNameController.text,
                'password': passwordController.text,
              });
            }
          },
          child: const Text('CREATE'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CSR Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCsrData,
            tooltip: "Refresh Data",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Performance"),
            Tab(text: "CSR Accounts"),
          ],
        ),
      ),
      drawer: const AdminDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPerformanceTab(),
                _buildCsrAccountsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewCsr,
        tooltip: "Add CSR",
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildPerformanceTab() {
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
                      _loadCsrData();
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadCsrData,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Team performance summary
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Team Performance Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    childAspectRatio: 2.5,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildStatTile(
                        'Total Tickets',
                        _teamAverage['total_tickets'].toString(),
                        Icons.confirmation_number,
                      ),
                      _buildStatTile(
                        'Resolved Tickets',
                        _teamAverage['resolved_tickets'].toString(),
                        Icons.check_circle,
                      ),
                      _buildStatTile(
                        'Resolution Rate',
                        '${(_teamAverage['resolution_rate'] * 100).toStringAsFixed(1)}%',
                        Icons.trending_up,
                      ),
                      _buildStatTile(
                        'Avg. Resolution Time',
                        _formatDuration(_teamAverage['average_resolution_time']),
                        Icons.timer,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Individual CSR performance
          const Text(
            'Individual CSR Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          if (_csrPerformance.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('No CSR performance data available')),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _csrPerformance.length,
              itemBuilder: (context, index) {
                final csr = _csrPerformance[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: Text(
                      csr['display_name'] ?? csr['email'] ?? 'Unknown CSR',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Tickets: ${csr['total_tickets']} | Resolved: ${csr['resolved_tickets']} | Rate: ${(csr['resolution_rate'] * 100).toStringAsFixed(1)}%',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: CSRPerformanceChart(
                          csrPerformance: csr,
                          teamAverage: _teamAverage,
                        ),
                      ),
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              // View detailed CSR profile
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('CSR profile view coming soon')),
                              );
                            },
                            icon: const Icon(Icons.person),
                            label: const Text('View Profile'),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              // Reassign tickets
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ticket reassignment coming soon')),
                              );
                            },
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Reassign Tickets'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildCsrAccountsTab() {
    // Filter CSRs from performance data
    final csrAccounts = _csrPerformance.map((csr) {
      return {
        'id': csr['id'],
        'email': csr['email'],
        'display_name': csr['display_name'],
        'total_tickets': csr['total_tickets'],
        'resolution_rate': csr['resolution_rate'],
      };
    }).toList();
    
    return csrAccounts.isEmpty
        ? const Center(child: Text('No CSR accounts found'))
        : ListView.builder(
            itemCount: csrAccounts.length,
            itemBuilder: (context, index) {
              final csr = csrAccounts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      (csr['display_name'] as String? ?? csr['email'] as String? ?? 'U')[0].toUpperCase(),
                    ),
                  ),
                  title: Text(
                    csr['display_name'] as String? ?? 'No Display Name',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${csr['email'] as String? ?? 'No Email'}\nTickets: ${csr['total_tickets']} | Resolution Rate: ${((csr['resolution_rate'] as double) * 100).toStringAsFixed(1)}%',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showCsrActions(csr),
                  ),
                ),
              );
            },
          );
  }
  
  void _showCsrActions(Map<String, dynamic> csr) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit CSR Profile'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to CSR edit screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CSR profile editing coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Manage Permissions'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show permissions dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Permission management coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.password),
                title: const Text('Reset Password'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Reset password
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Disable Account'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmCsrDisable(csr);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _confirmCsrDisable(Map<String, dynamic> csr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Disable Account'),
        content: Text(
          'Are you sure you want to disable the CSR account for ${csr['display_name'] ?? csr['email']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account disable
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account disabling coming soon')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DISABLE'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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