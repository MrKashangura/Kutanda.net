// lib/features/support/screens/enhanced_admin_user_management_screen.dart
import 'package:flutter/material.dart';

import '../../../core/utils/helpers.dart';
import '../widgets/admin_drawer.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = false;
  bool _initialLoadCompleted = false;
  List<Map<String, dynamic>> _users = [];
  String? _roleFilter;
  bool _showReportedOnly = false;
  bool _showSuspendedOnly = false;
  int _currentPage = 0;
  final int _pageSize = 20;
  List<bool> _selectedUsers = [];
  
  final List<String> _roleOptions = ['All', 'buyer', 'seller', 'csr', 'admin'];

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
      // Mock data for demonstration purposes
      await Future.delayed(const Duration(milliseconds: 500));
      
      final users = [
        {
          'id': '1',
          'email': 'johndoe@example.com',
          'display_name': 'John Doe',
          'role': 'buyer',
          'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          'is_reported': false,
          'is_suspended': false,
          'is_banned': false,
        },
        {
          'id': '2',
          'email': 'janedoe@example.com',
          'display_name': 'Jane Doe',
          'role': 'seller',
          'created_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
          'is_reported': false,
          'is_suspended': false,
          'is_banned': false,
        },
        {
          'id': '3',
          'email': 'support1@kutanda.com',
          'display_name': 'Support Agent 1',
          'role': 'csr',
          'created_at': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
          'is_reported': false,
          'is_suspended': false,
          'is_banned': false,
        },
        {
          'id': '4',
          'email': 'admin@kutanda.com',
          'display_name': 'Admin User',
          'role': 'admin',
          'created_at': DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
          'is_reported': false,
          'is_suspended': false,
          'is_banned': false,
        },
        {
          'id': '5',
          'email': 'reported@example.com',
          'display_name': 'Reported User',
          'role': 'buyer',
          'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
          'is_reported': true,
          'is_suspended': false,
          'is_banned': false,
        },
        {
          'id': '6',
          'email': 'suspended@example.com',
          'display_name': 'Suspended User',
          'role': 'seller',
          'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          'is_reported': false,
          'is_suspended': true,
          'is_banned': false,
        },
        {
          'id': '7',
          'email': 'banned@example.com',
          'display_name': 'Banned User',
          'role': 'buyer',
          'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          'is_reported': true,
          'is_suspended': false,
          'is_banned': true,
        },
      ];

      // Apply filtering
      var filteredUsers = List<Map<String, dynamic>>.from(users);
      
      if (_searchController.text.isNotEmpty) {
        final searchQuery = _searchController.text.toLowerCase();
        filteredUsers = filteredUsers.where((user) {
          return user['email'].toString().toLowerCase().contains(searchQuery) ||
                 (user['display_name']?.toString().toLowerCase() ?? '').contains(searchQuery);
        }).toList();
      }
      
      if (_roleFilter != null && _roleFilter != 'All') {
        filteredUsers = filteredUsers.where((user) => user['role'] == _roleFilter).toList();
      }
      
      if (_showReportedOnly) {
        filteredUsers = filteredUsers.where((user) => user['is_reported'] == true).toList();
      }
      
      if (_showSuspendedOnly) {
        filteredUsers = filteredUsers.where((user) => user['is_suspended'] == true).toList();
      }
      
      // Apply pagination (not really needed for this small dataset but included for completeness)
      final start = _currentPage * _pageSize;
      final end = start + _pageSize;
      
      if (start < filteredUsers.length) {
        final paginatedUsers = filteredUsers.sublist(
          start, 
          end > filteredUsers.length ? filteredUsers.length : end
        );
        
        setState(() {
          _users = paginatedUsers;
          _selectedUsers = List.generate(paginatedUsers.length, (_) => false);
          _isLoading = false;
          _initialLoadCompleted = true;
        });
      } else {
        setState(() {
          _users = [];
          _selectedUsers = [];
          _isLoading = false;
          _initialLoadCompleted = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _initialLoadCompleted = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }
  
  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _roleFilter = null;
      _showReportedOnly = false;
      _showSuspendedOnly = false;
      _currentPage = 0;
    });
    _loadUsers();
  }
  
  Future<void> _performBulkAction(String action) async {
    // Get list of selected user IDs
    final List<String> selectedIds = [];
    for (int i = 0; i < _selectedUsers.length; i++) {
      if (_selectedUsers[i]) {
        selectedIds.add(_users[i]['id']);
      }
    }
    
    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users selected')),
      );
      return;
    }
    
    // Show confirmation dialog
    final bool confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Bulk $action'),
        content: Text('Are you sure you want to $action ${selectedIds.length} selected users?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirmed) return;

    setState(() => _isLoading = true);
    
    try {
      // Add a small delay to simulate processing
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulate successful action
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bulk $action completed successfully for ${selectedIds.length} users')),
      );
      
      // For demonstration, we'll update our local state
      if (action == 'suspend') {
        for (int i = 0; i < _users.length; i++) {
          if (_selectedUsers[i]) {
            _users[i]['is_suspended'] = true;
          }
        }
      } else if (action == 'unsuspend') {
        for (int i = 0; i < _users.length; i++) {
          if (_selectedUsers[i]) {
            _users[i]['is_suspended'] = false;
          }
        }
      } else if (action == 'ban') {
        for (int i = 0; i < _users.length; i++) {
          if (_selectedUsers[i]) {
            _users[i]['is_banned'] = true;
          }
        }
      } else if (action == 'clear_flags') {
        for (int i = 0; i < _users.length; i++) {
          if (_selectedUsers[i]) {
            _users[i]['is_reported'] = false;
            _users[i]['is_suspended'] = false;
            _users[i]['is_banned'] = false;
          }
        }
      }
      
      setState(() {
        _isLoading = false;
        _selectedUsers = List.generate(_users.length, (_) => false);
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error performing bulk action: $e')),
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
            tooltip: "Refresh Data",
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          _buildFilterSection(),
          _buildBulkActionBar(),
          Expanded(
            child: _isLoading && !_initialLoadCompleted
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text("No users found"))
                    : _buildUserList(),
          ),
          _buildPaginationControls(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to user creation screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User creation coming soon')),
          );
        },
        tooltip: "Add User",
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Users',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadUsers();
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _loadUsers(),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _roleFilter,
                hint: const Text('Role'),
                onChanged: (String? newValue) {
                  setState(() {
                    _roleFilter = newValue;
                    _currentPage = 0; // Reset to first page
                  });
                  _loadUsers();
                },
                items: _roleOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value == 'All' ? null : value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Reported Only'),
                  value: _showReportedOnly,
                  onChanged: (value) {
                    setState(() {
                      _showReportedOnly = value ?? false;
                      _currentPage = 0; // Reset to first page
                    });
                    _loadUsers();
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Suspended Only'),
                  value: _showSuspendedOnly,
                  onChanged: (value) {
                    setState(() {
                      _showSuspendedOnly = value ?? false;
                      _currentPage = 0; // Reset to first page
                    });
                    _loadUsers();
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
              ),
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionBar() {
    final bool anySelected = _selectedUsers.contains(true);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
      child: Row(
        children: [
          Checkbox(
            value: _selectedUsers.isNotEmpty &&
                _selectedUsers.every((selected) => selected),
            tristate: _selectedUsers.contains(true) &&
                !_selectedUsers.every((selected) => selected),
            onChanged: (value) {
              setState(() {
                _selectedUsers = List<bool>.filled(
                  _selectedUsers.length,
                  value ?? false,
                );
              });
            },
          ),
          Text(
            '${_selectedUsers.where((selected) => selected).length} selected',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (anySelected) ...[
            _buildActionButton('Suspend', Icons.block, () => _performBulkAction('suspend')),
            _buildActionButton('Unsuspend', Icons.check_circle, () => _performBulkAction('unsuspend')),
            _buildActionButton('Ban', Icons.delete_forever, () => _performBulkAction('ban')),
            _buildActionButton('Clear Flags', Icons.cleaning_services, () => _performBulkAction('clear_flags')),
          ],
        ],
      ),
    );
  }
  
  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final bool isSelected = _selectedUsers[index];
        
        // Determine user status indicators
        final bool isReported = user['is_reported'] == true;
        final bool isSuspended = user['is_suspended'] == true;
        final bool isBanned = user['is_banned'] == true;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: isSelected ? 3 : 1,
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  _selectedUsers[index] = value ?? false;
                });
              },
            ),
            title: Row(
              children: [
                Text(
                  user['display_name'] ?? user['email'] ?? 'Unknown User',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (isReported)
                  _buildStatusChip('Reported', Colors.purple),
                if (isSuspended)
                  _buildStatusChip('Suspended', Colors.orange),
                if (isBanned)
                  _buildStatusChip('Banned', Colors.red),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${user['email'] ?? 'N/A'}'),
                Text(
                  'Role: ${user['role'] ?? 'N/A'} | Created: ${formatDate(DateTime.parse(user['created_at']))}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.navigate_next),
              onPressed: () {
                // For demonstration, we'll show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Viewing details for ${user['display_name'] ?? user['email']}')),
                );
              },
            ),
            onTap: () {
              setState(() {
                _selectedUsers[index] = !isSelected;
              });
            },
            onLongPress: () {
              // For demonstration, we'll show a snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Viewing details for ${user['display_name'] ?? user['email']}')),
              );
            },
            isThreeLine: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        );
      },
    );
  }
  
  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    // Calculate total pages (for this demo, we'll just use 3 pages)
    final int totalPages = 3;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _loadUsers();
                  }
                : null,
          ),
          Text(
            'Page ${_currentPage + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages - 1
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _loadUsers();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}