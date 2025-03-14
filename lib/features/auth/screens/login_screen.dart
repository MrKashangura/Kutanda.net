// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';

import '../../../core/utils/constants.dart';
import '../../../shared/services/session_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../services/auth_email_service.dart';
import '../widgets/social_signin_buttons.dart';
import 'register_screen.dart' as register;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthEmailService();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }
  
  Future<void> _checkExistingSession() async {
    setState(() => _isLoading = true);
    
    try {
      final session = await SessionService.getUserSession();
      
      if (session.isNotEmpty) {
        // User is already logged in, navigate to appropriate dashboard
        if (mounted) {
          final role = session['role'];
          
          if (role == 'buyer') {
            Navigator.pushReplacementNamed(context, '/buyer_dashboard');
          } else if (role == 'seller') {
            Navigator.pushReplacementNamed(context, '/seller_dashboard');
          } else if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
          } else if (role == 'csr') {
            Navigator.pushReplacementNamed(context, '/csr_dashboard');
          }
        }
      }
    } catch (e) {
      // Session check failed, continue to login screen
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _handleEmailLogin() async {
    // Clear previous errors
    setState(() => _errorMessage = null);
    
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final result = await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (result['success']) {
        // Navigate to appropriate dashboard based on role
        if (mounted) {
          final role = result['role'];
          
          if (role == 'buyer') {
            Navigator.pushReplacementNamed(context, '/buyer_dashboard');
          } else if (role == 'seller') {
            Navigator.pushReplacementNamed(context, '/seller_dashboard');
          } else if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
          } else if (role == 'csr') {
            Navigator.pushReplacementNamed(context, '/csr_dashboard');
          }
        }
      } else {
        setState(() => _errorMessage = result['message']);
      }
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _handleSocialSignIn(bool isSuccess, String message, bool isNewUser) {
    if (isSuccess) {
      // Navigate to buyer dashboard since social login defaults to buyer role
      Navigator.pushReplacementNamed(context, '/buyer_dashboard');
    } else {
      setState(() => _errorMessage = message);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading && _emailController.text.isEmpty) {
      // Show loading screen while checking for existing session
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 120,
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                ),
                
                const SizedBox(height: 32),
                
                // App Name
                Text(
                  AppStrings.appName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Tagline
                Text(
                  'Your green marketplace for rare plants',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email TextField
                      EmailTextField(
                        controller: _emailController,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Password TextField
                      PasswordTextField(
                        controller: _passwordController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleEmailLogin(),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/forgot_password');
                          },
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Error Message (if any)
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Login Button
                      CustomButton(
                        text: _isLoading ? 'Signing in...' : 'Sign In',
                        onPressed: _isLoading ? null : _handleEmailLogin,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // OR Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[400])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[400])),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Social Sign In Buttons
                      SocialSignInButtons(
                        onSignInComplete: _handleSocialSignIn,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account?',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const register.RegisterScreen()),
                        );
                      },
                      child: const Text('Register Now'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}