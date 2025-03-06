import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? userData;

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
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kutanda Plant Auction'),
        actions: [
          IconButton(
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
