// lib/config/routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter

// Import all screen widgets (ensure these paths are correct)
import '../features/auctions/screens/auction_screen.dart'; // Renamed to EnhancedAuctionScreen in old routes
import '../features/auctions/screens/buyer_dashboard.dart';
import '../features/auctions/screens/checkout_screen.dart';
import '../features/auctions/screens/create_auction_screen.dart';
import '../features/auctions/screens/search_explore_screen.dart';
import '../features/auctions/screens/seller_dashboard.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/profile/screens/kyc_submission_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/role_switch_screen.dart';
import '../features/support/screens/admin_analytics_screen.dart';
import '../features/support/screens/admin_content_moderation_screen.dart';
import '../features/support/screens/admin_csr_management_screen.dart';
import '../features/support/screens/admin_dashboard.dart';
import '../features/support/screens/admin_system_config_screen.dart';
import '../features/support/screens/admin_user_management_screen.dart';
import '../features/support/screens/csr_analytics_screen.dart';
import '../features/support/screens/csr_content_moderation_screen.dart';
import '../features/support/screens/csr_dashboard.dart';
import '../features/support/screens/csr_dispute_resolution_screen.dart';
import '../features/support/screens/csr_user_management_screen.dart';
import '../features/support/screens/ticket_detail_screen.dart';

// Import new placeholder/actual screens
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auctions/screens/watchlist_screen.dart';
import '../features/auctions/screens/fixed_price_detail_screen.dart';
import '../features/profile/screens/settings_screen.dart';

// More specific support screen imports if not covered by general support import
import '../features/support/screens/admin_user_detail_screen.dart'; // For /admin_users/:userId
import '../features/support/screens/csr_profile_screen.dart';       // For /csr_profile
import '../features/support/screens/csr_analytics_widget_screen.dart'; // For /csr_analytics_widget

