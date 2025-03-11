// lib/features/support/screens/admin_csr_management_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/helpers.dart';
import '../../../services/csr_analytics_service.dart';
import '../../../services/support_ticket_service.dart';
import '../../../services/user_management_service.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/csr_performance_chart.dart';

class AdminCsrManagementScreen extends StatefulWidget {
  const AdminCsrManagementScreen({super.key});

  @override
  State<AdminCsrManagementScreen> createState() => _AdminCsrManagementScreenState();
}

class _AdminCsrManagementScreenState extends State<AdminCsrManagementScreen> with SingleTickerProviderStateMixin {
  final CsrAnalyticsService _analyticsService = CsrAnalyticsService();
  final SupportTicketService _ticketService = SupportTicketService();
  final UserManagementService _userService = UserManagementService();
  late TabController _tabController;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _csrPerformance = [];
  Map<String, dynamic> _teamAverage = {};
  int _selectedTimeRange = 7; // Default to 7 days
  List<Map<String, dynamic>> _unassignedTickets = [];
  List<Map<String, dynamic>> _csrAccounts = [];
  String? _selectedCsrId;
  
  final List<int> _timeRangeOptions = [7, 30, 90];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      
      // Get unassigned tickets
      final tickets = await _ticketService.getTicketCountsByStatus();
      
      // Get CSR accounts
      final csrAccounts = await _userService.getUsers(roleFilter: 'csr');
      
      setState(() {
        _csrPerformance = performance;
        _teamAverage = teamAverage;
        _unassignedTickets = []; // This would be populated with actual data
        _csrAccounts = csrAccounts;
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
  
  Future<void> _manageCsrPermissions(String csrId, String displayName) async {
    final Map<String, bool>? permissions = await showDialog<Map<String, bool>>(
      context: context,
      builder: (context) => _buildPermissionsDialog(csrId, displayName),
    );
    
    if (permissions == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implement permission update in user_management_service.dart
      await Future.delayed(const Duration(seconds: 1)); // Simulating API call
      
      // Reload CSR data
      await _loadCsrData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSR permissions updated successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating CSR permissions: $e')),
        );
      }
    }
  }
  
  Future<void> _reassignTickets(String fromCsrId, String toCsrId) async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implement ticket reassignment in support_ticket_service.dart
      await Future.delayed(const Duration(seconds: 1)); // Simulating API call
      
