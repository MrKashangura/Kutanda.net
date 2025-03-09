// lib/config/app_config.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
/// Contains application-wide configuration settings
class AppConfig {
  // Supabase configuration
  static String get supabaseUrl => 
    dotenv.get('SUPABASE_URL', fallback: 'https://dcjycjiqelcftxbymley.supabase.co');
  
  static String get supabaseAnonKey => 
    dotenv.get('SUPABASE_ANON_KEY', fallback: 'your-anon-key-here');
  
  // OneSignal configuration
  static String get oneSignalAppId => 
    dotenv.get('ONESIGNAL_APP_ID', fallback: '474b0ac4-c770-4050-b4b2-6b8cbef188a7');
  
  // App configuration
  static bool get enableNotifications => true;
  static bool get enableAutoLogin => true;
  static int get cacheTimeoutMinutes => 60;
  
  // Feature flags
  static bool get enableDirectMessaging => false;
  static bool get enableLiveAuctions => true;
  static bool get enableSellerKYC => true;
  // App Information
  static const String appName = 'Kutanda Plant Auction';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // API Endpoints
  static const String apiBaseUrl = 'https://api.kutanda.net/v1';
  
  // Feature Flags
  static const bool enablePushNotifications = true;
  static const bool enableLocationFeatures = false;
  static const bool enableAnalytics = true;
  
  // App Modes
  static const bool isDebugMode = true; // Set to false for production
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  static const double defaultBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  
  // Duration Constants
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
  
  // Storage Keys
  static const String tokenKey = 'jwt_token';
  static const String userIdKey = 'user_id';
  static const String roleKey = 'user_role';
  static const String themeKey = 'app_theme';
  
  // Auction Settings
  static const double minimumBidIncrement = 1.0;
  static const double minListingPrice = 5.0;
  static const int maxImagesPerAuction = 5;
  static const int minAuctionDurationHours = 12;
  static const int maxAuctionDurationDays = 14;
  
  // Theme Configuration
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      tertiary: AppColors.lightGreen,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardTheme(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
  );
  
  // Dark theme - to be implemented
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    // Customize dark theme here
  );
}

/// App-wide color constants
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2E7D32); // Green 800
  static const Color accent = Color(0xFF00897B); // Teal 600
  static const Color lightGreen = Color(0xFF8BC34A);
  
  // Neutral Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  
  // Status Colors
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF1976D2);
  
  // Auction Status Colors
  static const Color activeAuction = Color(0xFF43A047);
  static const Color pendingAuction = Color(0xFFFFA000);
  static const Color endedAuction = Color(0xFF757575);
  
  // KYC Status Colors
  static const Color verified = Color(0xFF43A047);
  static const Color pending = Color(0xFFFFA000);
  static const Color rejected = Color(0xFFD32F2F);
  static const Color notSubmitted = Color(0xFF1976D2);
}

/// App-wide text constants
class AppStrings {
  // Auth Screens
  static const String login = 'Login';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = 'Don\'t have an account?';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String signUp = 'Sign Up';
  static const String signIn = 'Sign In';
  
  // Dashboard Screens
  static const String buyerDashboard = 'Buyer Dashboard';
  static const String sellerDashboard = 'Seller Dashboard';
  static const String adminDashboard = 'Admin Dashboard';
  static const String csrDashboard = 'Customer Support Dashboard';
  
  // Navigation
  static const String home = 'Home';
  static const String explore = 'Explore';
  static const String createAuction = 'Create Auction';
  static const String profile = 'Profile';
  static const String settings = 'Settings';
  
  // KYC Verification
  static const String kycSubmission = 'Seller Verification';
  static const String kycVerified = 'Verified Seller';
  static const String kycPending = 'Verification Pending';
  static const String kycRejected = 'Verification Rejected';
  static const String kycRequired = 'Verification Required';
  
  // Auction Related
  static const String currentBid = 'Current Bid';
  static const String startingPrice = 'Starting Price';
  static const String timeRemaining = 'Time Remaining';
  static const String placeBid = 'Place Bid';
  static const String createNewAuction = 'Create New Auction';
  static const String auctionEnded = 'Auction Ended';
  
  // Error Messages
  static const String errorLogin = 'Login failed';
  static const String errorRegister = 'Registration failed';
  static const String errorNetwork = 'Network error. Please try again.';
  static const String errorUnknown = 'An unknown error occurred';
  
  // Success Messages
  static const String successBid = 'Bid placed successfully!';
  static const String successAuction = 'Auction created successfully!';
  static const String successUpdate = 'Updated successfully!';
}

/// App-wide icon constants
class AppIcons {
  static const IconData home = Icons.home;
  static const IconData explore = Icons.search;
  static const IconData create = Icons.add_circle;
  static const IconData profile = Icons.person;
  static const IconData settings = Icons.settings;
  
  static const IconData bid = Icons.gavel;
  static const IconData delete = Icons.delete;
  static const IconData edit = Icons.edit;
  static const IconData view = Icons.visibility;
  
  static const IconData verified = Icons.verified;
  static const IconData pending = Icons.hourglass_top;
  static const IconData rejected = Icons.cancel;
  static const IconData notSubmitted = Icons.person_add;
  
  static const IconData switchRole = Icons.swap_horiz;
  static const IconData logout = Icons.logout;
  static const IconData upload = Icons.upload_file;
  static const IconData image = Icons.image;
  static const IconData imageError = Icons.image_not_supported;
  
  static const IconData success = Icons.check_circle;
  static const IconData error = Icons.error;
  static const IconData warning = Icons.warning;
  static const IconData info = Icons.info;
}