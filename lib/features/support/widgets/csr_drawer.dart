// lib/widgets/csr_drawer.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/csr_analytics_screen.dart';
import '../screens/csr_content_moderation_screen.dart';
import '../screens/csr_dashboard.dart';
import '../screens/csr_dispute_resolution_screen.dart';
import '../screens/csr_profile_screen.dart';
import '../screens/csr_user_management_screen.dart';

class CSRDrawer extends StatelessWidget {
  const CSRDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'CSR';
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Customer Support'),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                email.isNotEmpty ? email[0].toUpperCase() : 'C',
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
              context.go('/csr_dashboard');
            },
          ),
          
          const Divider(),
          
          // Support Sections
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'SUPPORT SECTIONS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          
          // Ticket Management
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Ticket Management'),
            onTap: () {
              context.pop(); // Close drawer
              // No navigation needed if already on dashboard, or context.go('/csr_dashboard');
            },
          ),
          
          // Dispute Resolution
          ListTile(
            leading: const Icon(Icons.gavel),
            title: const Text('Dispute Resolution'),
            onTap: () {
              context.pop(); // Close drawer
              context.push('/dispute_resolution');
            },
          ),
          
          // Content Moderation
          ListTile(
            leading: const Icon(Icons.content_paste),
            title: const Text('Content Moderation'),
            onTap: () {
              context.pop(); // Close drawer
              context.push('/content_moderation');
            },
          ),
          
          // User Management
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('User Management'),
            onTap: () {
              context.pop(); // Close drawer
              context.push('/user_management');
            },
          ),
          
          const Divider(),
          
          // Analytics
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics Dashboard'),
            onTap: () {
              context.pop(); // Close drawer
              context.push('/analytics'); // CSR Analytics path
            },
          ),
          
          // Divider before settings
          const Divider(),
          
          // Profile & Settings
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile & Settings'),
            onTap: () {
              context.pop(); // Close drawer
              context.push('/csr_profile');
            },
          ),
          
          // Help & Documentation
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Documentation'),
            onTap: () {
              context.pop(); // Close drawer
              _showHelpDialog(context); // This shows a dialog
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
          title: const Text('CSR Help & Documentation'),
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
                Text('• Ticket Management: Handle customer inquiries and issues.'),
                Text('• Dispute Resolution: Mediate between buyers and sellers.'),
                Text('• Content Moderation: Review and approve/reject content.'),
                Text('• User Management: Assist users with account issues.'),
                SizedBox(height: 15),
                Text(
                  'Need More Help?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 10),
                Text('Contact your supervisor or refer to the full documentation.'),
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