      // Reload CSR data
      await _loadCsrData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tickets reassigned successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reassigning tickets: $e')),
        );
      }
    }
  }
  
  Future<void> _deactivateCsr(String csrId) async {
    // Show confirmation dialog
    final bool confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deactivation'),
        content: const Text('Are you sure you want to deactivate this CSR account? They will no longer be able to access the system.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DEACTIVATE'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirmed) return;
    
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implement CSR deactivation in user_management_service.dart
      await Future.delayed(const Duration(seconds: 1)); // Simulating API call
      
      // Reload CSR data
      await _loadCsrData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSR account deactivated successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deactivating CSR account: $e')),
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
  
  Widget _buildPermissionsDialog(String csrId, String displayName) {
    // These would be loaded from the database in a real implementation
    final Map<String, bool> permissions = {
      'tickets.view': true,
      'tickets.assign': true,
      'tickets.resolve': true,
      'disputes.view': true,
      'disputes.resolve': false,
      'users.view': true,
      'users.manage': false,
      'content.moderate': true,
      'analytics.view': false,
    };
    
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text('Permissions for $displayName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ticket Management',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                CheckboxListTile(
                  title: const Text('View Tickets'),
                  value: permissions['tickets.view'],
                  onChanged: (value) {
                    setState(() => permissions['tickets.view'] = value!);
                  },
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('Assign Tickets'),
                  value: permissions['tickets.assign'],
                  onChanged: (value) {
                    setState(() => permissions['tickets.assign'] = value!);
                  },
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('Resolve Tickets'),
                  value: permissions['tickets.resolve'],
                  onChanged: (value) {
                    setState(() => permissions['tickets.resolve'] = value!);
                  },
                  dense: true,
                ),
                
                const Divider(),
                
                const Text(
                  'Dispute Resolution',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                CheckboxListTile(
                  title: const Text('View Disputes'),
                  value: permissions['disputes.view'],
                  onChanged: (value) {
                    setState(() => permissions['disputes.view'] = value!);
                  },
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('Resolve Disputes'),
                  value: permissions['disputes.resolve'],
                  onChanged: (value) {
                    setState(() => permissions['disputes.resolve'] = value!);
                  },
                  dense: true,
                ),
                
                const Divider(),
                
                const Text(
                  'User Management',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                CheckboxListTile(
                  title: const Text('View Users'),
                  value: permissions['users.view'],
                  onChanged: (value) {
                    setState(() => permissions['users.view'] = value!);
                  },
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('Manage Users'),
                  value: permissions['users.manage'],
                  onChanged: (value) {
                    setState(() => permissions['users.manage'] = value!);
                  },
                  dense: true,
                ),
                
                const Divider(),
                
                const Text(
                  'Content Moderation',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                CheckboxListTile(
                  title: const Text('Moderate Content'),
                  value: permissions['content.moderate'],
                  onChanged: (value) {
                    setState(() => permissions['content.moderate'] = value!);
                  },
                  dense: true,
                ),
                
                const Divider(),
                
                const Text(
                  'Analytics',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                CheckboxListTile(
                  title: const Text('View Analytics'),
                  value: permissions['analytics.view'],
                  onChanged: (value) {
                    setState(() => permissions['analytics.view'] = value!);
                  },
                  dense: true,
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
              onPressed: () => Navigator.pop(context, permissions),
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildReassignDialog(String fromCsrId, String fromCsrName) {
    String? selectedCsrId;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text('Reassign Tickets from $fromCsrName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select CSR to reassign tickets to:'),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Select CSR'),
                  value: selectedCsrId,
                  items: _csrAccounts
                      .where((csr) => csr['id'] != fromCsrId)
                      .map((csr) {
                    return DropdownMenuItem<String>(
                      value: csr['id'],
                      child: Text(csr['display_name'] ?? csr['email'] ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedCsrId = value);
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'This will reassign all open and in-progress tickets.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
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
              onPressed: selectedCsrId == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      _reassignTickets(fromCsrId, selectedCsrId!);
                    },
              child: const Text('REASSIGN'),
            ),
          ],
        );
      },
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
            Tab(text: "Workload Management"),
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
                _buildWorkloadManagementTab(),
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
          
          // Team performance summary with improved visualization
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
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Total Tickets',
                          _teamAverage['total_tickets'].toString(),
                          Icons.confirmation_number,
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildMetricCard(
                          'Resolved Tickets',
                          _teamAverage['resolved_tickets'].toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Resolution Rate',
                          '${(_teamAverage['resolution_rate'] * 100).toStringAsFixed(1)}%',
                          Icons.trending_up,
                          Colors.purple,
                        ),
                      ),
                      Expanded(
                        child: _buildMetricCard(
                          'Avg. Resolution Time',
                          _formatDuration(_teamAverage['average_resolution_time']),
                          Icons.timer,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  
                  // Add visualization of team performance over time
                  const SizedBox(height: 24),
                  const Text(
                    'Resolution Rate Trend',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Text('Resolution rate trend chart would appear here'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Individual CSR performance with ranking
          const Text(
            'Individual CSR Performance Ranking',
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
                final displayName = csr['display_name'] ?? csr['email'] ?? 'Unknown CSR';
                final resolutionRate = (csr['resolution_rate'] * 100).toStringAsFixed(1);
                final resolutionTime = _formatDuration(csr['average_resolution_time']);
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: _getPerformanceColor(csr['resolution_rate']),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: _buildMiniMetric('Tickets', '${csr['total_tickets']}'),
                        ),
                        Expanded(
                          child: _buildMiniMetric('Rate', '$resolutionRate%'),
                        ),
                        Expanded(
                          child: _buildMiniMetric('Avg Time', resolutionTime),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.expand_more),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // CSR Performance Chart (existing component)
                            CSRPerformanceChart(
                              csrPerformance: csr,
                              teamAverage: _teamAverage,
                            ),
                            
                            // Action buttons
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    _manageCsrPermissions(
                                      csr['id'],
                                      displayName,
                                    );
                                  },
                                  icon: const Icon(Icons.security),
                                  label: const Text('Permissions'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => _buildReassignDialog(
                                        csr['id'],
                                        displayName,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.swap_horiz),
                                  label: const Text('Reassign Tickets'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    // Navigate to detailed CSR profile
                                  },
                                  icon: const Icon(Icons.analytics),
                                  label: const Text('Detailed Stats'),
                                ),
                              ],
                            ),
                          ],
                        ),
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
    return Column(
      children: [
        // Search and filter bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search CSRs',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  // Show filter options
                },
              ),
            ),
            onChanged: (value) {
              // Filter CSRs based on search
            },
          ),
        ),
        
        // CSR accounts list
        Expanded(
          child: _csrAccounts.isEmpty
              ? const Center(child: Text('No CSR accounts found'))
              : ListView.builder(
                  itemCount: _csrAccounts.length,
                  itemBuilder: (context, index) {
                    final csr = _csrAccounts[index];
                    final csrName = csr['display_name'] ?? csr['email'] ?? 'Unknown';
                    final isActive = true; // This should be determined from the CSR's status
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive ? Colors.green : Colors.grey,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          csrName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isActive ? null : Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          'Email: ${csr['email'] ?? 'N/A'}\n'
                          'Created: ${formatDate(DateTime.parse(csr['created_at']))}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                // Navigate to edit profile screen
                                break;
                              case 'permissions':
                                _manageCsrPermissions(csr['id'], csrName);
                                break;
                              case 'reassign':
                                showDialog(
                                  context: context,
                                  builder: (context) => _buildReassignDialog(csr['id'], csrName),
                                );
                                break;
                              case 'deactivate':
                                _deactivateCsr(csr['id']);
                                break;
                              case 'reset_password':
                                // Show reset password dialog
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit Profile'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'permissions',
                              child: Row(
                                children: [
                                  Icon(Icons.security),
                                  SizedBox(width: 8),
                                  Text('Permissions'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'reassign',
                              child: Row(
                                children: [
                                  Icon(Icons.swap_horiz),
                                  SizedBox(width: 8),
                                  Text('Reassign Tickets'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'reset_password',
                              child: Row(
                                children: [
                                  Icon(Icons.password),
                                  SizedBox(width: 8),
                                  Text('Reset Password'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'deactivate',
                              child: Row(
                                children: [
                                  Icon(Icons.block, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Deactivate', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWorkloadManagementTab() {
    return Column(
      children: [
        // Workload overview
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workload Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Unassigned Tickets',
                          '12', // Replace with actual data
                          Icons.assignment_late,
                          Colors.orange,
                        ),
                      ),
                      Expanded(
                        child: _buildMetricCard(
                          'High Priority',
                          '5', // Replace with actual data
                          Icons.priority_high,
                          Colors.red,
                        ),
                      ),
                      Expanded(
                        child: _buildMetricCard(
                          'Avg. per CSR',
                          '8', // Replace with actual data
                          Icons.people,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  
                  // Workload distribution chart
                  const SizedBox(height: 24),
                  const Text(
                    'Workload Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Text('Workload distribution chart would appear here'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // CSR selection for ticket assignment
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Ticket Assignment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              DropdownButton<String>(
                hint: const Text('Select CSR'),
                value: _selectedCsrId,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCsrId = newValue;
                  });
                },
                items: _csrAccounts.map<DropdownMenuItem<String>>((Map<String, dynamic> csr) {
                  return DropdownMenuItem<String>(
                    value: csr['id'],
                    child: Text(csr['display_name'] ?? csr['email'] ?? 'Unknown'),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Unassigned tickets list
        Expanded(
          child: ListView.builder(
            itemCount: 5, // Replace with actual unassigned tickets count
            itemBuilder: (context, index) {
              // This would be populated with actual ticket data
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: index % 3 == 0 ? Colors.red : (index % 3 == 1 ? Colors.orange : Colors.green),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text('Ticket #${1000 + index}'),
                  subtitle: Text(
                    'Priority: ${index % 3 == 0 ? 'High' : (index % 3 == 1 ? 'Medium' : 'Low')}\n'
                    'Created: ${formatDate(DateTime.now().subtract(Duration(hours: index * 3)))}',
                  ),
                  trailing: _selectedCsrId == null
                      ? null
                      : TextButton(
                          onPressed: () {
                            // Assign ticket to selected CSR
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ticket assigned successfully')),
                            );
                          },
                          child: const Text('Assign'),
                        ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMiniMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Color _getPerformanceColor(double resolutionRate) {
    if (resolutionRate >= 0.8) {
      return Colors.green;
    } else if (resolutionRate >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
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
}