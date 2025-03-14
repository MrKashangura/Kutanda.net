// lib/features/auth/widgets/social_signin_buttons.dart
import 'package:flutter/material.dart';

import '../services/auth_facebook_service.dart';
import '../services/auth_google_service.dart';

class SocialSignInButtons extends StatefulWidget {
  final Function(bool isSuccess, String message, bool isNewUser) onSignInComplete;

  const SocialSignInButtons({
    required this.onSignInComplete,
    super.key,
  });

  @override
  State<SocialSignInButtons> createState() => _SocialSignInButtonsState();
}

class _SocialSignInButtonsState extends State<SocialSignInButtons> {
  final AuthGoogleService _googleService = AuthGoogleService();
  final AuthFacebookService _facebookService = AuthFacebookService();
  
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Google Sign In Button
        ElevatedButton.icon(
          onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
          icon: _isGoogleLoading 
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Image.asset(
                  'assets/images/google_logo.png',
                  height: 24,
                  width: 24,
                ),
          label: Text(_isGoogleLoading ? 'Signing in...' : 'Continue with Google'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.grey),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Facebook Sign In Button
        ElevatedButton.icon(
          onPressed: _isFacebookLoading ? null : _handleFacebookSignIn,
          icon: _isFacebookLoading 
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.facebook, size: 24, color: Colors.white),
          label: Text(_isFacebookLoading ? 'Signing in...' : 'Continue with Facebook'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1877F2), // Facebook blue
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final result = await _googleService.signInWithGoogle();
      
      widget.onSignInComplete(
        result['success'],
        result['message'] ?? '',
        result['isNewUser'] ?? false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() {
      _isFacebookLoading = true;
    });

    try {
      final result = await _facebookService.signInWithFacebook();
      
      widget.onSignInComplete(
        result['success'],
        result['message'] ?? '',
        result['isNewUser'] ?? false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFacebookLoading = false;
        });
      }
    }
  }
}