// lib/features/support/widgets/admin_drawer.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/services/session_service.dart';
import '../../auth/screens/login_screen.dart';
import '../screens/admin_analytics_screen.dart';
import '../screens/admin_content_moderation_screen.dart';
import '../screens/admin_csr_management_screen.dart';
import '../screens/admin_dashboard.dart';
import '../screens/admin_system_config_screen.dart';
import '../screens/admin_user_management_screen.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Admin';
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Administrator'),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                email.isNotEmpty ? email[0].toUpperCase() : 'A',
                style: const TextStyle(fontSize: 40.0),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          
          // Dashboard
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              context.pop(); // Close drawer
              context.go('/admin_dashboard');
            },
          ),
          
          const Divider(),
          
          // Admin Sections
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'ADMINISTRATION',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          
          // User Management - Updated to navigate to the enhanced screen
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('User Management'),
            onTap: () {
              context.pop(); // Close drawer
              context.push('/admin_users');
            },
          ),
          
          // CSR Management
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('CSR Management'),
            onTap: () {
              context.pop(); // Close drawer
              context.push('/admin_csrs');
            },
          ),
          
          // Content Moderation
          ListTile(
            leading: const Icon(Icons.content_paste),
            title: const Text('Content Moderation'),
            onTap: () {
              context.pop(); // Close drawer
              context.push('/admin_content');
            },
          ),
          
          const Divider(),
          
          // Analytics and Configuration
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'PLATFORM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          
          // Analytics
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics & Reports'),
            onTap: () {
              context.pop(); // Close drawer
              context.push('/admin_analytics');
            },
          ),
          
          // System Configuration
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('System Configuration'),
            onTap: () {
              context.pop(); // Close drawer
              context.push('/admin_config');
            },
          ),
          
          // Security (coming soon)
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Security'),
            onTap: () {
              context.pop(); // Close drawer
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Security module coming soon')),
              );
            },
          ),
          
          const Divider(),
          
          // Logout option
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              context.pop(); // Close drawer first
              try {
                await Supabase.instance.client.auth.signOut();
                await SessionService.clearSession();
                
                if (context.mounted) {
                  context.go('/login'); // Navigate to login screen
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              }
            },
          ),
          
          // Help & Documentation
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Documentation'),
            onTap: () {
              context.pop(); // Close drawer
              _showHelpDialog(context); // This shows a dialog, not a screen navigation
            },
          ),
        ],
      ),
    );
  }
  
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Admin Help & Documentation'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quick Reference Guide',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 10),
                Text('• User Management: Manage platform users and their roles.'),
                Text('• CSR Management: Oversee customer support representatives.'),
                Text('• Content Moderation: Review and approve platform content.'),
                Text('• Analytics: View platform performance metrics.'),
                Text('• System Configuration: Configure platform settings.'),
                SizedBox(height: 15),
                Text(
                  'Need More Help?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 10),
                Text('Refer to the full documentation for detailed instructions.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.pop(); // Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}