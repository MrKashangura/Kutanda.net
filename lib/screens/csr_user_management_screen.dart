// lib/screens/csr_user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/user_management_service.dart';
import '../widgets/csr_drawer.dart';

class CSRUserManagementScreen extends StatefulWidget {
  const CSRUserManagementScreen({super.key});

  @override
  State<CSRUserManagementScreen> createState() => _CSRUserManagementScreenState();
}

class _CSRUserManagementScreenState extends State<CSRUserManagementScreen> {
  final UserManagementService _userService = UserManagementService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      title: Text(user['display_name'] ?? user['email'] ?? 'Unknown User'),
                      subtitle: Text(user['email'] ?? 'No email'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // View user details
                      },
                    );
                  },
                ),
    );
  }
}