// Define the GoRouter instance
final GoRouter router = GoRouter(
  initialLocation: '/login', // Default initial route
  routes: <RouteBase>[
    // Auth Routes
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (BuildContext context, GoRouterState state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) => const EnhancedAuctionScreen(),
    ),
    GoRoute(
      path: '/buyer_dashboard',
      builder: (BuildContext context, GoRouterState state) => const BuyerDashboard(),
    ),
    GoRoute(
      path: '/seller_dashboard',
      builder: (BuildContext context, GoRouterState state) => const SellerDashboard(),
    ),
    GoRoute(
      path: '/profile',
      builder: (BuildContext context, GoRouterState state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/role_switch',
      builder: (BuildContext context, GoRouterState state) => const RoleSwitchScreen(),
    ),
    GoRoute(
      path: '/kyc_submission',
      builder: (BuildContext context, GoRouterState state) => const KycSubmissionScreen(),
    ),
    GoRoute(
      path: '/explore',
      builder: (BuildContext context, GoRouterState state) => const EnhancedAuctionScreen(),
    ),
    GoRoute(
      path: '/create_auction',
      builder: (BuildContext context, GoRouterState state) => const CreateAuctionScreen(),
    ),
    GoRoute(
      path: '/auction_detail', // Old: '/auction_detail': (context) => const EnhancedAuctionScreen(),
                               // If an ID is needed: '/auction_detail/:auctionId' and adapt EnhancedAuctionScreen
      builder: (BuildContext context, GoRouterState state) => const EnhancedAuctionScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (BuildContext context, GoRouterState state) {
        // final data = state.extra as Map<String, dynamic>?; // For passing arguments via `extra`
        return const CheckoutScreen();
      },
    ),
    GoRoute(
      path: '/search_explore',
      builder: (BuildContext context, GoRouterState state) => const SearchExploreScreen(),
    ),
    // Admin Routes
    GoRoute(
      path: '/admin_dashboard',
      builder: (BuildContext context, GoRouterState state) => const AdminDashboard(),
    ),
    GoRoute(
      path: '/admin_users',
      builder: (BuildContext context, GoRouterState state) => const AdminUserManagementScreen(),
    ),
    GoRoute(
      path: '/admin_csrs',
      builder: (BuildContext context, GoRouterState state) => const AdminCsrManagementScreen(),
    ),
    GoRoute(
      path: '/admin_content',
      builder: (BuildContext context, GoRouterState state) => const AdminContentModerationScreen(),
    ),
    GoRoute(
      path: '/admin_analytics',
      builder: (BuildContext context, GoRouterState state) => const AdminAnalyticsScreen(),
    ),
    GoRoute(
      path: '/admin_config',
      builder: (BuildContext context, GoRouterState state) => const AdminSystemConfigScreen(),
    ),
    // CSR Routes
    GoRoute(
      path: '/csr_dashboard',
      builder: (BuildContext context, GoRouterState state) => const CSRDashboard(),
    ),
    GoRoute(
      path: '/analytics', // CSR Analytics
      builder: (BuildContext context, GoRouterState state) => const CSRAnalyticsScreen(),
    ),
    GoRoute(
      path: '/content_moderation', // CSR Content Moderation
      builder: (BuildContext context, GoRouterState state) => const CSRContentModerationScreen(),
    ),
    GoRoute(
      path: '/dispute_resolution', // CSR Dispute Resolution
      builder: (BuildContext context, GoRouterState state) => const CSRDisputeResolutionScreen(),
    ),
    GoRoute(
      path: '/user_management', // CSR User Management
      builder: (BuildContext context, GoRouterState state) => const CSRUserManagementScreen(),
    ),
    GoRoute(
      path: '/ticket_detail/:ticketId', // Path parameter for ticketId
      builder: (BuildContext context, GoRouterState state) {
        final ticketId = state.pathParameters['ticketId'];
        return TicketDetailScreen(ticketId: ticketId ?? '');
        // Note: The onTicketUpdated callback is not handled by GoRouter arguments here.
        // It was part of the widget constructor, not ModalRoute arguments.
        // If needed, this should be handled via state management or other means.
      },
    ),
    // Add new routes here
    GoRoute(
      path: '/forgot_password',
      builder: (BuildContext context, GoRouterState state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/watchlist',
      builder: (BuildContext context, GoRouterState state) => const WatchlistScreen(),
    ),
    GoRoute(
      path: '/fixed_price_detail/:listingId',
      builder: (BuildContext context, GoRouterState state) {
        final listingId = state.pathParameters['listingId'];
        return FixedPriceDetailScreen(listingId: listingId ?? 'error_no_id');
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) => const SettingsScreen(),
    ),
    // Support specific detail/new routes
    GoRoute(
      path: '/admin_users/:userId',
      builder: (BuildContext context, GoRouterState state) {
        final userId = state.pathParameters['userId'];
        if (userId == null) {
          // Handle error: userId is required. Maybe redirect to an error page or /admin_users
          return const Scaffold(body: Center(child: Text('Error: User ID is missing')));
        }
        return AdminUserDetailScreen(userId: userId);
      },
    ),
    GoRoute(
      path: '/csr_profile',
      builder: (BuildContext context, GoRouterState state) => const CSRProfileScreen(),
    ),
    GoRoute(
      path: '/csr_analytics_widget', // Example for a specific widget/details screen for CSR analytics
      builder: (BuildContext context, GoRouterState state) => const CSRAnalyticsWidgetScreen(),
    ),
  ],
  // Optional: Add an error handler for unknown routes
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(
      child: Text('Error: ${state.error?.message ?? "The requested page doesn't exist."}'),
    ),
  ),
);

// The old appRoutes map, navigateTo, and navigateReplacementTo functions are removed.
// GoRouter's context.go, context.push, etc., should be used for navigation.

// To use GoRouter in your app, you'll need to update your MaterialApp:
// MaterialApp.router(
//   routerConfig: router, // router is the GoRouter instance defined in this file.
//   // ... other MaterialApp properties
// )
// Example in main.dart:
//
// import 'package:flutter/material.dart';
// import 'package:kutanda_plant_auction/config/routes.dart'; // Adjust import path
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp.router(
//       title: 'Kutanda Plant Auction',
//       // theme: ...,
//       routerConfig: router,
//     );
//   }
// }