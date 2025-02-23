import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../services/api_service.dart';

class RoleSwitchScreen extends StatefulWidget {
  const RoleSwitchScreen({super.key});

  @override
  State<RoleSwitchScreen> createState() => _RoleSwitchScreenState();
}

class _RoleSwitchScreenState extends State<RoleSwitchScreen> {
  final _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();
  String activeRole = 'buyer';

  @override
  void initState() {
    super.initState();
    _loadActiveRole();
  }

  Future<void> _loadActiveRole() async {
    final token = await _storage.read(key: 'jwt');
    if (token != null) {
      final decoded = JwtDecoder.decode(token);
      if (!mounted) return;
      setState(() {
        activeRole = decoded['activeRole'] ?? 'buyer';
      });
    }
  }

  Future<void> _switchRole() async {
    final newRole = activeRole == 'buyer' ? 'seller' : 'buyer';
    bool success = await _apiService.switchRole(newRole);
    if (!mounted) return;
    if (success) {
      setState(() {
        activeRole = newRole;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to $newRole mode')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to switch role')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Switch Role')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Current Role: ${activeRole.toUpperCase()}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _switchRole,
              child: Text('Switch to ${activeRole == 'buyer' ? 'Seller' : 'Buyer'}'),
            ),
          ],
        ),
      ),
    );
  }
}