// lib/utils/helpers.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formats a DateTime as a date string
String formatDate(DateTime date) {
  final formatter = DateFormat('MMM d, yyyy');
  return formatter.format(date);
}

/// Formats a DateTime as a date and time string
String formatDateTime(DateTime date) {
  final formatter = DateFormat('MMM d, yyyy h:mm a');
  return formatter.format(date);
}

/// Calculates time remaining from now until the given end time
String formatTimeRemaining(DateTime endTime) {
  final now = DateTime.now();
  final difference = endTime.difference(now);
  
  if (difference.isNegative) {
    return 'Ended';
  }
  
  if (difference.inDays > 0) {
    return '${difference.inDays}d ${difference.inHours % 24}h';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}h ${difference.inMinutes % 60}m';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}m ${difference.inSeconds % 60}s';
  } else {
    return '${difference.inSeconds}s';
  }
}

/// Returns a color based on the KYC status
Color getKycStatusColor(String status) {
  switch (status) {
    case 'verified':
      return const Color(0xFF43A047); // Green
    case 'pending':
      return const Color(0xFFFFA000); // Orange
    case 'rejected':
      return const Color(0xFFD32F2F); // Red
    default:
      return const Color(0xFF1976D2); // Blue
  }
}

/// Returns an icon based on the KYC status
IconData getKycStatusIcon(String status) {
  switch (status) {
    case 'verified':
      return Icons.verified;
    case 'pending':
      return Icons.hourglass_top;
    case 'rejected':
      return Icons.cancel;
    default:
      return Icons.person_add;
  }
}

/// Shows a snackbar with the given message and optional action
void showSnackBar(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onAction,
            )
          : null,
    ),
  );
}

/// Shows a loading dialog
void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );
}

String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays > 365) {
    return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
  } else if (difference.inDays > 30) {
    return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
  } else if (difference.inDays > 0) {
    return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
  } else {
    return 'Just now';
  }
}

/// Truncate text with ellipsis if it's too long
String truncateWithEllipsis(String text, int maxLength) {
  return text.length <= maxLength ? text : '${text.substring(0, maxLength)}...';
}

/// Extension method to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

/// Format a currency value
String formatCurrency(double value) {
  return '\${value.toStringAsFixed(2)}';
}

/// Format a percentage value
String formatPercentage(double value) {
  return '${value.toStringAsFixed(1)}%';
}
/// Shows a confirmation dialog and returns true if confirmed
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  Color? confirmColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: confirmColor != null
              ? TextButton.styleFrom(foregroundColor: confirmColor)
              : null,
          child: Text(confirmText),
        ),
      ],
    ),
  );
  
  return result ?? false;
}

/// Validates an email address
bool isValidEmail(String email) {
  return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
}

/// Validates a password (min 6 chars)
bool isValidPassword(String password) {
  return password.length >= 6;
}



/// Formats a number with thousands separators
String formatNumber(num number) {
  final formatter = NumberFormat('#,###');
  return formatter.format(number);
}

/// Extension on BuildContext to access theme and media query easily
extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  bool get isKeyboardOpen => MediaQuery.of(this).viewInsets.bottom > 0;
}
