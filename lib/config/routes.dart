// lib/config/routes.dart
import 'package:flutter/material.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/support/screens/admin_analytics_screen.dart';
import '../features/support/screens/admin_content_moderation_screen.dart';
import '../features/support/screens/admin_csr_management_screen.dart';
import '../features/support/screens/admin_dashboard.dart';
import '../features/support/screens/admin_system_config_screen.dart';
import '../features/support/screens/admin_user_detail_screen.dart';
import '../features/support/screens/admin_user_management_screen.dart';
import '../features/support/screens/csr_analytics_screen.dart';
import '../features/support/screens/csr_content_moderation_screen.dart';
import '../features/support/screens/csr_dashboard.dart';
import '../features/support/screens/csr_dispute_resolution_screen.dart';
import '../features/support/screens/csr_profile_screen.dart';
import '../features/support/screens/csr_user_management_screen.dart';
import '../features/support/screens/ticket_detail_screen.dart';

// Map all routes to their respective screens
final Map<String, WidgetBuilder> appRoutes = {
  // Auth routes
  '/login': (context) => const LoginScreen(),
  
  // Admin routes
  '/admin_dashboard': (context) => const AdminDashboard(),
  '/admin_user_management': (context) => const AdminUserManagementScreen(),
  '/admin_csr_management': (context) => const AdminCsrManagementScreen(),
  '/admin_content_moderation': (context) => const AdminContentModerationScreen(),
  '/admin_analytics': (context) => const AdminAnalyticsScreen(),
  '/admin_system_config': (context) => const AdminSystemConfigScreen(),
  
  // Dynamic routes that need parameters can't be directly added here
  // For admin_user_detail, we'll need to use Navigator.push directly
  
  // CSR routes
  '/csr_dashboard': (context) => const CSRDashboard(),
  '/csr_analytics': (context) => const CSRAnalyticsScreen(),
  '/csr_content_moderation': (context) => const CSRContentModerationScreen(),
  '/csr_dispute_resolution': (context) => const CSRDisputeResolutionScreen(),
  '/csr_profile': (context) => const CSRProfileScreen(),
  '/csr_user_management': (context) => const CSRUserManagementScreen(),
  
  // Common routes
  // For ticket_detail, we'll need to use Navigator.push directly
};

// Helper methods for navigation that require parameters
class AppRouter {
  // Navigate to user detail screen
  static void navigateToUserDetail(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminUserDetailScreen(userId: userId),
      ),
    );
  }
  
  // Navigate to ticket detail screen
  static void navigateToTicketDetail(BuildContext context, String ticketId, {Function? onTicketUpdated}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailScreen(
          ticketId: ticketId,
          onTicketUpdated: onTicketUpdated,
        ),
      ),
    );
  }
  
  // Admin dashboard navigation
  static void goToAdminDashboard(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/admin_dashboard',
      (route) => false,
    );
  }
  
  // CSR dashboard navigation
  static void goToCSRDashboard(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/csr_dashboard',
      (route) => false,
    );
  }
}