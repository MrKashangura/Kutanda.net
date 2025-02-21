import 'dart:developer'; // ✅ Use proper logging

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static Future<void> saveUserSession(String uid, String role) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
    await prefs.setString('role', role);
  }

  static Future<Map<String, String?>> getUserSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uid = prefs.getString('uid');
    String? role = prefs.getString('role');

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || uid == null) {
      return {};
    }

    if (role != null) {
      return {'uid': uid, 'role': role}; // ✅ If stored, return session immediately
    }

    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        role = userDoc.get('role') ?? "unknown";
        await prefs.setString('role', role ?? "unknown"); // ✅ Ensure role is non-null
        return {'uid': uid, 'role': role};
      }
    } catch (e) {
      log("Firestore fetch error: $e"); // ✅ Replace print with log
    }

    return {};
  }

  static Future<void> clearSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
