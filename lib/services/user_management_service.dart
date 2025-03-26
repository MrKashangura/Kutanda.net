// lib/services/user_management_service.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Get a user's verification history
  Future<List<Map<String, dynamic>>> getUserVerificationHistory(String userId) async {
    try {
      final response = await _supabase
          .from('verification_history')
          .select('*, reviewer:users!reviewer_id(email, display_name)')
          .eq('user_id', userId)
          .order('timestamp', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      log('❌ Error getting user verification history: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Assist with user verification (approve or reject)
  Future<bool> processVerification(
    String userId,
    bool approve,
    String csrId,
    String? notes
  ) async {
    try {
      // Update the seller profile
      await _supabase
          .from('sellers')
          .update({
            'kyc_status': approve ? 'verified' : 'rejected',
            'is_active': approve,
            'verified_by': csrId,
            'verification_notes': notes,
            'verified_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
      
      // Add entry to verification history
      await _supabase
          .from('verification_history')
          .insert({
            'user_id': userId,
            'reviewer_id': csrId,
            'action': approve ? 'approved' : 'rejected',
            'notes': notes,
            'timestamp': DateTime.now().toIso8601String(),
          });
      
      log('✅ User verification processed: $userId, approved: $approve');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error processing verification: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Reset a user's password (generates a password reset link)
  Future<bool> resetUserPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      log('✅ Password reset email sent to: $email');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error sending password reset: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Suspend a user account
  Future<bool> suspendUser(
    String userId, 
    int durationDays,
    String csrId,
    String reason
  ) async {
    try {
      final suspendUntil = DateTime.now().add(Duration(days: durationDays));
      
      await _supabase
          .from('users')
          .update({
            'is_suspended': true,
            'suspended_until': suspendUntil.toIso8601String(),
            'suspended_by': csrId,
            'suspension_reason': reason,
            'suspended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      
      // Add to user action history
      await _supabase
          .from('user_action_history')
          .insert({
            'user_id': userId,
            'action_by': csrId,
            'action_type': 'suspend',
            'reason': reason,
            'duration_days': durationDays,
            'timestamp': DateTime.now().toIso8601String(),
          });
      
      log('✅ User suspended: $userId for $durationDays days');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error suspending user: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Unsuspend a user account
  Future<bool> unsuspendUser(
    String userId,
    String csrId,
    String reason
  ) async {
    try {
      await _supabase
          .from('users')
          .update({
            'is_suspended': false,
            'suspended_until': null,
            'unsuspended_by': csrId,
            'unsuspended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      
      // Add to user action history
      await _supabase
          .from('user_action_history')
          .insert({
            'user_id': userId,
            'action_by': csrId,
            'action_type': 'unsuspend',
            'reason': reason,
            'timestamp': DateTime.now().toIso8601String(),
          });
      
      log('✅ User unsuspended: $userId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error unsuspending user: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Get a user's account action history
  Future<List<Map<String, dynamic>>> getUserActionHistory(String userId) async {
    try {
      final response = await _supabase
          .from('user_action_history')
          .select('*, admin:users!action_by(email, display_name)')
          .eq('user_id', userId)
          .order('timestamp', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      log('❌ Error getting user action history: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Ban a user permanently
  Future<bool> banUser(
    String userId,
    String csrId,
    String reason
  ) async {
    try {
      await _supabase
          .from('users')
          .update({
            'is_banned': true,
            'banned_by': csrId,
            'ban_reason': reason,
            'banned_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      
      // Add to user action history
      await _supabase
          .from('user_action_history')
          .insert({
            'user_id': userId,
            'action_by': csrId,
            'action_type': 'ban',
            'reason': reason,
            'timestamp': DateTime.now().toIso8601String(),
          });
      
      log('✅ User banned: $userId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error banning user: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Unban a user
  Future<bool> unbanUser(
    String userId,
    String csrId,
    String reason
  ) async {
    try {
      await _supabase
          .from('users')
          .update({
            'is_banned': false,
            'unbanned_by': csrId,
            'unbanned_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      
      // Add to user action history
      await _supabase
          .from('user_action_history')
          .insert({
            'user_id': userId,
            'action_by': csrId,
            'action_type': 'unban',
            'reason': reason,
            'timestamp': DateTime.now().toIso8601String(),
          });
      
      log('✅ User unbanned: $userId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error unbanning user: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Add a note to a user's profile
  Future<bool> addUserNote(
    String userId,
    String csrId,
    String note
  ) async {
    try {
      await _supabase
          .from('user_notes')
          .insert({
            'user_id': userId,
            'author_id': csrId,
            'content': note,
            'created_at': DateTime.now().toIso8601String(),
          });
      
      log('✅ Note added to user: $userId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error adding user note: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Get notes for a user
  Future<List<Map<String, dynamic>>> getUserNotes(String userId) async {
    try {
      final response = await _supabase
          .from('user_notes')
          .select('*, author:users!author_id(email, display_name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      log('❌ Error getting user notes: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  /// Get CSR permissions
  Future<Map<String, bool>> getCsrPermissions(String csrId) async {
    try {
      final response = await _supabase
          .from('csr_permissions')
          .select('*')
          .eq('user_id', csrId)
          .maybeSingle();
      
      if (response == null) {
        // Return default permissions if none exist
        return {
          'tickets.view': true,
          'tickets.assign': true,
          'tickets.resolve': true,
          'disputes.view': true,
          'disputes.resolve': false,
          'users.view': true,
          'users.manage': false,
          'content.moderate': true,
          'analytics.view': false,
        };
      }
      
      // Extract permissions from the database response
      Map<String, bool> permissions = {};
      
      // Remove the id and user_id from the response
      final permissionMap = Map<String, dynamic>.from(response);
      permissionMap.remove('id');
      permissionMap.remove('user_id');
      
      // Convert to Map<String, bool>
      permissionMap.forEach((key, value) {
        permissions[key] = value as bool;
      });
      
      return permissions;
    } catch (e, stackTrace) {
      log('❌ Error getting CSR permissions: $e', error: e, stackTrace: stackTrace);
      
      // Return default permissions on error
      return {
        'tickets.view': true,
        'tickets.assign': true,
        'tickets.resolve': true,
        'disputes.view': true,
        'disputes.resolve': false,
        'users.view': true,
        'users.manage': false,
        'content.moderate': true,
        'analytics.view': false,
      };
    }
  }
  
  /// Update CSR permissions
  Future<bool> updateCsrPermissions(String csrId, Map<String, bool> permissions) async {
    try {
      // Add the user_id to the permissions map
      final permissionsData = {
        'user_id': csrId,
        ...permissions,
      };
      
      // Check if permissions already exist
      final existingPermissions = await _supabase
          .from('csr_permissions')
          .select('uid')
          .eq('user_id', csrId)
          .maybeSingle();
      
      if (existingPermissions != null) {
        // Update existing permissions
        await _supabase
            .from('csr_permissions')
            .update(permissionsData)
            .eq('user_id', csrId);
      } else {
        // Insert new permissions
        await _supabase
            .from('csr_permissions')
            .insert(permissionsData);
      }
      
      log('✅ CSR permissions updated: $csrId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error updating CSR permissions: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Deactivate a CSR account
  Future<bool> deactivateCsrAccount(String csrId, String adminId, String reason) async {
    try {
      // Update the user record
      await _supabase
          .from('users')
          .update({
            'is_active': false,
            'deactivated_by': adminId,
            'deactivation_reason': reason,
            'deactivated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', csrId)
          .eq('role', 'csr');
      
      // Add to user action history
      await _supabase
          .from('user_action_history')
          .insert({
            'user_id': csrId,
            'action_by': adminId,
            'action_type': 'deactivate',
            'reason': reason,
            'timestamp': DateTime.now().toIso8601String(),
          });
      
      log('✅ CSR account deactivated: $csrId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error deactivating CSR account: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Reactivate a CSR account
  Future<bool> reactivateCsrAccount(String csrId, String adminId, String reason) async {
    try {
      // Update the user record
      await _supabase
          .from('users')
          .update({
            'is_active': true,
            'reactivated_by': adminId,
            'reactivation_reason': reason,
            'reactivated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', csrId)
          .eq('role', 'csr');
      
      // Add to user action history
      await _supabase
          .from('user_action_history')
          .insert({
            'user_id': csrId,
            'action_by': adminId,
            'action_type': 'reactivate',
            'reason': reason,
            'timestamp': DateTime.now().toIso8601String(),
          });
      
      log('✅ CSR account reactivated: $csrId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error reactivating CSR account: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Create a new CSR account
  Future<Map<String, dynamic>?> createCsrAccount(
    String email,
    String displayName,
    String password,
    String adminId
  ) async {
    try {
      // Create the auth account
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Failed to create auth account');
      }
      
      final userId = response.user!.id;
      
      // Create the user record
      await _supabase
          .from('users')
          .insert({
            'id': userId,
            'email': email,
            'display_name': displayName,
            'role': 'csr',
            'is_active': true,
            'created_by': adminId,
            'created_at': DateTime.now().toIso8601String(),
          });
      
      // Set default permissions
      await updateCsrPermissions(userId, {
        'tickets.view': true,
        'tickets.assign': true,
        'tickets.resolve': true,
        'disputes.view': true,
        'disputes.resolve': false,
        'users.view': true,
        'users.manage': false,
        'content.moderate': true,
        'analytics.view': false,
      });
      
      // Add to user action history
      await _supabase
          .from('user_action_history')
          .insert({
            'user_id': userId,
            'action_by': adminId,
            'action_type': 'create',
            'reason': 'New CSR account creation',
            'timestamp': DateTime.now().toIso8601String(),
          });
      
      log('✅ CSR account created: $userId');
      
      // Return the new user info
      return {
        'id': userId,
        'email': email,
        'display_name': displayName,
        'role': 'csr',
      };
    } catch (e, stackTrace) {
      log('❌ Error creating CSR account: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  /// Get users with optional filtering
  Future<List<Map<String, dynamic>>> getUsers({
    String? searchQuery,
    String? roleFilter,
    bool? onlyReported,
  }) async {
    try {
      var query = _supabase.from('users').select();
      
      // Apply filters if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('display_name.ilike.%$searchQuery%,email.ilike.%$searchQuery%');
      }
      
      if (roleFilter != null) {
        query = query.eq('role', roleFilter);
      }
      
      if (onlyReported == true) {
        query = query.eq('is_reported', true);
      }
      
      final response = await query.order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      log('Error getting users: $e');
      return [];
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      log('Error getting user profile: $e');
      return null;
    }
  }
  
  /// Update user permissions
  Future<bool> updateUserPermissions(String userId, Map<String, bool> permissions) async {
    try {
      // First, check if user exists
      final userExists = await _supabase
        .from('users')
        .select('id')
        .eq('id', userId)
        .maybeSingle();
        
      if (userExists == null) {
        throw Exception('User not found');
      }
      
      // Check if permissions table exists, if not create it
      await _supabase
        .from('user_permissions')
        .upsert({
          'user_id': userId,
          'permissions': permissions,
          'updated_at': DateTime.now().toIso8601String(),
        });
      
      return true;
    } catch (e) {
      log('Error updating user permissions: $e');
      return false;
    }
  }
  
  /// Deactivate a CSR account
  Future<bool> deactivateCSR(String csrId) async {
    try {
      // Update the user record to mark as inactive
      await _supabase
        .from('users')
        .update({
          'is_active': false,
          'deactivated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', csrId);
      
      // Log the action
      await _supabase
        .from('user_action_history')
        .insert({
          'user_id': csrId,
          'action_type': 'deactivate',
          'action_by': _supabase.auth.currentUser?.id,
          'timestamp': DateTime.now().toIso8601String(),
          'notes': 'CSR account deactivated',
        });
      
      return true;
    } catch (e) {
      log('Error deactivating CSR account: $e');
      return false;
    }
  }
  
  /// Get user registration statistics
  Future<Map<String, dynamic>> getUserRegistrationStats({
    int? lastDays,
  }) async {
    try {
      final now = DateTime.now();
      final startDate = lastDays != null 
        ? now.subtract(Duration(days: lastDays))
        : now.subtract(const Duration(days: 30)); // Default to 30 days
      
      final startDateString = startDate.toIso8601String();
      
      // Get total users registered in the period
      final totalUsersResponse = await _supabase
        .from('users')
        .select('id')
        .gte('created_at', startDateString)
        .count();
      
      final totalUsers = totalUsersResponse.count;
      
      // Get users by role
      final roleTypes = ['buyer', 'seller', 'csr', 'admin'];
      Map<String, int> registrationsByRole = {};
      
      for (final role in roleTypes) {
        final response = await _supabase
          .from('users')
          .select('id')
          .eq('role', role)
          .gte('created_at', startDateString)
          .count();
        
        registrationsByRole[role] = response.count;
      }
      
      return {
        'total_users': totalUsers,
        'registrations_by_role': registrationsByRole,
        'period_days': lastDays ?? 30,
      };
    } catch (e) {
      log('Error getting user registration stats: $e');
      return {
        'total_users': 0,
        'registrations_by_role': {},
        'period_days': lastDays ?? 30,
      };
    }
  }
  
  /// Get verification statistics
  Future<Map<String, dynamic>> getVerificationStats({
    int? lastDays,
  }) async {
    try {
      final now = DateTime.now();
      final startDate = lastDays != null 
        ? now.subtract(Duration(days: lastDays))
        : now.subtract(const Duration(days: 30)); // Default to 30 days
      
      final startDateString = startDate.toIso8601String();
      
      // Get total verifications
      final totalVerificationsResponse = await _supabase
        .from('verification_requests')
        .select('id')
        .gte('created_at', startDateString)
        .count();
      
      final totalVerifications = totalVerificationsResponse.count;
      
      // Get approved verifications
      final approvedResponse = await _supabase
        .from('verification_requests')
        .select('id')
        .eq('status', 'approved')
        .gte('created_at', startDateString)
        .count();
      
      final approved = approvedResponse.count;
      
      // Get rejected verifications
      final rejectedResponse = await _supabase
        .from('verification_requests')
        .select('id')
        .eq('status', 'rejected')
        .gte('created_at', startDateString)
        .count();
      
      final rejected = rejectedResponse.count;
      
      // Calculate approval rate
      final approvalRate = totalVerifications > 0 
        ? approved / totalVerifications 
        : 0.0;
      
      return {
        'total_verifications': totalVerifications,
        'approved': approved,
        'rejected': rejected,
        'approval_rate': approvalRate,
        'period_days': lastDays ?? 30,
      };
    } catch (e) {
      log('Error getting verification stats: $e');
      return {
        'total_verifications': 0,
        'approved': 0,
        'rejected': 0,
        'approval_rate': 0.0,
        'period_days': lastDays ?? 30,
      };
    }
  }
}