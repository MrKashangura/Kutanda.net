// lib/features/support/screens/admin_user_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/helpers.dart';
import '../../../services/user_management_service.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final String userId;
  
  const AdminUserDetailScreen({
    required this.userId,
    super.key,
  });

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> with SingleTickerProviderStateMixin {
  final UserManagementService _userService = UserManagementService();
  final TextEditingController _noteController = TextEditingController();
  
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _userActionHistory = [];
  List<Map<String, dynamic>> _verificationHistory = [];
  List<Map<String, dynamic>> _userNotes = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final profile = await _userService.getUserProfile(widget.userId);
      final actionHistory = await _userService.getUserActionHistory(widget.userId);
      final verificationHistory = await _userService.getUserVerificationHistory(widget.userId);
      final notes = await _userService.getUserNotes(widget.userId);
      
      setState(() {
        _userProfile = profile;
        _userActionHistory = actionHistory;
        _verificationHistory = verificationHistory;
        _userNotes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    }
  }
  
  Future<void> _addUserNote() async {
    if (_noteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a note')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final adminId = Supabase.instance.client.auth.currentUser?.id;
      if (adminId == null) {
        throw Exception('Admin ID not found');
      }
      
      final success = await _userService.addUserNote(
        widget.userId,
        adminId,
        _noteController.text,
      );
      
      if (success) {
        _noteController.clear();
        await _loadUserData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note added successfully')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding note: $e')),
        );
      }
    }
  }
  
  Future<void> _performAction(String action) async {
    // Show confirmation dialog
    final bool confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $action'),
        content: Text('Are you sure you want to $action this user?'),
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
    
    // Get reason from admin
    final String? reason = await showDialog<String>(
      context: context,
      builder: (context) => _buildReasonDialog(action),
    );
    
    if (reason == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final adminId = Supabase.instance.client.auth.currentUser?.id;
      if (adminId == null) {
        throw Exception('Admin ID not found');
      }
      
      bool success = false;
      
      // Perform the action
      switch (action) {
        case 'Suspend':
          // Default suspension is 7 days
          success = await _userService.suspendUser(widget.userId, 7, adminId, reason);
          break;
        case 'Unsuspend':
          success = await _userService.unsuspendUser(widget.userId, adminId, reason);
          break;
        case 'Ban':
          success = await _userService.banUser(widget.userId, adminId, reason);
          break;
        case 'Unban':
          success = await _userService.unbanUser(widget.userId, adminId, reason);
          break;
        case 'Reset Password':
          // Get user email from profile
          final email = _userProfile?['email'];
          if (email == null) {
            throw Exception('User email not found');
          }
          success = await _userService.resetUserPassword(email);
          break;
      }
      
      if (success) {
        await _loadUserData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$action action completed successfully')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error performing action: $e')),
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
        title: Text(_userProfile != null 
            ? "User: ${_userProfile!['display_name'] ?? _userProfile!['email'] ?? 'Unknown'}" 
            : "User Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: "Refresh Data",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Profile"),
            Tab(text: "Activity"),
            Tab(text: "Verification"),
            Tab(text: "Notes"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? const Center(child: Text("User not found"))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProfileTab(),
                    _buildActivityTab(),
                    _buildVerificationTab(),
                    _buildNotesTab(),
                  ],
                ),
    );
  }

  Widget _buildProfileTab() {
    if (_userProfile == null) {
      return const Center(child: Text("User profile not available"));
    }
    
    final user = _userProfile!;
    final sellerProfile = user['seller_profile'] as Map<String, dynamic>?;
    final activity = user['activity'] as Map<String, dynamic>?;
    
    // Determine user status flags
    final bool isReported = user['is_reported'] == true;
    final bool isWarned = user['is_warned'] == true;
    final bool isSuspended = user['is_suspended'] == true;
    final bool isBanned = user['is_banned'] == true;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User information card
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        child: Text(
                          (user['email'] as String?)?.isNotEmpty == true
                              ? (user['email'] as String)[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['display_name'] ?? 'No Display Name',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Email: ${user['email'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Phone: ${user['phone'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildProfileChip('Role: ${user['role'] ?? 'Unknown'}', Colors.blue),
                                const SizedBox(width: 8),
                                if (isReported)
                                  _buildProfileChip('Reported', Colors.purple),
                                if (isWarned)
                                  _buildProfileChip('Warned', Colors.amber),
                                if (isSuspended)
                                  _buildProfileChip('Suspended', Colors.orange),
                                if (isBanned)
                                  _buildProfileChip('Banned', Colors.red),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Text(
                    'Created: ${formatDate(DateTime.parse(user['created_at']))}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (user['updated_at'] != null)
                    Text(
                      'Last Updated: ${formatDate(DateTime.parse(user['updated_at']))}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  if (isSuspended && user['suspended_until'] != null)
                    Text(
                      'Suspended Until: ${formatDate(DateTime.parse(user['suspended_until']))}',
                      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.error),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildActionButton(
                        label: isSuspended ? 'Unsuspend' : 'Suspend',
                        icon: isSuspended ? Icons.check_circle : Icons.block,
                        color: isSuspended ? Colors.green : Colors.orange,
                        onPressed: () => _performAction(isSuspended ? 'Unsuspend' : 'Suspend'),
                      ),
                      _buildActionButton(
                        label: isBanned ? 'Unban' : 'Ban',
                        icon: isBanned ? Icons.lock_open : Icons.delete_forever,
                        color: isBanned ? Colors.blue : Colors.red,
                        onPressed: () => _performAction(isBanned ? 'Unban' : 'Ban'),
                      ),
                      _buildActionButton(
                        label: 'Reset Password',
                        icon: Icons.password,
                        color: Colors.purple,
                        onPressed: () => _performAction('Reset Password'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // User activity stats
          if (activity != null)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Activity',
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
                      children: [
                        _buildStatTile('Auctions Created', activity['auctions_created']?.toString() ?? '0'),
                        _buildStatTile('Bids Placed', activity['bids_placed']?.toString() ?? '0'),
                        _buildStatTile('Reviews Received', activity['reviews_received']?.toString() ?? '0'),
                        _buildStatTile('Total Tickets', activity['total_tickets']?.toString() ?? '0'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Seller profile section (if applicable)
          if (sellerProfile != null)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seller Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('KYC Status'),
                      subtitle: Text(sellerProfile['kyc_status'] ?? 'Unknown'),
                      leading: Icon(
                        _getKycStatusIcon(sellerProfile['kyc_status']),
                        color: _getKycStatusColor(sellerProfile['kyc_status']),
                      ),
                    ),
                    ListTile(
                      title: const Text('Business Name'),
                      subtitle: Text(sellerProfile['business_name'] ?? 'N/A'),
                    ),
                    ListTile(
                      title: const Text('Business ID'),
                      subtitle: Text(sellerProfile['business_id'] ?? 'N/A'),
                    ),
                    ListTile(
                      title: const Text('Tax ID'),
                      subtitle: Text(sellerProfile['tax_id'] ?? 'N/A'),
                    ),
                    if (sellerProfile['document_urls'] != null)
                      const ListTile(
                        title: Text('Verification Documents'),
                        subtitle: Text('Documents available'),
                        trailing: Icon(Icons.attach_file),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildActivityTab() {
    if (_userActionHistory.isEmpty) {
      return const Center(child: Text("No activity history available"));
    }
    
    return ListView.builder(
      itemCount: _userActionHistory.length,
      itemBuilder: (context, index) {
        final action = _userActionHistory[index];
        final admin = action['admin'] as Map<String, dynamic>?;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getActionColor(action['action_type']),
              child: Icon(
                _getActionIcon(action['action_type']),
                color: Colors.white,
              ),
            ),
            title: Text(
              _formatActionType(action['action_type']),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reason: ${action['reason'] ?? 'No reason provided'}'),
                const SizedBox(height: 4),
                Text(
                  'By ${admin?['display_name'] ?? admin?['email'] ?? 'Unknown'} on ${formatDate(DateTime.parse(action['timestamp']))}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
  
  Widget _buildVerificationTab() {
    if (_verificationHistory.isEmpty) {
      return const Center(child: Text("No verification history available"));
    }
    
    return ListView.builder(
      itemCount: _verificationHistory.length,
      itemBuilder: (context, index) {
        final verification = _verificationHistory[index];
        final reviewer = verification['reviewer'] as Map<String, dynamic>?;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: verification['action'] == 'approved' 
                  ? Colors.green 
                  : Colors.red,
              child: Icon(
                verification['action'] == 'approved' 
                    ? Icons.check 
                    : Icons.close,
                color: Colors.white,
              ),
            ),
            title: Text(
              'Verification ${verification['action'] == 'approved' ? 'Approved' : 'Rejected'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (verification['notes'] != null)
                  Text('Notes: ${verification['notes']}'),
                const SizedBox(height: 4),
                Text(
                  'By ${reviewer?['display_name'] ?? reviewer?['email'] ?? 'Unknown'} on ${formatDate(DateTime.parse(verification['timestamp']))}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            isThreeLine: verification['notes'] != null,
          ),
        );
      },
    );
  }
  
  Widget _buildNotesTab() {
    return Column(
      children: [
        // Add note form
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Note',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: 'Enter a note about this user',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _addUserNote,
                icon: const Icon(Icons.add),
                label: const Text('Add Note'),
              ),
            ],
          ),
        ),
        
        const Divider(),
        
        // Notes list
        Expanded(
          child: _userNotes.isEmpty
              ? const Center(child: Text("No notes available"))
              : ListView.builder(
                  itemCount: _userNotes.length,
                  itemBuilder: (context, index) {
                    final note = _userNotes[index];
                    final author = note['author'] as Map<String, dynamic>?;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.note),
                        ),
                        title: Text(
                          'Note by ${author?['display_name'] ?? author?['email'] ?? 'Unknown'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(note['content'] ?? 'No content'),
                            const SizedBox(height: 4),
                            Text(
                              'Added on ${formatDate(DateTime.parse(note['created_at']))}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
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
  
  Widget _buildProfileChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
      ),
    );
  }
  
  Widget _buildStatTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getKycStatusIcon(String? status) {
    switch (status) {
      case 'verified':
        return Icons.verified;
      case 'pending':
        return Icons.pending;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.question_mark;
    }
  }
  
  Color _getKycStatusColor(String? status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  Color _getActionColor(String? actionType) {
    switch (actionType) {
      case 'suspend':
        return Colors.orange;
      case 'unsuspend':
        return Colors.green;
      case 'ban':
        return Colors.red;
      case 'unban':
        return Colors.blue;
      case 'warn':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getActionIcon(String? actionType) {
    switch (actionType) {
      case 'suspend':
        return Icons.block;
      case 'unsuspend':
        return Icons.check_circle;
      case 'ban':
        return Icons.delete_forever;
      case 'unban':
        return Icons.lock_open;
      case 'warn':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }
  
  String _formatActionType(String? actionType) {
    if (actionType == null) return 'Unknown Action';
    
    // Convert from snake_case or camelCase to Title Case with spaces
    return actionType
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match[0]}') // Handle camelCase
        .replaceAll('_', ' ') // Handle snake_case
        .trim()
        .split(' ')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}