// lib/services/api_service.dart
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/services/role_service.dart';

class ApiService {
  static const String baseUrl = 'https://api.kutanda.com'; // Replace with your actual API URL
  final _storage = const FlutterSecureStorage();
  final _roleService = RoleService();
  final SupabaseClient supabase;

  // Allow SupabaseClient injection for testing, default to Supabase.instance.client for production
  ApiService({SupabaseClient? supabaseInstance}) : supabase = supabaseInstance ?? Supabase.instance.client;

  /// Get the token from secure storage
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt');
  }

  /// Switch between buyer and seller role
  Future<bool> switchRole(String currentRole) async {
    try {
      log('Switching from $currentRole to ${currentRole == "buyer" ? "seller" : "buyer"}');
      
      // Use RoleService to handle role switching
      return await _roleService.switchRole(
        currentRole == "buyer" ? "seller" : "buyer"
      );
    } catch (e) {
      log('Error switching role: $e');
      return false;
    }
  }

  /// Make authenticated GET request
  Future<Map<String, dynamic>?> get(String endpoint) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        log('No authenticated user');
        return null;
      }
      
      final response = await supabase.functions.invoke(endpoint);
      
      if (response.status != 200) {
        log('Error: ${response.status}');
        return null;
      }
      
      return response.data;
    } catch (e) {
      log('Error making GET request: $e');
      return null;
    }
  }

  /// Make authenticated POST request
  Future<Map<String, dynamic>?> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        log('No authenticated user');
        return null;
      }
      
      final response = await supabase.functions.invoke(
        endpoint,
        body: data,
      );
      
      if (response.status != 200) {
        log('Error: ${response.status}');
        return null;
      }
      
      return response.data;
    } catch (e) {
      log('Error making POST request: $e');
      return null;
    }
  }

  /// Make authenticated PUT request
  Future<Map<String, dynamic>?> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        log('No authenticated user');
        return null;
      }

      final response = await supabase.functions.invoke(
        endpoint,
        method: HttpMethod.put,
        body: data,
      );

      if (response.status != 200) {
        log('Error: ${response.status}');
        return null;
      }

      return response.data;
    } catch (e) {
      log('Error making PUT request: $e');
      return null;
    }
  }

  /// Make authenticated DELETE request
  Future<Map<String, dynamic>?> delete(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        log('No authenticated user');
        return null;
      }

      final response = await supabase.functions.invoke(
        endpoint,
        method: HttpMethod.delete,
        body: data,
      );

      if (response.status != 200) {
        log('Error: ${response.status}');
        return null;
      }

      return response.data;
    } catch (e) {
      log('Error making DELETE request: $e');
      return null;
    }
  }

  /// Make authenticated PATCH request
  Future<Map<String, dynamic>?> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        log('No authenticated user');
        return null;
      }

      final response = await supabase.functions.invoke(
        endpoint,
        method: HttpMethod.patch,
        body: data,
      );

      if (response.status != 200) {
        log('Error: ${response.status}');
        return null;
      }

      return response.data;
    } catch (e) {
      log('Error making PATCH request: $e');
      return null;
    }
  }
}