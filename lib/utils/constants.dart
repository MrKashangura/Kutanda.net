// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF2E7D32); // Green 800
  static const Color accentColor = Color(0xFF00897B); // Teal 600
  static const Color lightGreen = Color(0xFF8BC34A);
  
  // Neutral Colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFD32F2F);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  
  // Status Colors
  static const Color successColor = Color(0xFF43A047);
  static const Color warningColor = Color(0xFFFFA000);
  static const Color infoColor = Color(0xFF1976D2);
  
  // Auction Status Colors
  static const Color activeAuctionColor = Color(0xFF43A047);
  static const Color pendingAuctionColor = Color(0xFFFFA000);
  static const Color endedAuctionColor = Color(0xFF757575);
  
  // KYC Status Colors
  static const Color verifiedColor = Color(0xFF43A047);
  static const Color pendingColor = Color(0xFFFFA000);
  static const Color rejectedColor = Color(0xFFD32F2F);
  static const Color notSubmittedColor = Color(0xFF1976D2);
  
  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  
  // Border Radius
  static const double borderRadiusSm = 4.0;
  static const double borderRadiusMd = 8.0;
  static const double borderRadiusLg = 12.0;
  static const double borderRadiusXl = 16.0;
  
  // Elevation
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  
  // Font Sizes
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeMd = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 20.0;
  static const double fontSizeXxl = 24.0;
  
  // Font Weights
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
}

// App-wide string constants
class AppStrings {
  // Auth Screens
  static const String appName = 'Kutanda Plant Auction';
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
}

// Icons used throughout the app
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