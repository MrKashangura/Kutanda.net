// lib/data/repositories/user_repository.dart
import 'dart:developer';

// import 'package:supabase_flutter/supabase_flutter.dart'; // SupabaseClient no longer directly needed for most operations
import '../models/user_model.dart';
import '../../services/api_service.dart'; // Import ApiService

class UserRepository {
  final ApiService _apiService;

  // Allow ApiService injection for testing
  UserRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Get user profile by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Supabase GET request with `limit=1` on a unique ID will return an array with one or zero elements.
      final response = await _apiService.get('users?id=eq.$userId&limit=1');
      
      if (response != null && response['data'] is List) {
        final dataList = response['data'] as List;
        if (dataList.isNotEmpty) {
          return UserModel.fromJson(dataList.first as Map<String, dynamic>);
        }
      }
      log('❌ Error fetching user: User not found or invalid response. UserId: $userId');
      return null;
    } catch (e, stackTrace) {
      log('❌ Error fetching user: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get user role
  Future<String?> getUserRole(String userId) async {
    try {
      // Fetching a specific field 'role' for a user.
      // The 'uid' field is used here as per the original Supabase query.
      final response = await _apiService.get('users?uid=eq.$userId&select=role&limit=1');

      if (response != null && response['data'] is List) {
        final dataList = response['data'] as List;
        if (dataList.isNotEmpty && dataList.first is Map) {
          final userData = dataList.first as Map<String, dynamic>;
          return userData['role'] as String?;
        }
      }
      log('❌ Error fetching user role: Role not found or invalid response. UserId: $userId');
      return null;
    } catch (e, stackTrace) {
      log('❌ Error fetching user role: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Create a new user
  Future<bool> createUser(UserModel user) async {
    try {
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'phone': user.phone,
        'role': user.activeRole,
        // 'created_at' is typically handled by the database automatically on insert
      };
      final response = await _apiService.post('users', userData);
      
      // Assuming the ApiService's post method returns a non-null response on success (e.g., the created object or a success status)
      if (response != null) {
        log('✅ User created: ${user.uid}');
        return true;
      }
      log('❌ Error creating user: Response was null. UserId: ${user.uid}');
      return false;
    } catch (e, stackTrace) {
      log('❌ Error creating user: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateUser(UserModel user) async {
    try {
      final userData = {
        'email': user.email,
        'phone': user.phone,
        'role': user.activeRole,
        // 'updated_at' is typically handled by the database automatically on update
      };
      // Using PUT to update the user. The endpoint identifies the user by uid.
      // Alternatively, _apiService.patch could be used if the backend supports partial updates.
      final response = await _apiService.put('users?uid=eq.${user.uid}', userData);
      
      if (response != null) { // Assuming success if response is not null
        log('✅ User updated: ${user.uid}');
        return true;
      }
      log('❌ Error updating user: Response was null. UserId: ${user.uid}');
      return false;
    } catch (e, stackTrace) {
      log('❌ Error updating user: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      // Using DELETE to remove the user. The endpoint identifies the user by uid.
      final response = await _apiService.delete('users?uid=eq.$userId');
      
      if (response != null) { // Assuming success if response is not null
        log('✅ User deleted: $userId');
        return true;
      }
      log('❌ Error deleting user: Response was null. UserId: $userId');
      return false;
    } catch (e, stackTrace) {
      log('❌ Error deleting user: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get all users (admin/CSR function)
  Future<List<UserModel>> getAllUsers({
    String? searchQuery, 
    String? roleFilter
  }) async {
    try {
      String queryString = 'users?select=*'; // Base query
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Supabase syntax for OR condition on multiple fields for search
        queryString += '&or=(email.ilike.%$searchQuery%,phone.ilike.%$searchQuery%)';
      }
      
      if (roleFilter != null && roleFilter.isNotEmpty) {
        queryString += '&role=eq.$roleFilter';
      }
      
      final response = await _apiService.get(queryString);
      
      if (response != null && response['data'] is List) {
        final dataList = response['data'] as List;
        return dataList.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      log('❌ Error fetching users: Response was null or not a list.');
      return [];
    } catch (e, stackTrace) {
      log('❌ Error fetching users: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      // Query for users with the given email. We only need to know if at least one exists.
      final response = await _apiService.get('users?email=eq.$email&select=email&limit=1');
      
      if (response != null && response['data'] is List) {
        final dataList = response['data'] as List;
        return dataList.isNotEmpty; // True if the list is not empty (email exists)
      }
      // If response is null or data is not a list, assume email does not exist or an error occurred.
      // Logging this as an error might be too noisy if it's common for checks on non-existent emails.
      // However, if response is null, it indicates a problem with the service call.
      if (response == null) {
        log('❌ Error checking email: API response was null. Email: $email');
      }
      return false;
    } catch (e, stackTrace) {
      log('❌ Error checking email: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Check if phone exists
  Future<bool> phoneExists(String phone) async {
    try {
      // Query for users with the given phone number. We only need to know if at least one exists.
      final response = await _apiService.get('users?phone=eq.$phone&select=phone&limit=1');
      
      if (response != null && response['data'] is List) {
        final dataList = response['data'] as List;
        return dataList.isNotEmpty; // True if the list is not empty (phone exists)
      }
      // If response is null or data is not a list, assume phone does not exist or an error occurred.
      if (response == null) {
        log('❌ Error checking phone: API response was null. Phone: $phone');
      }
      return false;
    } catch (e, stackTrace) {
      log('❌ Error checking phone: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}