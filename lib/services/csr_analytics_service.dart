// lib/services/csr_analytics_service.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/support_ticket_model.dart';

class CsrAnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Get overall support ticket statistics
  Future<Map<String, dynamic>> getTicketStats({int? lastDays}) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('support_tickets')
          .select('status, created_at, last_updated, assigned_csr_id');
      
      // Filter by date range if specified
      if (lastDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
        query = query.gte('created_at', cutoffDate.toIso8601String());
      }
      
      final tickets = await query;
      
      if (tickets.isEmpty) {
        return {
          'total_tickets': 0,
          'tickets_by_status': {},
          'average_resolution_time': null,
          'tickets_by_day': {},
        };
      }
      
      // Count by status
      Map<String, int> ticketsByStatus = {};
      for (final ticket in tickets) {
        final status = ticket['status'] as String;
        ticketsByStatus[status] = (ticketsByStatus[status] ?? 0) + 1;
      }
      
      // Calculate average resolution time
      List<Duration> resolutionTimes = [];
      for (final ticket in tickets) {
        if (ticket['status'] == TicketStatus.resolved.toString().split('.').last && 
            ticket['last_updated'] != null) {
          final createdAt = DateTime.parse(ticket['created_at']);
          final resolvedAt = DateTime.parse(ticket['last_updated']);
          resolutionTimes.add(resolvedAt.difference(createdAt));
        }
      }
      
      Duration? averageResolutionTime;
      if (resolutionTimes.isNotEmpty) {
        final totalMilliseconds = resolutionTimes
            .map((d) => d.inMilliseconds)
            .reduce((a, b) => a + b);
        averageResolutionTime = Duration(
            milliseconds: totalMilliseconds ~/ resolutionTimes.length);
      }
      
      // Group by day
      Map<String, int> ticketsByDay = {};
      for (final ticket in tickets) {
        final date = DateTime.parse(ticket['created_at']).toIso8601String().split('T')[0];
        ticketsByDay[date] = (ticketsByDay[date] ?? 0) + 1;
      }
      
      // Count unassigned tickets
      int unassignedTickets = 0;
      for (final ticket in tickets) {
        if (ticket['assigned_csr_id'] == null) {
          unassignedTickets++;
        }
      }
      
      return {
        'total_tickets': tickets.length,
        'tickets_by_status': ticketsByStatus,
        'average_resolution_time': averageResolutionTime,
        'tickets_by_day': ticketsByDay,
        'unassigned_tickets': unassignedTickets,
      };
    } catch (e, stackTrace) {
      log('❌ Error getting ticket stats: $e', error: e, stackTrace: stackTrace);
      return {};
    }
  }
  
  /// Get performance metrics for all CSRs
  Future<List<Map<String, dynamic>>> getAllCsrPerformance({int? lastDays}) async {
    try {
      // First, get all CSR users
      final csrUsers = await _supabase
          .from('users')
          .select('id, email, display_name')
          .eq('role', 'csr');
      
      List<Map<String, dynamic>> csrPerformance = [];
      
      for (final csr in csrUsers) {
        final csrId = csr['id'];
        final metrics = await _getCsrMetrics(csrId, lastDays: lastDays);
        
        csrPerformance.add({
          'csr_id': csrId,
          'email': csr['email'],
          'display_name': csr['display_name'],
          ...metrics,
        });
      }
      
      return csrPerformance;
    } catch (e, stackTrace) {
      log('❌ Error getting all CSR performance: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Get detailed performance metrics for a specific CSR
  Future<Map<String, dynamic>> getCsrPerformance(String csrId, {int? lastDays}) async {
    try {
      // Get CSR user details
      final csr = await _supabase
          .from('users')
          .select('email, display_name')
          .eq('id', csrId)
          .single();
      
      final metrics = await _getCsrMetrics(csrId, lastDays: lastDays);
      
      return {
        'csr_id': csrId,
        'email': csr['email'],
        'display_name': csr['display_name'],
        ...metrics,
      };
    } catch (e, stackTrace) {
      log('❌ Error getting CSR performance: $e', error: e, stackTrace: stackTrace);
      return {};
    }
  }
  
  /// Helper function to get metrics for a specific CSR
  Future<Map<String, dynamic>> _getCsrMetrics(String csrId, {int? lastDays}) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('support_tickets')
          .select('id, status, created_at, last_updated, type')
          .eq('assigned_csr_id', csrId);
      
      // Filter by date range if specified
      if (lastDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
        query = query.gte('created_at', cutoffDate.toIso8601String());
      }
      
      final tickets = await query;
      
      if (tickets.isEmpty) {
        return {
          'total_tickets': 0,
          'resolved_tickets': 0,
          'resolution_rate': 0,
          'average_resolution_time': null,
          'tickets_by_type': {},
          'tickets_by_status': {},
        };
      }
      
      // Count resolved tickets and calculate resolution time
      int resolvedTickets = 0;
      List<Duration> resolutionTimes = [];
      
      for (final ticket in tickets) {
        if (ticket['status'] == TicketStatus.resolved.toString().split('.').last && 
            ticket['last_updated'] != null) {
          resolvedTickets++;
          
          final createdAt = DateTime.parse(ticket['created_at']);
          final resolvedAt = DateTime.parse(ticket['last_updated']);
          resolutionTimes.add(resolvedAt.difference(createdAt));
        }
      }
      
      // Calculate average resolution time
      Duration? averageResolutionTime;
      if (resolutionTimes.isNotEmpty) {
        final totalMilliseconds = resolutionTimes
            .map((d) => d.inMilliseconds)
            .reduce((a, b) => a + b);
        averageResolutionTime = Duration(
            milliseconds: totalMilliseconds ~/ resolutionTimes.length);
      }
      
      // Count by ticket type
      Map<String, int> ticketsByType = {};
      for (final ticket in tickets) {
        final type = ticket['type'] as String;
        ticketsByType[type] = (ticketsByType[type] ?? 0) + 1;
      }
      
      // Count by ticket status
      Map<String, int> ticketsByStatus = {};
      for (final ticket in tickets) {
        final status = ticket['status'] as String;
        ticketsByStatus[status] = (ticketsByStatus[status] ?? 0) + 1;
      }
      
      // Get moderation actions
      final moderationActions = await _supabase
          .from('moderation_logs')
          .select('id')
          .eq('moderator_id', csrId)
          .count();
      
      // Get dispute resolutions
      final disputesResolved = await _supabase
          .from('dispute_tickets')
          .select('id')
          .eq('resolved_by', csrId)
          .count();
      
      return {
        'total_tickets': tickets.length,
        'resolved_tickets': resolvedTickets,
        'resolution_rate': tickets.isNotEmpty ? resolvedTickets / tickets.length : 0,
        'average_resolution_time': averageResolutionTime,
        'tickets_by_type': ticketsByType,
        'tickets_by_status': ticketsByStatus,
        'moderation_actions': moderationActions,
        'disputes_resolved': disputesResolved,
      };
    } catch (e, stackTrace) {
      log('❌ Error getting CSR metrics: $e', error: e, stackTrace: stackTrace);
      return {};
    }
  }
  
  /// Get detailed resolution time statistics
  Future<Map<String, dynamic>> getResolutionTimeStats({int? lastDays}) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('support_tickets')
          .select('created_at, last_updated, status, type, priority')
          .eq('status', TicketStatus.resolved.toString().split('.').last);
      
      // Filter by date range if specified
      if (lastDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
        query = query.gte('created_at', cutoffDate.toIso8601String());
      }
      
      final resolvedTickets = await query;
      
      if (resolvedTickets.isEmpty) {
        return {
          'overall_average': null,
          'by_type': {},
          'by_priority': {},
        };
      }
      
      // Calculate overall average
      List<Duration> allResolutionTimes = [];
      Map<String, List<Duration>> timesByType = {};
      Map<String, List<Duration>> timesByPriority = {};
      
      for (final ticket in resolvedTickets) {
        final createdAt = DateTime.parse(ticket['created_at']);
        final resolvedAt = DateTime.parse(ticket['last_updated']);
        final duration = resolvedAt.difference(createdAt);
        
        allResolutionTimes.add(duration);
        
        // Group by type
        final type = ticket['type'] as String;
        if (!timesByType.containsKey(type)) {
          timesByType[type] = [];
        }
        timesByType[type]!.add(duration);
        
        // Group by priority
        final priority = ticket['priority'] as String;
        if (!timesByPriority.containsKey(priority)) {
          timesByPriority[priority] = [];
        }
        timesByPriority[priority]!.add(duration);
      }
      
      // Calculate average resolution time
      final totalMilliseconds = allResolutionTimes
          .map((d) => d.inMilliseconds)
          .reduce((a, b) => a + b);
      final overallAverage = Duration(
          milliseconds: totalMilliseconds ~/ allResolutionTimes.length);
      
      // Calculate averages by type
      Map<String, Duration> averageByType = {};
      timesByType.forEach((type, durations) {
        final totalMs = durations
            .map((d) => d.inMilliseconds)
            .reduce((a, b) => a + b);
        averageByType[type] = Duration(milliseconds: totalMs ~/ durations.length);
      });
      
      // Calculate averages by priority
      Map<String, Duration> averageByPriority = {};
      timesByPriority.forEach((priority, durations) {
        final totalMs = durations
            .map((d) => d.inMilliseconds)
            .reduce((a, b) => a + b);
        averageByPriority[priority] = Duration(milliseconds: totalMs ~/ durations.length);
      });
      
      return {
        'overall_average': overallAverage,
        'by_type': averageByType,
        'by_priority': averageByPriority,
      };
    } catch (e, stackTrace) {
      log('❌ Error getting resolution time stats: $e', error: e, stackTrace: stackTrace);
      return {};
    }
  }
  
  /// Get most common issue types
  Future<List<Map<String, dynamic>>> getCommonIssueTypes({int? lastDays, int limit = 10}) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('support_tickets')
          .select('type');
      
      // Filter by date range if specified
      if (lastDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
        query = query.gte('created_at', cutoffDate.toIso8601String());
      }
      
      final tickets = await query;
      
      // Count by type
      Map<String, int> issueTypeCounts = {};
      for (final ticket in tickets) {
        final type = ticket['type'] as String;
        issueTypeCounts[type] = (issueTypeCounts[type] ?? 0) + 1;
      }
      
      // Convert to list and sort
      List<Map<String, dynamic>> issueTypes = issueTypeCounts.entries
          .map((entry) => {
            'type': entry.key,
            'count': entry.value,
            'percentage': tickets.isNotEmpty ? (entry.value / tickets.length) * 100 : 0,
          })
          .toList();
      
      // Sort by count descending
      issueTypes.sort((a, b) => b['count'].compareTo(a['count']));
      
      // Limit results
      if (issueTypes.length > limit) {
        issueTypes = issueTypes.sublist(0, limit);
      }
      
      return issueTypes;
    } catch (e, stackTrace) {
      log('❌ Error getting common issue types: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Get ticket volume by time of day
  Future<Map<int, int>> getTicketVolumeByHour({int? lastDays}) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('support_tickets')
          .select('created_at');
      
      // Filter by date range if specified
      if (lastDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
        query = query.gte('created_at', cutoffDate.toIso8601String());
      }
      
      final tickets = await query;
      
      // Group by hour
      Map<int, int> ticketsByHour = {};
      
      // Initialize all hours with 0
      for (int hour = 0; hour < 24; hour++) {
        ticketsByHour[hour] = 0;
      }
      
      for (final ticket in tickets) {
        final date = DateTime.parse(ticket['created_at']);
        final hour = date.hour;
        ticketsByHour[hour] = (ticketsByHour[hour] ?? 0) + 1;
      }
      
      return ticketsByHour;
    } catch (e, stackTrace) {
      log('❌ Error getting ticket volume by hour: $e', error: e, stackTrace: stackTrace);
      return {};
    }
  }
  
  /// Get customer satisfaction ratings
  Future<Map<String, dynamic>> getCustomerSatisfactionStats({int? lastDays}) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('ticket_satisfaction_ratings')
          .select('rating, feedback, ticket_id, created_at');
      
      // Filter by date range if specified
      if (lastDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
        query = query.gte('created_at', cutoffDate.toIso8601String());
      }
      
      final ratings = await query;
      
      if (ratings.isEmpty) {
        return {
          'average_rating': 0.0,
          'rating_counts': {
            '1': 0,
            '2': 0,
            '3': 0,
            '4': 0,
            '5': 0,
          },
          'total_ratings': 0,
        };
      }
      
      // Calculate average rating
      double totalScore = 0;
      
      // Count by rating value
      Map<String, int> ratingCounts = {
        '1': 0,
        '2': 0,
        '3': 0,
        '4': 0,
        '5': 0,
      };
      
      for (final rating in ratings) {
        final score = rating['rating'] as int;
        totalScore += score;
        ratingCounts[score.toString()] = (ratingCounts[score.toString()] ?? 0) + 1;
      }
      
      final averageRating = totalScore / ratings.length;
      
      return {
        'average_rating': averageRating,
        'rating_counts': ratingCounts,
        'total_ratings': ratings.length,
      };
    } catch (e, stackTrace) {
      log('❌ Error getting customer satisfaction stats: $e', error: e, stackTrace: stackTrace);
      return {};
    }
  }
  
  /// Get CSR activity log
  Future<List<Map<String, dynamic>>> getCsrActivityLog({
    String? csrId,
    int limit = 50,
    int offset = 0
  }) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('csr_activity_log')
          .select('*, csr:users!csr_id(email, display_name)');
      
      // Filter by CSR ID if specified
      if (csrId != null) {
        query = query.eq('csr_id', csrId);
      }
      
      // Apply pagination and ordering
      final activities = await query
          .order('timestamp', ascending: false)
          .range(offset, offset + limit - 1);
      
      return List<Map<String, dynamic>>.from(activities);
    } catch (e, stackTrace) {
      log('❌ Error getting CSR activity log: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Log CSR activity
  Future<bool> logCsrActivity(
    String csrId,
    String activityType,
    String entityType,
    String entityId,
    String? details
  ) async {
    try {
      await _supabase
          .from('csr_activity_log')
          .insert({
            'csr_id': csrId,
            'activity_type': activityType,
            'entity_type': entityType,
            'entity_id': entityId,
            'details': details,
            'timestamp': DateTime.now().toIso8601String(),
          });
      
      return true;
    } catch (e, stackTrace) {
      log('❌ Error logging CSR activity: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}