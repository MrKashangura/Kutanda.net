// lib/config/routes.dart
import 'package:flutter/material.dart';

import '../features/auctions/screens/auction_screen.dart';
import '../features/auctions/screens/buyer_dashboard.dart';
import '../features/auctions/screens/create_auction_screen.dart';
import '../features/auctions/screens/seller_dashboard.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/profile/screens/kyc_submission_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/role_switch_screen.dart';
import '../features/support/screens/admin_dashboard.dart';
import '../features/support/screens/csr_analytics_screen.dart';
import '../features/support/screens/csr_content_moderation_screen.dart';
import '../features/support/screens/csr_dashboard.dart';
import '../features/support/screens/csr_dispute_resolution_screen.dart';
import '../features/support/screens/csr_user_management_screen.dart';
import '../features/support/screens/ticket_detail_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  // Auth Routes
  '/': (context) => const LoginScreen(),
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  
  // User Dashboards
  '/home': (context) => const EnhancedAuctionScreen(),
  '/buyer_dashboard': (context) => const BuyerDashboard(),
  '/seller_dashboard': (context) => const SellerDashboard(),
  '/admin_dashboard': (context) => const AdminDashboard(),
  
  // Profile Routes
  '/profile': (context) => const ProfileScreen(),
  '/role_switch': (context) => const RoleSwitchScreen(),
  '/kyc_submission': (context) => const KycSubmissionScreen(),
  
  // Auction Routes
  '/explore': (context) => const EnhancedAuctionScreen(),
  '/create_auction': (context) => const CreateAuctionScreen(),
  '/auction_detail': (context) => const EnhancedAuctionScreen(),
  
  // CSR Routes
  '/csr_dashboard': (context) => const CSRDashboard(),
  '/analytics': (context) => const CSRAnalyticsScreen(),
  '/content_moderation': (context) => const CSRContentModerationScreen(),
  '/dispute_resolution': (context) => const CSRDisputeResolutionScreen(),
  '/user_management': (context) => const CSRUserManagementScreen(),
  '/ticket_detail': (context) {
    final args = ModalRoute.of(context)?.settings.arguments as String?;
    return TicketDetailScreen(ticketId: args ?? '');
  },
};

// Navigation helper to use throughout the app
void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
  Navigator.pushNamed(context, routeName, arguments: arguments);
}

void navigateReplacementTo(BuildContext context, String routeName, {Object? arguments}) {
  Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
}