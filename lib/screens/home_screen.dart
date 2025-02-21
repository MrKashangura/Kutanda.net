import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        final fetchedUserData = doc.data() as Map<String, dynamic>;

        if (mounted) { // ✅ Ensure widget is still active
          setState(() {
            userData = fetchedUserData;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kutanda Plant Auction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final BuildContext currentContext = context; // ✅ Save BuildContext
              await _auth.signOut();
              if (!mounted) return; // ✅ Prevent navigation if widget is disposed
              if (!context.mounted) return; // Ensure widget is still in the tree
              Navigator.pushReplacementNamed(context, '/login');
              Navigator.pushReplacement(
                currentContext, // ✅ Use saved context
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
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
                    "Welcome, ${userData!['name'] ?? "User"}", // ✅ Default value
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: userData!['profilePic'] != null && userData!['profilePic']!.isNotEmpty
                        ? NetworkImage(userData!['profilePic']!)
                        : const NetworkImage("https://via.placeholder.com/150"), // ✅ Default image
                  ),
                  const SizedBox(height: 10),
                  Text(userData!['email'] ?? "No email provided"), // ✅ Default value
                ],
              ),
      ),
    );
  }
}
