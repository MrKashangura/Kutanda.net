// lib/routes.dart
import 'package:flutter/material.dart';

import '../features/auctions/screens/auction_screen.dart'; // Import EnhancedAuctionScreen
import '../features/auctions/screens/buyer_dashboard.dart';
import '../features/auctions/screens/create_auction_screen.dart';
import '../features/auctions/screens/home_screen.dart';
import '../features/auctions/screens/seller_dashboard.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/profile/screens/kyc_submission_screen.dart';
import '../features/profile/screens/role_switch_screen.dart';
import '../features/support/screens/admin_dashboard.dart';
import '../features/support/screens/csr_dashboard.dart';

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
  '/explore': (context) => const EnhancedAuctionScreen(), // Change to your actual class name
  '/kyc_submission': (context) => const KycSubmissionScreen(),
};