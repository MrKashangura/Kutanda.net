// lib/routes.dart
import 'package:flutter/material.dart';

import 'screens/admin_dashboard.dart';
import 'screens/auction_screen.dart';
import 'screens/buyer_dashboard.dart';
import 'screens/create_auction_screen.dart';
import 'screens/csr_dashboard.dart';
import 'screens/home_screen.dart';
import 'screens/kyc_submission_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/role_switch_screen.dart';
import 'screens/seller_dashboard.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const LoginScreen(),
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  '/home': (context) => const HomeScreen(),
  '/buyer_dashboard': (context) => const BuyerDashboard(),
  '/seller_dashboard': (context) => const SellerDashboard(),
  '/admin_dashboard': (context) => const AdminDashboard(),
  '/csr_dashboard': (context) => const CSRDashboard(),
  '/role_switch': (context) => const RoleSwitchScreen(),
  '/create_auction': (context) => const CreateAuctionScreen(),
  '/explore': (context) => const AuctionScreen(),
  '/kyc_submission': (context) => const KycSubmissionScreen(),
};