// lib/services/csr_analytics_service.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing analytics data for the CSR dashboard
class CsrAnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Get ticket statistics
  Future<Map<String, dynamic>> getTicketStats({int? lastDays}) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('support_tickets')
          .select('status, created_at, last_updated');
      
      // Filter by date range if specified
      if (lastDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
        query = query.gte('created_at', cutoffDate.toIso8601String());
      }
      
      final tickets = await query;
      
      // Count tickets by status
      Map<String, int> ticketsByStatus = {
        'open': 0,
        'inProgress': 0,
        'pendingUser': 0,
        'resolved': 0,
        'closed': 0,
      };
      
      // Calculate resolution times
      int totalTickets = tickets.length;
      int resolvedTickets = 0;
      int totalResolutionMilliseconds = 0;
      int unassignedTickets = 0;
      
      for (final ticket in tickets) {
        final status = ticket['status'] as String;
        ticketsByStatus[status] = (ticketsByStatus[status] ?? 0) + 1;
        
        // Count unassigned tickets
        if (status == 'open' && ticket['assigned_csr_id'] == null) {
          unassignedTickets++;
        }
        
        // Calculate resolution time for resolved tickets
        if (status == 'resolved' && ticket['last_updated'] != null) {
          resolvedTickets++;
          final createdAt = DateTime.parse(ticket['created_at']);
          final resolvedAt = DateTime.parse(ticket['last_updated']);
          totalResolutionMilliseconds += resolvedAt.difference(createdAt).inMilliseconds;
        }
      }
      
      // Calculate average resolution time
      Duration? averageResolutionTime;
      if (resolvedTickets > 0) {
        averageResolutionTime = Duration(
          milliseconds: totalResolutionMilliseconds ~/ resolvedTickets
        );
      }
      
      return {
        'total_tickets': totalTickets,
        'tickets_by_status': ticketsByStatus,
        'resolved_tickets': resolvedTickets,
        'unassigned_tickets': unassignedTickets,
        'average_resolution_time': averageResolutionTime,
      };
    } catch (e) {
      log('❌ Error getting ticket stats: $e');
      return {};
    }
  }
  
  /// Get resolution time statistics by priority
  Future<Map<String, dynamic>> getResolutionTimeStats({int? lastDays}) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('support_tickets')
          .select('priority, created_at, last_updated')
          .eq('status', 'resolved');
      
      // Filter by date range if specified
      if (lastDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
        query = query.gte('created_at', cutoffDate.toIso8601String());
      }
      
      final tickets = await query;
      
      // Group by priority
      Map<String, List<int>> resolutionMillisecondsByPriority = {
        'low': [],
        'medium': [],
        'high': [],
        'urgent': [],
      };
      
      for (final ticket in tickets) {
        final priority = ticket['priority'] as String;
        final createdAt = DateTime.parse(ticket['created_at']);
        final resolvedAt = DateTime.parse(ticket['last_updated']);
        final milliseconds = resolvedAt.difference(createdAt).inMilliseconds;
        
        resolutionMillisecondsByPriority[priority]?.add(milliseconds);
      }
      
      // Calculate averages by priority
      Map<String, Duration> averageByPriority = {};
      
      for (final entry in resolutionMillisecondsByPriority.entries) {
        final priorityData = entry.value;
        if (priorityData.isNotEmpty) {
          final average = priorityData.reduce((a, b) => a + b) ~/ priorityData.length;
          averageByPriority[entry.key] = Duration(milliseconds: average);
        }
      }
      
      return {
        'by_priority': averageByPriority,
      };
    } catch (e) {
      log('❌ Error getting resolution time stats: $e');
      return {};
    }
  }
  
  /// Get common issue types
  Future<List<Map<String, dynamic>>> getCommonIssueTypes({int? lastDays, int? limit}) async {
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
      Map<String, int> typeCount = {};
      for (final ticket in tickets) {
        final type = ticket['type'] as String;
        typeCount[type] = (typeCount[type] ?? 0) + 1;
      }
      
      // Calculate percentages and format for display
      List<Map<String, dynamic>> result = [];
      int totalTickets = tickets.length;
      
      for (final entry in typeCount.entries) {
        double percentage = totalTickets > 0 
            ? (entry.value / totalTickets) * 100 
            : 0.0;
            
        result.add({
          'type': entry.key,
          'count': entry.value,
          'percentage': percentage,
        });
      }
      
      // Sort by count descending
      result.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      // Apply limit if specified
      if (limit != null && limit < result.length) {
        result = result.sublist(0, limit);
      }
      
      return result;
    } catch (e) {
      log('❌ Error getting common issue types: $e');
      return [];
    }
  }
  
  /// Get ticket volume by hour of day
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
      
      // Group by hour of day (0-23)
      Map<int, int> hourCount = {};
      for (int i = 0; i < 24; i++) {
        hourCount[i] = 0;
      }
      
      for (final ticket in tickets) {
        final createdAt = DateTime.parse(ticket['created_at']);
        final hour = createdAt.hour;
        hourCount[hour] = (hourCount[hour] ?? 0) + 1;
      }
      
      return hourCount;
    } catch (e) {
      log('❌ Error getting ticket volume by hour: $e');
      return {};
    }
  }
  
  /// Get performance metrics for a specific CSR
  Future<Map<String, dynamic>> getCsrPerformance(String csrId, {int? lastDays}) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('support_tickets')
          .select('id, created_at, last_updated, status')
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
          'resolution_rate': 0.0,
          'average_resolution_time': null,
        };
      }
      
      int totalTickets = tickets.length;
      int resolvedTickets = 0;
      int totalResolutionMilliseconds = 0;
      
      for (final ticket in tickets) {
        if (ticket['status'] == 'resolved') {
          resolvedTickets++;
          
          final createdAt = DateTime.parse(ticket['created_at']);
          final lastUpdated = DateTime.parse(ticket['last_updated']);
          totalResolutionMilliseconds += lastUpdated.difference(createdAt).inMilliseconds;
        }
      }
      
      double resolutionRate = totalTickets > 0 ? resolvedTickets / totalTickets : 0;
      Duration? averageResolutionTime = resolvedTickets > 0
          ? Duration(milliseconds: totalResolutionMilliseconds ~/ resolvedTickets)
          : null;
      
      return {
        'total_tickets': totalTickets,
        'resolved_tickets': resolvedTickets,
        'resolution_rate': resolutionRate,
        'average_resolution_time': averageResolutionTime,
      };
    } catch (e) {
      log('❌ Error getting CSR performance metrics: $e');
      return {};
    }
  }
  
  /// Get performance metrics for all CSRs
  Future<List<Map<String, dynamic>>> getAllCsrPerformance({int? lastDays}) async {
    try {
      // First get all CSRs
      final csrs = await _supabase
          .from('users')
          .select('id, email, display_name')
          .eq('role', 'csr');
      
      List<Map<String, dynamic>> results = [];
      
      for (final csr in csrs) {
        final csrId = csr['id'] as String;
        final performance = await getCsrPerformance(csrId, lastDays: lastDays);
        
        results.add({
          ...Map<String, dynamic>.from(csr),
          ...performance,
        });
      }
      
      // Sort by total tickets descending
      results.sort((a, b) => (b['total_tickets'] as int).compareTo(a['total_tickets'] as int));
      
      return results;
    } catch (e) {
      log('❌ Error getting all CSR performance: $e');
      return [];
    }
  }
  
  /// Get customer satisfaction statistics
  Future<Map<String, dynamic>> getCustomerSatisfactionStats({int? lastDays}) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('satisfaction_ratings')
          .select('rating, created_at');
      
      // Filter by date range if specified
      if (lastDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
        query = query.gte('created_at', cutoffDate.toIso8601String());
      }
      
      final ratings = await query;
      
      if (ratings.isEmpty) {
        return {
          'average_rating': 0.0,
          'total_ratings': 0,
          'rating_counts': {
            '1': 0,
            '2': 0,
            '3': 0,
            '4': 0,
            '5': 0,
          }
        };
      }
      
      // Count ratings by value
      Map<String, int> ratingCounts = {
        '1': 0,
        '2': 0,
        '3': 0,
        '4': 0,
        '5': 0,
      };
      
      int totalRatingValue = 0;
      
      for (final rating in ratings) {
        final ratingValue = rating['rating'] as int;
        totalRatingValue += ratingValue;
        ratingCounts[ratingValue.toString()] = (ratingCounts[ratingValue.toString()] ?? 0) + 1;
      }
      
      double averageRating = ratings.isNotEmpty 
          ? totalRatingValue / ratings.length 
          : 0.0;
      
      return {
        'average_rating': averageRating,
        'total_ratings': ratings.length,
        'rating_counts': ratingCounts,
      };
    } catch (e) {
      log('❌ Error getting satisfaction stats: $e');
      return {};
    }
  }
}