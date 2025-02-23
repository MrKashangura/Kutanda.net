import 'package:flutter/material.dart';

import 'screens/admin_dashboard.dart';
import 'screens/buyer_dashboard.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/role_switch_screen.dart'; // New role switch screen
import 'screens/seller_dashboard.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => LoginScreen(),
  '/home': (context) => HomeScreen(),
  '/buyer_dashboard': (context) => BuyerDashboard(),
  '/seller_dashboard': (context) => SellerDashboard(),
  '/admin_dashboard': (context) => AdminDashboard(),
  '/role_switch': (context) => RoleSwitchScreen(), // Added route for role switching
};

