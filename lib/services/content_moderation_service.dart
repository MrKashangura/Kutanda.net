// lib/services/content_moderation_service.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/support_ticket_model.dart';

class ContentModerationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Get all pending auction listings that need approval
  Future<List<Map<String, dynamic>>> getPendingAuctions() async {
    try {
      final response = await _supabase
          .from('auctions')
          .select('*, users!inner(email, display_name)')
          .eq('is_approved', false)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      log('❌ Error getting pending auctions: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Approve or reject an auction listing
  Future<bool> moderateAuction(
    String auctionId,
    bool approve, 
    String moderatorId,
    String? rejectionReason
  ) async {
    try {
      if (approve) {
        await _supabase
            .from('auctions')
            .update({
              'is_approved': true,
              'moderator_id': moderatorId,
              'approved_at': DateTime.now().toIso8601String()
            })
            .eq('id', auctionId);
        
        log('✅ Auction approved: $auctionId');
      } else {
        await _supabase
            .from('auctions')
            .update({
              'is_approved': false,
              'is_active': false,
              'moderator_id': moderatorId,
              'rejection_reason': rejectionReason,
              'rejected_at': DateTime.now().toIso8601String()
            })
            .eq('id', auctionId);
        
        log('✅ Auction rejected: $auctionId');
      }
      
      return true;
    } catch (e, stackTrace) {
      log('❌ Error moderating auction: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Get all reported reviews
  Future<List<Map<String, dynamic>>> getReportedReviews() async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('*, reporter:users!reporter_id(email, display_name), author:users!author_id(email, display_name)')
          .eq('is_reported', true)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      log('❌ Error getting reported reviews: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Moderate a review (keep or remove)
  Future<bool> moderateReview(
    String reviewId,
    bool keep, 
    String moderatorId,
    String? moderationNotes
  ) async {
    try {
      if (keep) {
        await _supabase
            .from('reviews')
            .update({
              'is_reported': false,
              'is_visible': true,
              'moderator_id': moderatorId,
              'moderation_notes': moderationNotes,
              'moderated_at': DateTime.now().toIso8601String()
            })
            .eq('id', reviewId);
        
        log('✅ Review kept visible: $reviewId');
      } else {
        await _supabase
            .from('reviews')
            .update({
              'is_visible': false,
              'moderator_id': moderatorId,
              'moderation_notes': moderationNotes,
              'moderated_at': DateTime.now().toIso8601String()
            })
            .eq('id', reviewId);
        
        log('✅ Review hidden: $reviewId');
      }
      
      return true;
    } catch (e, stackTrace) {
      log('❌ Error moderating review: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Get all content reports with related content details
  Future<List<Map<String, dynamic>>> getContentReportsWithDetails() async {
    try {
      final reports = await _supabase
          .from('content_reports')
          .select('*, reporter:users!reporter_id(email, display_name)')
          .eq('status', ContentReportStatus.pending.toString().split('.').last)
          .order('created_at', ascending: false);
      
      List<Map<String, dynamic>> enrichedReports = [];
      
      // Fetch additional details based on content type
      for (final report in reports) {
        final contentType = report['content_type'];
        final contentId = report['content_id'];
        
        Map<String, dynamic> contentDetails = {};
        
        switch (contentType) {
          case 'auction':
            final auctionDetails = await _supabase
                .from('auctions')
                .select('title, description, seller_id, starting_price')
                .eq('id', contentId)
                .maybeSingle();
            
            if (auctionDetails != null) {
              contentDetails = Map<String, dynamic>.from(auctionDetails);
            }
            break;
            
          case 'review':
            final reviewDetails = await _supabase
                .from('reviews')
                .select('content, rating, author_id')
                .eq('id', contentId)
                .maybeSingle();
            
            if (reviewDetails != null) {
              contentDetails = Map<String, dynamic>.from(reviewDetails);
            }
            break;
            
          case 'user':
            final userDetails = await _supabase
                .from('users')
                .select('email, display_name')
                .eq('id', contentId)
                .maybeSingle();
            
            if (userDetails != null) {
              contentDetails = Map<String, dynamic>.from(userDetails);
            }
            break;
            
          case 'message':
            final messageDetails = await _supabase
                .from('ticket_messages')
                .select('content, sender_id')
                .eq('id', contentId)
                .maybeSingle();
            
            if (messageDetails != null) {
              contentDetails = Map<String, dynamic>.from(messageDetails);
            }
            break;
        }
        
        enrichedReports.add({
          ...Map<String, dynamic>.from(report),
          'content_details': contentDetails,
        });
      }
      
      return enrichedReports;
    } catch (e, stackTrace) {
      log('❌ Error getting content reports with details: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Get all reported users
  Future<List<Map<String, dynamic>>> getReportedUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('is_reported', true)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      log('❌ Error getting reported users: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Take action on a reported user
  Future<bool> moderateUser(
    String userId,
    String action, // 'warn', 'suspend', 'ban', or 'clear'
    String moderatorId,
    String? moderationNotes
  ) async {
    try {
      Map<String, dynamic> updateData = {
        'moderated_by': moderatorId,
        'moderation_notes': moderationNotes,
        'moderated_at': DateTime.now().toIso8601String(),
        'is_reported': false,
      };
      
      // Add action-specific fields
      switch (action) {
        case 'warn':
          updateData['is_warned'] = true;
          updateData['warned_at'] = DateTime.now().toIso8601String();
          break;
          
        case 'suspend':
          updateData['is_suspended'] = true;
          updateData['suspended_until'] = DateTime.now()
              .add(const Duration(days: 7))
              .toIso8601String();
          break;
          
        case 'ban':
          updateData['is_banned'] = true;
          updateData['banned_at'] = DateTime.now().toIso8601String();
          break;
          
        case 'clear':
          updateData['is_warned'] = false;
          updateData['is_suspended'] = false;
          updateData['is_banned'] = false;
          break;
      }
      
      await _supabase
          .from('users')
          .update(updateData)
          .eq('id', userId);
      
      log('✅ User moderated: $userId, action: $action');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error moderating user: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Get moderation activity log
  Future<List<Map<String, dynamic>>> getModerationLogs({int limit = 50, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('moderation_logs')
          .select('*, moderator:users!moderator_id(email, display_name)')
          .order('timestamp', ascending: false)
          .range(offset, offset + limit - 1);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      log('❌ Error getting moderation logs: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Log a moderation action
  Future<bool> logModeration(
    String moderatorId,
    String actionType,
    String contentType,
    String contentId,
    String? notes
  ) async {
    try {
      await _supabase
          .from('moderation_logs')
          .insert({
            'moderator_id': moderatorId,
            'action_type': actionType,
            'content_type': contentType,
            'content_id': contentId,
            'notes': notes,
            'timestamp': DateTime.now().toIso8601String(),
          });
      
      return true;
    } catch (e, stackTrace) {
      log('❌ Error logging moderation action: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Get content moderation statistics
  Future<Map<String, dynamic>> getModerationStats({int? lastDays}) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('moderation_logs')
          .select('action_type, content_type');
      
      // Filter by date range if specified
      if (lastDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
        query = query.gte('timestamp', cutoffDate.toIso8601String());
      }
      
      final logs = await query;
      
      // Count by action type
      Map<String, int> actionCounts = {};
      for (final log in logs) {
        final actionType = log['action_type'] as String;
        actionCounts[actionType] = (actionCounts[actionType] ?? 0) + 1;
      }
      
      // Count by content type
      Map<String, int> contentTypeCounts = {};
      for (final log in logs) {
        final contentType = log['content_type'] as String;
        contentTypeCounts[contentType] = (contentTypeCounts[contentType] ?? 0) + 1;
      }
      
      // Calculate approval/rejection rates for auctions
      int auctionsApproved = 0;
      int auctionsRejected = 0;
      
      for (final log in logs) {
        if (log['content_type'] == 'auction') {
          if (log['action_type'] == 'approve') {
            auctionsApproved++;
          } else if (log['action_type'] == 'reject') {
            auctionsRejected++;
          }
        }
      }
      
      double auctionApprovalRate = (auctionsApproved + auctionsRejected) > 0
          ? auctionsApproved / (auctionsApproved + auctionsRejected)
          : 0;
      
      return {
        'total_actions': logs.length,
        'actions_by_type': actionCounts,
        'actions_by_content_type': contentTypeCounts,
        'auction_approval_rate': auctionApprovalRate,
      };
    } catch (e, stackTrace) {
      log('❌ Error getting moderation stats: $e', error: e, stackTrace: stackTrace);
      return {};
    }
  }
}