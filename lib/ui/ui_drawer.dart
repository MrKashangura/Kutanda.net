import 'package:flutter/material.dart';

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
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          // Buyer Dashboard
          ListTile(
            leading: Icon(Icons.person),
            title: Text("Buyer Dashboard"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/buyer_dashboard');
            },
          ),
          // Seller Dashboard
          ListTile(
            leading: Icon(Icons.store),
            title: Text("Seller Dashboard"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/seller_dashboard');
            },
          ),
          // Admin Dashboard
          ListTile(
            leading: Icon(Icons.admin_panel_settings),
            title: Text("Admin Dashboard"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/admin_dashboard');
            },
          ),
          // Role Switch
          ListTile(
            leading: Icon(Icons.swap_horiz),
            title: Text("Switch Role"),
            onTap: () {
              Navigator.pushNamed(context, '/role_switch');
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