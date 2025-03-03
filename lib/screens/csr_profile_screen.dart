// lib/screens/csr_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/session_service.dart';
import '../widgets/csr_drawer.dart';
import 'login_screen.dart';

class CSRProfileScreen extends StatefulWidget {
  const CSRProfileScreen({super.key});

  @override
  State<CSRProfileScreen> createState() => _CSRProfileScreenState();
}

class _CSRProfileScreenState extends State<CSRProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _csrStats;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }
      
      // Get user profile data
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      
      // Get CSR performance stats
      final resolvedTickets = await _supabase
          .from('support_tickets')
          .select('id')
          .eq('assigned_csr_id', user.id)
          .eq('status', 'resolved')
          .count();
      
      final totalTickets = await _supabase
          .from('support_tickets')
          .select('id')
          .eq('assigned_csr_id', user.id)
          .count();
      
      final disputes = await _supabase
          .from('dispute_tickets')
          .select('id, resolved_at')
          .eq('moderator_id', user.id)
          .count();
          
      final resolvedCount = resolvedTickets.count ?? 0;
      final totalCount = totalTickets.count ?? 0;
      final disputeCount = disputes.count ?? 0;
          
      final csrStats = {
        'resolved_tickets': resolvedCount,
        'total_tickets': totalCount,
        'resolution_rate': totalCount > 0 ? resolvedCount / totalCount : 0.0,
        'disputes_handled': disputeCount,
      };
      
      if (mounted) {
        setState(() {
          _userData = userData;
          _csrStats = csrStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile data: $e')),
        );
      }
    }
  }
  
  Future<void> _logout() async {
    setState(() => _isLoading = true);
    
    try {
      await _supabase.auth.signOut();
      await SessionService.clearSession();
      
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile & Settings")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final name = _userData?['display_name'] ?? 'CSR';
    final email = _userData?['email'] ?? '';
    final phone = _userData?['phone'] ?? 'Not provided';
    final joinDate = _userData?['created_at'] != null
        ? DateTime.parse(_userData!['created_at'])
        : null;
        
    final resolvedTickets = _csrStats?['resolved_tickets'] ?? 0;
    final totalTickets = _csrStats?['total_tickets'] ?? 0;
    final resolutionRate = _csrStats?['resolution_rate'] ?? 0.0;
    final disputesHandled = _csrStats?['disputes_handled'] ?? 0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile & Settings"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: const CSRDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile header with avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'C',
                style: const TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Customer Support Representative',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Contact Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: Text(email),
                      dense: true,
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('Phone'),
                      subtitle: Text(phone),
                      dense: true,
                    ),
                    if (joinDate != null)
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Joined'),
                        subtitle: Text(
                          '${joinDate.day}/${joinDate.month}/${joinDate.year}',
                        ),
                        dense: true,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Performance Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Performance Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Stats in a grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Tickets',
                            totalTickets.toString(),
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            'Resolved',
                            resolvedTickets.toString(),
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Resolution Rate',
                            '${(resolutionRate * 100).toStringAsFixed(1)}%',
                            Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            'Disputes Handled',
                            disputesHandled.toString(),
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Settings Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Notification Settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to notification settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notification settings not implemented yet')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text('Change Password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to change password screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Change password not implemented yet')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.color_lens),
                      title: const Text('Theme Preferences'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to theme settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Theme settings not implemented yet')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
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