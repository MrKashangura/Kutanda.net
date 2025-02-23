import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000'; // update as needed
  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt');
  }

  /// Switches role only if current role is 'buyer' or 'seller'.
  /// This function toggles the role: if currentRole is 'buyer', newRole becomes 'seller', and vice versa.
  Future<bool> switchRole(String currentRole) async {
    // Client-side validation: only allow buyer and seller.
    if (currentRole != 'buyer' && currentRole != 'seller') {
      return false;
    }
    String newRole = currentRole == 'buyer' ? 'seller' : 'buyer';

    final token = await getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/switchRole');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'newRole': newRole}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];
        // Save the new token with the updated role.
        await _storage.write(key: 'jwt', value: newToken);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

