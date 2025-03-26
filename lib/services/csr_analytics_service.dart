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
          .select('status, created_at, last_updated, assigned_csr_id');
      
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
        if (ticket['assigned_csr_id'] == null) {
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
          .select('uid, created_at, last_updated, status')
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
  
  /// Get detailed performance metrics for a specific CSR
  Future<Map<String, dynamic>> getDetailedCsrPerformance(String csrId, {int? lastDays}) async {
    try {
      // Get basic performance metrics
      final basicMetrics = await getCsrPerformance(csrId, lastDays: lastDays);
      
      // Get ticket statuses
      PostgrestFilterBuilder query = _supabase
          .from('support_tickets')
          .select('uid, status, priority, type')
          .eq('assigned_csr_id', csrId);
      
      // Filter by date range if specified
      if (lastDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
        query = query.gte('created_at', cutoffDate.toIso8601String());
      }
      
      final tickets = await query;
      
      // Count tickets by status
      Map<String, int> statusCounts = {
        'open': 0,
        'inProgress': 0,
        'pendingUser': 0,
        'resolved': 0,
        'closed': 0,
      };
      
      // Count tickets by priority
      Map<String, int> priorityCounts = {
        'low': 0,
        'medium': 0,
        'high': 0,
        'urgent': 0,
      };
      
      // Count tickets by type
      Map<String, int> typeCounts = {};
      
      for (final ticket in tickets) {
        final status = ticket['status'] as String;
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        
        final priority = ticket['priority'] as String;
        priorityCounts[priority] = (priorityCounts[priority] ?? 0) + 1;
        
        final type = ticket['type'] as String;
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }
      
      // Get customer satisfaction ratings
      final ratingsQuery = _supabase
          .from('satisfaction_ratings')
          .select('rating')
          .eq('csr_id', csrId);
      
      // Filter by date range if specified
      if (lastDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
        ratingsQuery.gte('created_at', cutoffDate.toIso8601String());
      }
      
      final ratings = await ratingsQuery;
      
      // Calculate average rating
      double averageRating = 0;
      if (ratings.isNotEmpty) {
        int totalRating = 0;
        for (final rating in ratings) {
          totalRating += rating['rating'] as int;
        }
        averageRating = totalRating / ratings.length;
      }
      
      return {
        ...basicMetrics,
        'status_counts': statusCounts,
        'priority_counts': priorityCounts,
        'type_counts': typeCounts,
        'average_rating': averageRating,
        'rating_count': ratings.length,
      };
    } catch (e) {
      log('❌ Error getting detailed CSR performance: $e');
      return {};
    }
  }
  
  /// Get performance metrics for all CSRs
  Future<List<Map<String, dynamic>>> getAllCsrPerformance({int? lastDays}) async {
    try {
      // First get all CSRs
      final csrs = await _supabase
          .from('users')
          .select('uid, email, display_name')
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
  
  /// Get performance comparison between CSRs
  Future<Map<String, dynamic>> getCsrPerformanceComparison({int? lastDays}) async {
    try {
      // Get all CSR performance
      final allCsrPerformance = await getAllCsrPerformance(lastDays: lastDays);
      
      if (allCsrPerformance.isEmpty) {
        return {
          'top_performers': [],
          'needs_improvement': [],
          'average_resolution_rate': 0.0,
          'average_resolution_time': null,
        };
      }
      
      // Calculate overall averages
      int totalTickets = 0;
      int totalResolved = 0;
      int totalResolutionMilliseconds = 0;
      int csrsWithResolutionTime = 0;
      
      for (final csr in allCsrPerformance) {
        totalTickets += csr['total_tickets'] as int;
        totalResolved += csr['resolved_tickets'] as int;
        
        final resolutionTime = csr['average_resolution_time'] as Duration?;
        if (resolutionTime != null) {
          totalResolutionMilliseconds += resolutionTime.inMilliseconds;
          csrsWithResolutionTime++;
        }
      }
      
      double averageResolutionRate = totalTickets > 0 ? totalResolved / totalTickets : 0;
      
      Duration? averageResolutionTime;
      if (csrsWithResolutionTime > 0) {
        averageResolutionTime = Duration(
          milliseconds: totalResolutionMilliseconds ~/ csrsWithResolutionTime
        );
      }
      
      // Sort CSRs by resolution rate
      allCsrPerformance.sort((a, b) {
        final aRate = a['resolution_rate'] as double;
        final bRate = b['resolution_rate'] as double;
        return bRate.compareTo(aRate);
      });
      
      // Get top and bottom performers
      final topPerformers = allCsrPerformance.length > 3 
          ? allCsrPerformance.sublist(0, 3) 
          : allCsrPerformance;
      
      final needsImprovement = allCsrPerformance.length > 3 
          ? allCsrPerformance.sublist(allCsrPerformance.length - 3) 
          : [];
      
      return {
        'top_performers': topPerformers,
        'needs_improvement': needsImprovement,
        'average_resolution_rate': averageResolutionRate,
        'average_resolution_time': averageResolutionTime,
      };
    } catch (e) {
      log('❌ Error getting CSR performance comparison: $e');
      return {};
    }
  }
  
  /// Get CSR performance trends over time
  Future<Map<String, List<Map<String, dynamic>>>> getCsrPerformanceTrends({
    List<String>? csrIds,
    int days = 30
  }) async {
    try {
      // Get all CSRs if not specified
      List<Map<String, dynamic>> csrs;
      if (csrIds == null || csrIds.isEmpty) {
        csrs = await _supabase
            .from('users')
            .select('uid, email, display_name')
            .eq('role', 'csr');
      } else {
        csrs = await _supabase
            .from('users')
            .select('uid, email, display_name')
            .filter('id', 'in', csrIds);  // Using filter with 'in' operator for list of values
      }
      
      // Calculate start and end dates
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      Map<String, List<Map<String, dynamic>>> trends = {};
      
      // For each CSR, get weekly metrics
      for (final csr in csrs) {
        final csrId = csr['id'] as String;
        
        // Get all tickets in the date range
        final tickets = await _supabase
            .from('support_tickets')
            .select('uid, created_at, last_updated, status')
            .eq('assigned_csr_id', csrId)
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String());
        
        // Group by week
        Map<String, List<Map<String, dynamic>>> ticketsByWeek = {};
        
        for (final ticket in tickets) {
          final createdAt = DateTime.parse(ticket['created_at']);
          // Get week number (ISO week)
          final weekNumber = _getWeekNumber(createdAt);
          final weekYear = _getWeekYear(createdAt);
          final weekKey = '$weekYear-W$weekNumber';
          
          if (!ticketsByWeek.containsKey(weekKey)) {
            ticketsByWeek[weekKey] = [];
          }
          
          ticketsByWeek[weekKey]!.add(ticket);
        }
        
        // Calculate weekly metrics
        List<Map<String, dynamic>> weeklyMetrics = [];
        
        for (var i = 0; i < (days / 7).ceil(); i++) {
          final weekDate = endDate.subtract(Duration(days: i * 7));
          final weekNumber = _getWeekNumber(weekDate);
          final weekYear = _getWeekYear(weekDate);
          final weekKey = '$weekYear-W$weekNumber';
          
          final weekTickets = ticketsByWeek[weekKey] ?? [];
          
          int totalTickets = weekTickets.length;
          int resolvedTickets = weekTickets.where((t) => 
            t['status'] == 'resolved' || t['status'] == 'closed'
          ).length;
          
          double resolutionRate = totalTickets > 0 ? resolvedTickets / totalTickets : 0;
          
          // Calculate average resolution time
          int totalResolutionMilliseconds = 0;
          int resolvedCount = 0;
          
          for (final ticket in weekTickets) {
            if (ticket['status'] == 'resolved' && ticket['last_updated'] != null) {
              final createdAt = DateTime.parse(ticket['created_at']);
              final resolvedAt = DateTime.parse(ticket['last_updated']);
              totalResolutionMilliseconds += resolvedAt.difference(createdAt).inMilliseconds;
              resolvedCount++;
            }
          }
          
          Duration? averageResolutionTime = resolvedCount > 0 
              ? Duration(milliseconds: totalResolutionMilliseconds ~/ resolvedCount)
              : null;
          
          weeklyMetrics.add({
            'week': weekKey,
            'total_tickets': totalTickets,
            'resolved_tickets': resolvedTickets,
            'resolution_rate': resolutionRate,
            'average_resolution_time': averageResolutionTime,
          });
        }
        
        // Sort by week (most recent first)
        weeklyMetrics.sort((a, b) => b['week'].compareTo(a['week']));
        
        trends[csrId] = weeklyMetrics;
      }
      
      return trends;
    } catch (e) {
      log('❌ Error getting CSR performance trends: $e');
      return {};
    }
  }
  
  /// Get team performance summary
  Future<Map<String, dynamic>> getTeamPerformanceSummary({int? lastDays}) async {
    try {
      // Get ticket statistics
      final ticketStats = await getTicketStats(lastDays: lastDays);
      
      // Get all CSR performance metrics
      final csrPerformance = await getAllCsrPerformance(lastDays: lastDays);
      
      // Calculate average resolution rate and time
      double overallResolutionRate = 0;
      int totalResolutionMilliseconds = 0;
      int csrsWithResolutionTime = 0;
      
      for (final csr in csrPerformance) {
        if (csr['total_tickets'] > 0) {
          overallResolutionRate += csr['resolution_rate'] as double;
          
          final resolutionTime = csr['average_resolution_time'] as Duration?;
          if (resolutionTime != null) {
            totalResolutionMilliseconds += resolutionTime.inMilliseconds;
            csrsWithResolutionTime++;
          }
        }
      }
      
      if (csrPerformance.isNotEmpty) {
        overallResolutionRate /= csrPerformance.length;
      }
      
      Duration? averageResolutionTime;
      if (csrsWithResolutionTime > 0) {
        averageResolutionTime = Duration(
          milliseconds: totalResolutionMilliseconds ~/ csrsWithResolutionTime
        );
      }
      
      // Get satisfaction stats
      final satisfactionStats = await getCustomerSatisfactionStats(lastDays: lastDays);
      
      return {
        'active_csrs': csrPerformance.length,
        'total_tickets': ticketStats['total_tickets'] ?? 0,
        'tickets_by_status': ticketStats['tickets_by_status'] ?? {},
        'unassigned_tickets': ticketStats['unassigned_tickets'] ?? 0,
        'resolution_rate': overallResolutionRate,
        'average_resolution_time': averageResolutionTime,
        'customer_satisfaction': satisfactionStats['average_rating'] ?? 0,
      };
    } catch (e) {
      log('❌ Error getting team performance summary: $e');
      return {};
    }
  }
  
  /// Get CSR workload distribution
  Future<Map<String, dynamic>> getCsrWorkloadDistribution() async {
    try {
      // Get all CSRs
      final csrs = await _supabase
          .from('users')
          .select('uid, email, display_name')
          .eq('role', 'csr');
      
      // Get ticket counts for each CSR
      List<Map<String, dynamic>> csrWorkloads = [];
      int totalActiveTickets = 0;
      
      for (final csr in csrs) {
        final csrId = csr['id'] as String;
        
        // Count active tickets (open, inProgress, pendingUser)
        final activeTicketsResult = await _supabase
            .from('support_tickets')
            .select('uid')
            .eq('assigned_csr_id', csrId)
            .inFilter('status', ['open', 'inProgress', 'pendingUser']);
        
        // Fixed: Using length instead of count
        final activeTickets = activeTicketsResult.length;
        
        // Count all tickets
        final allTicketsResult = await _supabase
            .from('support_tickets')
            .select('uid')
            .eq('assigned_csr_id', csrId);
        
        // Fixed: Using length instead of count
        final allTickets = allTicketsResult.length;
        
        csrWorkloads.add({
          'id': csrId,
          'email': csr['email'],
          'display_name': csr['display_name'],
          'active_tickets': activeTickets,
          'total_tickets': allTickets,
        });
        
        totalActiveTickets += activeTickets;
      }
      
      // Calculate workload percentages
      for (final workload in csrWorkloads) {
        workload['workload_percentage'] = totalActiveTickets > 0 
            ? (workload['active_tickets'] as int) / totalActiveTickets 
            : 0.0;  // Fixed: Ensuring this is a double, not trying to assign to int
      }
      
      // Sort by active tickets (descending)
      csrWorkloads.sort((a, b) => 
        (b['active_tickets'] as int).compareTo(a['active_tickets'] as int));
      
      final unassignedTicketsResult = await _supabase
          .from('support_tickets')
          .select('uid')
          .isFilter('assigned_csr_id', null);
      
      // Fixed: Using length instead of count
      final unassignedTickets = unassignedTicketsResult.length;
      
      return {
        'csr_workloads': csrWorkloads,
        'total_active_tickets': totalActiveTickets,
        'unassigned_tickets': unassignedTickets,
      };
    } catch (e) {
      log('❌ Error getting CSR workload distribution: $e');
      return {};
    }
  }
  
  /// Helper method to get ISO week number
  int _getWeekNumber(DateTime date) {
    int dayOfYear = int.parse(
        DateTime(date.year, date.month, date.day)
            .difference(DateTime(date.year, 1, 1))
            .inDays.toString()) +
        1;
    int woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) {
      woy = _getWeeksInYear(date.year - 1);
    } else if (woy > _getWeeksInYear(date.year)) {
      woy = 1;
    }
    return woy;
  }

  /// Helper method to get week year (may be different from date year near year boundaries)
  int _getWeekYear(DateTime date) {
    int dayOfYear = int.parse(
        DateTime(date.year, date.month, date.day)
            .difference(DateTime(date.year, 1, 1))
            .inDays.toString()) +
        1;
    int woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) {
      return date.year - 1;
    } else if (woy > _getWeeksInYear(date.year)) {
      return date.year + 1;
    }
    return date.year;
  }

  /// Helper method to get number of weeks in a year
  int _getWeeksInYear(int year) {
    DateTime dec28 = DateTime(year, 12, 28);
    int dayOfDec28 = int.parse(
        DateTime(dec28.year, dec28.month, dec28.day)
            .difference(DateTime(dec28.year, 1, 1))
            .inDays.toString()) +
        1;
    return ((dayOfDec28 - dec28.weekday + 10) / 7).floor();
  }
}