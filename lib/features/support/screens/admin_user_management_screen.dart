// lib/features/support/screens/admin_user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/helpers.dart';
import '../../../services/user_management_service.dart';
import '../widgets/admin_drawer.dart';
import 'admin_user_detail_screen.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final UserManagementService _userService = UserManagementService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String? _roleFilter;
  bool _showReportedOnly = false;
  bool _showSuspendedOnly = false;
  int _currentPage = 0;
  int _pageSize = 20;
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
      final users = await _userService.getUsers(
        searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
        roleFilter: _roleFilter == 'All' ? null : _roleFilter,
        onlyReported: _showReportedOnly ? true : null,
        onlySuspended: _showSuspendedOnly ? true : null,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );
      
      setState(() {
        _users = users;
        _selectedUsers = List.generate(users.length, (_) => false);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
      final adminId = Supabase.instance.client.auth.currentUser?.id;
      if (adminId == null) {
        throw Exception('Admin ID not found');
      }
      
      String? notes;
      if (action != 'clear_flags') {
        // Get reason from admin
        notes = await showDialog<String>(
          context: context,
          builder: (context) => _buildReasonDialog(action),
        );
        
        if (notes == null) {
          setState(() => _isLoading = false);
          return;
        }
      }
      
      int successCount = 0;
      
      for (final userId in selectedIds) {
        bool success = false;
        
        // Perform the action
        switch (action) {
          case 'suspend':
            success = await _userService.suspendUser(userId, 7, adminId, notes ?? 'Bulk action');
            break;
          case 'unsuspend':
            success = await _userService.unsuspendUser(userId, adminId, notes ?? 'Bulk action');
            break;
          case 'ban':
            success = await _userService.banUser(userId, adminId, notes ?? 'Bulk action');
            break;
          case 'unban':
            success = await _userService.unbanUser(userId, adminId, notes ?? 'Bulk action');
            break;
          case 'clear_flags':
            // Implement clear flags action
            success = true; // Placeholder
            break;
        }
        
        if (success) {
          successCount++;
        }
      }
      
      // Reload data
      await _loadUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action completed for $successCount users')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error performing bulk action: $e')),
        );
      }
    }
  }
  
  Widget _buildReasonDialog(String action) {
    final TextEditingController reasonController = TextEditingController();
    
    return AlertDialog(
      title: Text('Reason for $action'),
      content: TextField(
        controller: reasonController,
        decoration: const InputDecoration(
          labelText: 'Enter reason',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () {
            if (reasonController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a reason')),
              );
              return;
            }
            Navigator.pop(context, reasonController.text);
          },
          child: const Text('SUBMIT'),
        ),
      ],
    );
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildUserManagementContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to user creation screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User creation coming soon')),
          );
        },
        child: const Icon(Icons.person_add),
        tooltip: "Add User",
      ),
    );
  }

  Widget _buildUserManagementContent() {
    return Column(
      children: [
        _buildFilterSection(),
        _buildBulkActionBar(),
        Expanded(
          child: _users.isEmpty
              ? const Center(child: Text("No users found"))
              : _buildUserList(),
        ),
        _buildPaginationControls(),
      ],
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
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminUserDetailScreen(userId: user['id']),
                  ),
                ).then((_) => _loadUsers());
              },
            ),
            onTap: () {
              setState(() {
                _selectedUsers[index] = !isSelected;
              });
            },
            onLongPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminUserDetailScreen(userId: user['id']),
                ),
              ).then((_) => _loadUsers());
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
            onPressed: _users.length >= _pageSize
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