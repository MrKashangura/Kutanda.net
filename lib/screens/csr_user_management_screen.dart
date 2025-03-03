// lib/screens/csr_user_management_screen.dart
import 'package:flutter/material.dart';

import '../services/user_management_service.dart';
import '../widgets/csr_drawer.dart';

class CSRUserManagementScreen extends StatefulWidget {
  const CSRUserManagementScreen({super.key});

  @override
  State<CSRUserManagementScreen> createState() => _CSRUserManagementScreenState();
}

class _CSRUserManagementScreenState extends State<CSRUserManagementScreen> {
  final UserManagementService _userService = UserManagementService();
  // Removed unused _supabase field
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';
  String? _roleFilter;
  bool _onlyReported = false;
  
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    try {
      final users = await _userService.getUsers(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        roleFilter: _roleFilter,
        onlyReported: _onlyReported ? true : null,
      );
      
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const CSRDrawer(),
      body: Column(
        children: [
          // Search and filter area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _loadUsers();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Filter button
                PopupMenuButton<String?>(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter',
                  onSelected: (value) {
                    setState(() {
                      _roleFilter = value;
                    });
                    _loadUsers();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: null,
                      child: Text('All Roles'),
                    ),
                    const PopupMenuItem(
                      value: 'buyer',
                      child: Text('Buyers'),
                    ),
                    const PopupMenuItem(
                      value: 'seller',
                      child: Text('Sellers'),
                    ),
                    const PopupMenuItem(
                      value: 'admin',
                      child: Text('Admins'),
                    ),
                    const PopupMenuItem(
                      value: 'csr',
                      child: Text('CSRs'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Filter chip for reported users
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Reported Users Only'),
                  selected: _onlyReported,
                  onSelected: (selected) {
                    setState(() {
                      _onlyReported = selected;
                    });
                    _loadUsers();
                  },
                ),
                const SizedBox(width: 8),
                if (_roleFilter != null)
                  Chip(
                    label: Text('Role: ${_roleFilter!}'),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () {
                      setState(() {
                        _roleFilter = null;
                      });
                      _loadUsers();
                    },
                  ),
              ],
            ),
          ),
          
          // Users list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text('No users found'))
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final bool isReported = user['is_reported'] == true;
                          final bool isSuspended = user['is_suspended'] == true;
                          final bool isBanned = user['is_banned'] == true;
                          
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                (user['email'] as String?)?.isNotEmpty == true
                                    ? (user['email'] as String)[0].toUpperCase()
                                    : 'U',
                              ),
                            ),
                            title: Text(user['display_name'] ?? user['email'] ?? 'Unknown User'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['email'] ?? 'No email'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        // Fixed deprecated withOpacity use
                                        color: Colors.blue.withAlpha(51),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        user['role'] ?? 'unknown',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    if (isReported || isSuspended || isBanned) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          // Fixed deprecated withOpacity use
                                          color: Colors.red.withAlpha(51),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isBanned ? 'BANNED' : isSuspended ? 'SUSPENDED' : 'REPORTED',
                                          style: const TextStyle(fontSize: 12, color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // View user details
                              _showUserDetailsDialog(user);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  void _showUserDetailsDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(user['display_name'] ?? user['email'] ?? 'User Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Email'),
                  subtitle: Text(user['email'] ?? 'No email'),
                  leading: const Icon(Icons.email),
                ),
                ListTile(
                  title: const Text('Role'),
                  subtitle: Text(user['role'] ?? 'Unknown'),
                  leading: const Icon(Icons.person),
                ),
                ListTile(
                  title: const Text('Status'),
                  subtitle: Text(_getUserStatusText(user)),
                  leading: const Icon(Icons.security),
                ),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Actions:', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (user['is_reported'] == true || user['is_suspended'] == true)
              ElevatedButton(
                onPressed: () {
                  // Take moderation action
                  Navigator.pop(context);
                  _showModerationActionDialog(user);
                },
                child: const Text('Take Action'),
              ),
          ],
        );
      },
    );
  }
  
  String _getUserStatusText(Map<String, dynamic> user) {
    if (user['is_banned'] == true) return 'Banned';
    if (user['is_suspended'] == true) return 'Suspended';
    if (user['is_reported'] == true) return 'Reported';
    return 'Active';
  }
  
  void _showModerationActionDialog(Map<String, dynamic> user) {
    // Placeholder for moderation action dialog
    // Would implement real actions here in a production app
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Moderation Actions'),
          content: const Text('Moderation actions would be implemented here'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}