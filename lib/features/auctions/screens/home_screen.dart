import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/services/onesignal_service.dart';
import '../../../shared/services/session_service.dart';
import '../../auth/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? userData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

 Future<void> _fetchUserData() async {
  final user = supabase.auth.currentUser;
  if (user != null) {
    final response = await supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle(); // ✅ Use maybeSingle() to prevent errors

    if (response != null && mounted) { 
      setState(() {
        userData = response;
      });
    }
  }
}


 Future<void> _logout() async {
  setState(() => _isLoading = true); // Show loading indicator
  
  try {
    // Clear OneSignal data first if you're using it
    final oneSignalService = OneSignalService();
    await oneSignalService.clearUserData();
    
    // Clear session using only SessionService to avoid double signOut calls
    await SessionService.clearSession();
    
    if (!mounted) return;
    
    // Navigate to login screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false, // Remove all previous routes
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
      setState(() => _isLoading = false); // Hide loading indicator
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kutanda Plant Auction'),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _logout,
                ),
        ],
      ),
      body: Center(
        child: userData == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Welcome, ${userData!['name'] ?? "User"}", 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: userData!['profile_pic'] != null && userData!['profile_pic']!.isNotEmpty
                        ? NetworkImage(userData!['profile_pic']!)
                        : const NetworkImage("https://via.placeholder.com/150"), 
                  ),
                  const SizedBox(height: 10),
                  Text(userData!['email'] ?? "No email provided"), 
                ],
              ),
      ),
    );
  }
}
