// lib/services/user_management_service.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Get all users with pagination and search
  Future<List<Map<String, dynamic>>> getUsers({
    String? searchQuery,
    String? roleFilter,
    bool? onlyReported,
    bool? onlySuspended,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('users')
          .select('id, email, display_name, role, created_at, is_reported, is_suspended, is_banned');
      
      // Apply filters
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('email.ilike.%$searchQuery%,display_name.ilike.%$searchQuery%');
      }
      
      if (roleFilter != null) {
        query = query.eq('role', roleFilter);
      }
      
      if (onlyReported == true) {
        query = query.eq('is_reported', true);
      }
      
      if (onlySuspended == true) {
        query = query.eq('is_suspended', true);
      }
      
      // Apply pagination and ordering
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      log('❌ Error getting users: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Get a single user's complete profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final userResponse = await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();
      
      // Get the user's KYC status if they're a seller
      final sellerProfile = await _supabase
          .from('sellers')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();
      
      // Get the user's activity statistics
      final auctionsCreated = await _supabase
          .from('auctions')
          .select('id')
          .eq('seller_id', userId)
          .count();
      
      final bidsPlaced = await _supabase
          .from('bids')
          .select('id')
          .eq('bidder_id', userId)
          .count();
      
      final reviewsReceived = await _supabase
          .from('reviews')
          .select('id')
          .eq('user_id', userId)
          .count();
      
      final supportTickets = await _supabase
          .from('support_tickets')
          .select('id, status')
          .eq('user_id', userId);
      
      // Count tickets by status
      Map<String, int> ticketsByStatus = {};
      for (final ticket in supportTickets) {
        final status = ticket['status'] as String;
        ticketsByStatus[status] = (ticketsByStatus[status] ?? 0) + 1;
      }
      
      final userProfile = {
        ...Map<String, dynamic>.from(userResponse),
        'seller_profile': sellerProfile,
        'activity': {
          'auctions_created': auctionsCreated,
          'bids_placed': bidsPlaced,
          'reviews_received': reviewsReceived,
          'total_tickets': supportTickets.length,
          'tickets_by_status': ticketsByStatus,
        }
      };
      
      return userProfile;
    } catch (e, stackTrace) {
      log('❌ Error getting user profile: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
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
  
  /// Get user registration statistics for analytics
  Future<Map<String, dynamic>> getUserRegistrationStats({int? lastDays}) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('users')
          .select('created_at, role');
      
      // Filter by date range if specified
      if (lastDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
        query = query.gte('created_at', cutoffDate.toIso8601String());
      }
      
      final users = await query;
      
      // Group by day
      Map<String, int> registrationsByDay = {};
      
      // Group by role
      Map<String, int> registrationsByRole = {
        'buyer': 0,
        'seller': 0,
        'admin': 0,
        'csr': 0,
      };
      
      for (final user in users) {
        final date = DateTime.parse(user['created_at']).toIso8601String().split('T')[0];
        registrationsByDay[date] = (registrationsByDay[date] ?? 0) + 1;
        
        final role = user['role'] as String;
        registrationsByRole[role] = (registrationsByRole[role] ?? 0) + 1;
      }
      
      return {
        'total_users': users.length,
        'registrations_by_day': registrationsByDay,
        'registrations_by_role': registrationsByRole,
      };
    } catch (e, stackTrace) {
      log('❌ Error getting user registration stats: $e', error: e, stackTrace: stackTrace);
      return {};
    }
  }
  
  /// Get verification statistics
  Future<Map<String, dynamic>> getVerificationStats({int? lastDays}) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('verification_history')
          .select('action, timestamp');
      
      // Filter by date range if specified
      if (lastDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
        query = query.gte('timestamp', cutoffDate.toIso8601String());
      }
      
      final verifications = await query;
      
      // Count by action type
      int approved = 0;
      int rejected = 0;
      
      for (final verification in verifications) {
        if (verification['action'] == 'approved') {
          approved++;
        } else if (verification['action'] == 'rejected') {
          rejected++;
        }
      }
      
      // Group by day
      Map<String, Map<String, int>> verificationsByDay = {};
      
      for (final verification in verifications) {
        final date = DateTime.parse(verification['timestamp']).toIso8601String().split('T')[0];
        final action = verification['action'] as String;
        
        if (!verificationsByDay.containsKey(date)) {
          verificationsByDay[date] = {'approved': 0, 'rejected': 0};
        }
        
        verificationsByDay[date]![action] = (verificationsByDay[date]![action] ?? 0) + 1;
      }
      
      return {
        'total_verifications': verifications.length,
        'approved': approved,
        'rejected': rejected,
        'approval_rate': verifications.isNotEmpty ? approved / verifications.length : 0,
        'verifications_by_day': verificationsByDay,
      };
    } catch (e, stackTrace) {
      log('❌ Error getting verification stats: $e', error: e, stackTrace: stackTrace);
      return {};
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
          .select('id')
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
}