// lib/config/app_config.dart
import 'package:flutter/material.dart';

/// Application-wide configuration settings
class AppConfig {
  // App display information
  static const String appName = 'Kutanda Plant Auction';
  static const String appVersion = '1.0.0';
  
  // Environment settings
  static const bool enableDebugLogs = true;
  static const bool isDevelopment = true;
  static const bool enablePushNotifications = true;
  
  // API endpoints and server config
  static const String apiBaseUrl = 'https://api.kutanda.com';
  static const String supabaseUrl = 'https://dcjycjiqelcftxbymley.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjanljamlxZWxjZnR4YnltbGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAyMTIwNTksImV4cCI6MjA1NTc4ODA1OX0.DmLByHHoWeRPusRD2EoYLxxk5F_soscl3jKg7mE4pPM';
  
  // User permissions and limits
  static const int maxItemsPerRequest = 50;
  static const int maxImagesPerAuction = 10;
  static const int maxAuctionDurationDays = 14;
  static const int defaultAuctionDurationDays = 7;
  static const double minimumBidIncrementPercentage = 5.0;
  
  // Theme configuration
  static final ThemeData lightTheme = ThemeData(
    primaryColor: AppTheme.primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppTheme.primaryColor,
      primary: AppTheme.primaryColor,
      secondary: AppTheme.accentColor,
    ),
    scaffoldBackgroundColor: AppTheme.backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
    ),
    useMaterial3: true,
  );
  
  // Pagination default values
  static const int defaultPageSize = 20;
  static const int defaultCacheTimeMinutes = 10;
}

/// Application theme colors
class AppTheme {
  static const Color primaryColor = Color(0xFF2E7D32); // Forest Green
  static const Color accentColor = Color(0xFF81C784); // Light Green
  static const Color backgroundColor = Color(0xFFF5F5F5); // Very Light Grey
  static const Color textColor = Color(0xFF212121); // Almost Black
  static const Color secondaryTextColor = Color(0xFF757575); // Medium Grey
  static const Color errorColor = Color(0xFFD32F2F); // Red
  static const Color successColor = Color(0xFF388E3C); // Green
  static const Color warningColor = Color(0xFFFFA000); // Amber
  static const Color surfaceColor = Colors.white;
}

/// Text constants used throughout the app
class AppStrings {
  static const String appName = 'Kutanda Plant Auction';
  static const String tagline = 'The premier marketplace for rare plants';
  
  // Auth screen texts
  static const String welcomeBack = 'Welcome Back';
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String emailPlaceholder = 'Email Address';
  static const String passwordPlaceholder = 'Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = 'Don\'t have an account?';
  static const String alreadyHaveAccount = 'Already have an account?';
  
  // Admin panel texts
  static const String adminPanel = 'Admin Panel';
  static const String userManagement = 'User Management';
  static const String contentModeration = 'Content Moderation';
  static const String analytics = 'Analytics';
  static const String settings = 'Settings';
  
  // Error messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String noInternetError = 'No internet connection. Please check your network.';
  static const String unauthorizedError = 'You are not authorized to perform this action.';
  static const String sessionExpiredError = 'Your session has expired. Please sign in again.';
  
  // Success messages
  static const String actionSuccessful = 'Action completed successfully.';
  static const String saveSuccessful = 'Changes saved successfully.';
  static const String deleteSuccessful = 'Deleted successfully.';
}