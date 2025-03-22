// lib/features/auth/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/constants.dart';
import '../../../shared/services/session_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../widgets/social_signin_buttons.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _handleRegister() async {
    // Clear previous errors
    setState(() => _errorMessage = null);
    
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Register with Supabase
      final AuthResponse response = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      final User? user = response.user;
      
      if (user == null) {
        setState(() {
          _errorMessage = 'Registration failed. Please try again.';
          _isLoading = false;
        });
        return;
      }
      
      // Create user profile
      await _supabase.from('users').insert({
        'uid': user.id,
        'email': _emailController.text.trim(),
        'display_name': _nameController.text.trim(),
        'role': 'buyer', // Default role
        'auth_provider': 'email',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Create buyer profile
      await _supabase.from('buyers').insert({
        'user_id': user.id,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Save session
      await SessionService.saveUserSession(user.id, 'buyer');
      
      // Show success message and navigate
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Welcome to Kutanda.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to buyer dashboard
        Navigator.pushReplacementNamed(context, '/buyer_dashboard');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create an Account'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
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
                  'lib/assets/images/KutandaLogo.png',
                  height: 80,
                ),
                
                const SizedBox(height: 24),
                
                // App Name
                Text(
                  AppStrings.appName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Tagline
                Text(
                  'Join our green community today',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Registration Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name TextField
                      CustomTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        prefixIcon: Icons.person,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email TextField
                      EmailTextField(
                        controller: _emailController,
                        textInputAction: TextInputAction.next,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Password TextField
                      PasswordTextField(
                        controller: _passwordController,
                        textInputAction: TextInputAction.next,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Confirm Password TextField
                      PasswordTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleRegister(),
                        isConfirmPassword: true,
                        passwordController: _passwordController,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Terms and Conditions Checkbox
                      CheckboxListTile(
                        title: RichText(
                          text: TextSpan(
                            style: TextStyle(color: Colors.grey[700]),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        value: true, // This should be a state variable in a real app
                        onChanged: (value) {
                          // Update state variable in a real app
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
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
                      
                      // Register Button
                      CustomButton(
                        text: _isLoading ? 'Creating Account...' : 'Create Account',
                        onPressed: _isLoading ? null : _handleRegister,
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
                
                const SizedBox(height: 24),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Sign In'),
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