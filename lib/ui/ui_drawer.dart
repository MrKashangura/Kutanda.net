import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key}); // ✅ FIXED: Use Dart's super parameter

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          // Drawer header
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.green),
            child: Text(
              "Kutanda Auction",
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
          // Home
          ListTile(
            leading: Icon(Icons.home),
            title: Text("Home"),
            onTap: () {
              context.go('/home');
              Navigator.pop(context); // Close the drawer
            },
          ),
          // Buyer Dashboard
          ListTile(
            leading: Icon(Icons.person),
            title: Text("Buyer Dashboard"),
            onTap: () {
              context.go('/buyer_dashboard');
              Navigator.pop(context); // Close the drawer
            },
          ),
          // Seller Dashboard
          ListTile(
            leading: Icon(Icons.store),
            title: Text("Seller Dashboard"),
            onTap: () {
              context.go('/seller_dashboard');
              Navigator.pop(context); // Close the drawer
            },
          ),
          // Admin Dashboard
          ListTile(
            leading: Icon(Icons.admin_panel_settings),
            title: Text("Admin Dashboard"),
            onTap: () {
              context.go('/admin_dashboard');
              Navigator.pop(context); // Close the drawer
            },
          ),
          // Role Switch
          ListTile(
            leading: Icon(Icons.swap_horiz),
            title: Text("Switch Role"),
            onTap: () {
              context.push('/role_switch');
              Navigator.pop(context); // Close the drawer
            },
          ),
          // Logout (if needed)
          ListTile(
            leading: Icon(Icons.logout),
            title: Text("Logout"),
            onTap: () {
              // Add your logout logic here.
            },
          ),
        ],
      ),
    );
  }
}