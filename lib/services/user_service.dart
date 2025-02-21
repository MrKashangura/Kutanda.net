import 'dart:developer'; // ✅ Use proper logging

import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.get('role');
      }
    } catch (e) {
      log("Error fetching user role: $e"); // ✅ Replace print with log
    }
    return null;
  }
}
