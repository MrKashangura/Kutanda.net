// lib/services/support_ticket_service.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/support_ticket_model.dart';

class SupportTicketService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Create a new support ticket
  Future<SupportTicket?> createTicket(SupportTicket ticket) async {
    try {
      // Insert ticket data into the database
      final response = await _supabase
          .from('support_tickets')
          .insert(ticket.toMap())
          .select()
          .single();
      
      // If ticket has messages, insert them
      if (ticket.messages.isNotEmpty) {
        for (final message in ticket.messages) {
          await _supabase
              .from('ticket_messages')
              .insert(message.toMap());
        }
      }
      
      log('✅ Support ticket created: ${response['id']}');
      return SupportTicket.fromMap(response, messages: ticket.messages);
    } catch (e, stackTrace) {
      log('❌ Error creating support ticket: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Get all tickets for a user
  Future<List<SupportTicket>> getUserTickets(String userId) async {
    try {
      final response = await _supabase
          .from('support_tickets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      List<SupportTicket> tickets = [];
      
      for (final ticketData in response) {
        // Get messages for this ticket
        final messagesResponse = await _supabase
            .from('ticket_messages')
            .select()
            .eq('ticket_id', ticketData['id'])
            .order('timestamp');
        
        final messages = messagesResponse
            .map((msgData) => TicketMessage.fromMap(msgData))
            .toList();
        
        tickets.add(SupportTicket.fromMap(ticketData, messages: messages));
      }
      
      return tickets;
    } catch (e, stackTrace) {
      log('❌ Error getting user tickets: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Get all tickets for CSR dashboard
  Future<List<SupportTicket>> getAllTickets({
    TicketStatus? statusFilter,
    TicketPriority? priorityFilter,
    TicketType? typeFilter,
    String? assignedCsrId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Start with base query
      PostgrestFilterBuilder query = _supabase
          .from('support_tickets')
          .select();
      
      // Apply filters if provided
      if (statusFilter != null) {
        query = query.eq('status', statusFilter.toString().split('.').last);
      }
      
      if (priorityFilter != null) {
        query = query.eq('priority', priorityFilter.toString().split('.').last);
      }
      
      if (typeFilter != null) {
        query = query.eq('type', typeFilter.toString().split('.').last);
      }
      
      if (assignedCsrId != null) {
        query = query.eq('assigned_csr_id', assignedCsrId);
      }
      
      // Apply pagination
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      List<SupportTicket> tickets = [];
      
      for (final ticketData in response) {
        // Get messages for this ticket
        final messagesResponse = await _supabase
            .from('ticket_messages')
            .select()
            .eq('ticket_id', ticketData['id'])
            .order('timestamp');
        
        final messages = messagesResponse
            .map((msgData) => TicketMessage.fromMap(msgData))
            .toList();
        
        tickets.add(SupportTicket.fromMap(ticketData, messages: messages));
      }
      
      return tickets;
    } catch (e, stackTrace) {
      log('❌ Error getting tickets: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Get a single ticket by ID
  Future<SupportTicket?> getTicket(String ticketId) async {
    try {
      final response = await _supabase
          .from('support_tickets')
          .select()
          .eq('id', ticketId)
          .single();
      
      // Get messages for this ticket
      final messagesResponse = await _supabase
          .from('ticket_messages')
          .select()
          .eq('ticket_id', ticketId)
          .order('timestamp');
      
      final messages = messagesResponse
          .map((msgData) => TicketMessage.fromMap(msgData))
          .toList();
      
      return SupportTicket.fromMap(response, messages: messages);
    } catch (e, stackTrace) {
      log('❌ Error getting ticket: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Update a ticket
  Future<bool> updateTicket(SupportTicket ticket) async {
    try {
      await _supabase
          .from('support_tickets')
          .update(ticket.toMap())
          .eq('id', ticket.id);
      
      log('✅ Support ticket updated: ${ticket.id}');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error updating support ticket: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Add a message to a ticket
  Future<bool> addMessage(TicketMessage message) async {
    try {
      // Insert the message
      await _supabase
          .from('ticket_messages')
          .insert(message.toMap());
      
      // Update the ticket's last_updated timestamp
      await _supabase
          .from('support_tickets')
          .update({'last_updated': DateTime.now().toIso8601String()})
          .eq('id', message.ticketId);
      
      log('✅ Message added to ticket: ${message.ticketId}');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error adding message: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Assign a ticket to a CSR
  Future<bool> assignTicket(String ticketId, String csrId) async {
    try {
      await _supabase
          .from('support_tickets')
          .update({
            'assigned_csr_id': csrId,
            'status': TicketStatus.inProgress.toString().split('.').last,
            'last_updated': DateTime.now().toIso8601String()
          })
          .eq('id', ticketId);
      
      log('✅ Ticket assigned to CSR: $csrId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error assigning ticket: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Update ticket status
  Future<bool> updateTicketStatus(String ticketId, TicketStatus status) async {
    try {
      await _supabase
          .from('support_tickets')
          .update({
            'status': status.toString().split('.').last,
            'last_updated': DateTime.now().toIso8601String()
          })
          .eq('id', ticketId);
      
      log('✅ Ticket status updated: $status');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error updating ticket status: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Create a new dispute ticket
  Future<DisputeTicket?> createDispute(DisputeTicket dispute) async {
    try {
      final response = await _supabase
          .from('dispute_tickets')
          .insert(dispute.toMap())
          .select()
          .single();
      
      log('✅ Dispute ticket created: ${response['id']}');
      return DisputeTicket.fromMap(response);
    } catch (e, stackTrace) {
      log('❌ Error creating dispute ticket: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Get all dispute tickets
  Future<List<DisputeTicket>> getAllDisputes({
    DisputeStatus? statusFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Start with base query
      PostgrestFilterBuilder query = _supabase
          .from('dispute_tickets')
          .select();
      
      // Apply status filter if provided
      if (statusFilter != null) {
        query = query.eq('status', statusFilter.toString().split('.').last);
      }
      
      // Apply pagination
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return response.map((data) => DisputeTicket.fromMap(data)).toList();
    } catch (e, stackTrace) {
      log('❌ Error getting disputes: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Get a single dispute by ID
  Future<DisputeTicket?> getDispute(String disputeId) async {
    try {
      final response = await _supabase
          .from('dispute_tickets')
          .select()
          .eq('id', disputeId)
          .single();
      
      return DisputeTicket.fromMap(response);
    } catch (e, stackTrace) {
      log('❌ Error getting dispute: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Update a dispute
  Future<bool> updateDispute(DisputeTicket dispute) async {
    try {
      await _supabase
          .from('dispute_tickets')
          .update(dispute.toMap())
          .eq('id', dispute.id);
      
      log('✅ Dispute updated: ${dispute.id}');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error updating dispute: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Resolve a dispute
  Future<bool> resolveDispute(String disputeId, String resolution, String csrNotes) async {
    try {
      await _supabase
          .from('dispute_tickets')
          .update({
            'status': DisputeStatus.resolved.toString().split('.').last,
            'resolution': resolution,
            'csr_notes': csrNotes,
            'resolved_at': DateTime.now().toIso8601String()
          })
          .eq('id', disputeId);
      
      log('✅ Dispute resolved: $disputeId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error resolving dispute: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Create a content report
  Future<ContentReport?> createContentReport(ContentReport report) async {
    try {
      final response = await _supabase
          .from('content_reports')
          .insert(report.toMap())
          .select()
          .single();
      
      log('✅ Content report created: ${response['id']}');
      return ContentReport.fromMap(response);
    } catch (e, stackTrace) {
      log('❌ Error creating content report: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Get all content reports
  Future<List<ContentReport>> getAllContentReports({
    ContentReportStatus? statusFilter,
    ContentType? typeFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Start with base query
      PostgrestFilterBuilder query = _supabase
          .from('content_reports')
          .select();
      
      // Apply filters if provided
      if (statusFilter != null) {
        query = query.eq('status', statusFilter.toString().split('.').last);
      }
      
      if (typeFilter != null) {
        query = query.eq('content_type', typeFilter.toString().split('.').last);
      }
      
      // Apply pagination
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return response.map((data) => ContentReport.fromMap(data)).toList();
    } catch (e, stackTrace) {
      log('❌ Error getting content reports: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Get a single content report by ID
  Future<ContentReport?> getContentReport(String reportId) async {
    try {
      final response = await _supabase
          .from('content_reports')
          .select()
          .eq('id', reportId)
          .single();
      
      return ContentReport.fromMap(response);
    } catch (e, stackTrace) {
      log('❌ Error getting content report: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Moderate a content report (approve or reject)
  Future<bool> moderateContentReport(
    String reportId, 
    ContentReportStatus decision,
    String moderatorId,
    String? notes
  ) async {
    try {
      await _supabase
          .from('content_reports')
          .update({
            'status': decision.toString().split('.').last,
            'moderator_id': moderatorId,
            'moderator_notes': notes,
            'reviewed_at': DateTime.now().toIso8601String()
          })
          .eq('id', reportId);
      
      // If approved, handle content removal based on type
      if (decision == ContentReportStatus.approved) {
        final report = await getContentReport(reportId);
        if (report != null) {
          await _handleReportedContent(report);
        }
      }
      
      log('✅ Content report moderated: $reportId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error moderating content report: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Handle the removal of reported content based on its type
  Future<void> _handleReportedContent(ContentReport report) async {
    try {
      switch (report.contentType) {
        case ContentType.auction:
          // Remove auction listing
          await _supabase
              .from('auctions')
              .update({'is_active': false, 'is_reported': true})
              .eq('id', report.contentId);
          break;
          
        case ContentType.review:
          // Remove review
          await _supabase
              .from('reviews')
              .update({'is_visible': false, 'is_reported': true})
              .eq('id', report.contentId);
          break;
          
        case ContentType.user:
          // Flag user account
          await _supabase
              .from('users')
              .update({'is_reported': true})
              .eq('id', report.contentId);
          break;
          
        case ContentType.message:
          // Remove message
          await _supabase
              .from('ticket_messages')
              .update({'is_visible': false, 'is_reported': true})
              .eq('id', report.contentId);
          break;
      }
    } catch (e, stackTrace) {
      log('❌ Error handling reported content: $e', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Get ticket counts by status for analytics
  Future<Map<String, int>> getTicketCountsByStatus() async {
    try {
      final response = await _supabase
          .from('support_tickets')
          .select('status');
      
      Map<String, int> counts = {
        'open': 0,
        'inProgress': 0,
        'pendingUser': 0,
        'resolved': 0,
        'closed': 0,
      };
      
      for (final ticket in response) {
        final status = ticket['status'] as String;
        counts[status] = (counts[status] ?? 0) + 1;
      }
      
      return counts;
    } catch (e, stackTrace) {
      log('❌ Error getting ticket counts: $e', error: e, stackTrace: stackTrace);
      return {};
    }
  }
  
  /// Get average resolution time for tickets
  Future<Duration?> getAverageResolutionTime({int? lastDays}) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('support_tickets')
          .select('created_at, last_updated')
          .eq('status', TicketStatus.resolved.toString().split('.').last);
      
      // Filter by date range if specified
      if (lastDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
        query = query.gte('created_at', cutoffDate.toIso8601String());
      }
      
      final response = await query;
      
      if (response.isEmpty) {
        return null;
      }
      
      int totalMilliseconds = 0;
      int count = 0;
      
      for (final ticket in response) {
        final createdAt = DateTime.parse(ticket['created_at']);
        final lastUpdated = DateTime.parse(ticket['last_updated']);
        final duration = lastUpdated.difference(createdAt).inMilliseconds;
        
        totalMilliseconds += duration;
        count++;
      }
      
      if (count == 0) return null;
      
      final averageMilliseconds = totalMilliseconds ~/ count;
      return Duration(milliseconds: averageMilliseconds);
    } catch (e, stackTrace) {
      log('❌ Error calculating average resolution time: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Get CSR performance metrics
  Future<Map<String, dynamic>> getCsrPerformanceMetrics(String csrId, {int? lastDays}) async {
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
        if (ticket['status'] == TicketStatus.resolved.toString().split('.').last) {
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
    } catch (e, stackTrace) {
      log('❌ Error getting CSR performance metrics: $e', error: e, stackTrace: stackTrace);
      return {};
    }
  }
  
  /// Get common issue types for analytics
  Future<Map<String, int>> getCommonIssueTypes({int? lastDays}) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('support_tickets')
          .select('type');
      
      // Filter by date range if specified
      if (lastDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
        query = query.gte('created_at', cutoffDate.toIso8601String());
      }
      
      final response = await query;
      
      Map<String, int> typeCounts = {};
      
      for (final ticket in response) {
        final type = ticket['type'] as String;
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }
      
      return typeCounts;
    } catch (e, stackTrace) {
      log('❌ Error getting common issue types: $e', error: e, stackTrace: stackTrace);
      return {};
    }
  }
  
  /// Reassign tickets from one CSR to another
  Future<int> reassignTickets(String fromCsrId, String toCsrId) async {
    try {
      // Only reassign open and in-progress tickets
      final result = await _supabase
          .from('support_tickets')
          .update({
            'assigned_csr_id': toCsrId,
            'last_updated': DateTime.now().toIso8601String()
          })
          .eq('assigned_csr_id', fromCsrId)
          .inFilter('status', [
            TicketStatus.open.toString().split('.').last,
            TicketStatus.inProgress.toString().split('.').last,
          ]);
      
      // For Supabase, count the affected rows
      int reassignedCount = result.length;  // This might need adjustment based on the actual return value
      
      log('✅ Reassigned $reassignedCount tickets from $fromCsrId to $toCsrId');
      return reassignedCount;
    } catch (e, stackTrace) {
      log('❌ Error reassigning tickets: $e', error: e, stackTrace: stackTrace);
      return 0;
    }
  }
  
  /// Batch assign tickets to a CSR
  Future<int> batchAssignTickets(List<String> ticketIds, String csrId) async {
    try {
      if (ticketIds.isEmpty) {
        return 0;
      }
      
      // Update all tickets in the list
      final result = await _supabase
          .from('support_tickets')
          .update({
            'assigned_csr_id': csrId,
            'status': TicketStatus.inProgress.toString().split('.').last,
            'last_updated': DateTime.now().toIso8601String()
          })
          .inFilter('id', ticketIds);
      
      int assignedCount = ticketIds.length;  // This might need adjustment based on actual return
      
      log('✅ Batch assigned $assignedCount tickets to CSR: $csrId');
      return assignedCount;
    } catch (e, stackTrace) {
      log('❌ Error batch assigning tickets: $e', error: e, stackTrace: stackTrace);
      return 0;
    }
  }
  
  /// Get unassigned tickets
  Future<List<Map<String, dynamic>>> getUnassignedTickets({
    TicketPriority? priorityFilter,
    int limit = 20,
  }) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('support_tickets')
          .select('*, users:user_id(email, display_name)')
          .inFilter('assigned_csr_id', [null, ''])
          .eq('status', TicketStatus.open.toString().split('.').last);
      
      // Apply priority filter if provided
      if (priorityFilter != null) {
        query = query.eq('priority', priorityFilter.toString().split('.').last);
      }
      
      // Apply ordering and limit
      final tickets = await query
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(tickets);
    } catch (e, stackTrace) {
      log('❌ Error getting unassigned tickets: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Get CSR workload metrics
  Future<List<Map<String, dynamic>>> getCsrWorkloadMetrics() async {
    try {
      // Get all CSRs
      final csrs = await _supabase
          .from('users')
          .select('uid, email, display_name')
          .eq('role', 'csr');
      
      List<Map<String, dynamic>> workloadMetrics = [];
      
      // For each CSR, count their tickets by status
      for (final csr in csrs) {
        final csrId = csr['id'] as String;
        
        // Get ticket counts by status
        final tickets = await _supabase
            .from('support_tickets')
            .select('status')
            .eq('assigned_csr_id', csrId);
        
        // Count tickets by status
        Map<String, int> statusCounts = {
          'open': 0,
          'inProgress': 0, 
          'pendingUser': 0,
          'resolved': 0,
          'closed': 0,
        };
        
        for (final ticket in tickets) {
          final status = ticket['status'] as String;
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }
        
        // Calculate active tickets (open + inProgress + pendingUser)
        int activeTickets = statusCounts['open']! + 
                           statusCounts['inProgress']! + 
                           statusCounts['pendingUser']!;
        
        // Add CSR workload metrics
        workloadMetrics.add({
          'id': csrId,
          'email': csr['email'],
          'display_name': csr['display_name'],
          'total_tickets': tickets.length,
          'active_tickets': activeTickets,
          'status_counts': statusCounts,
        });
      }
      
      // Sort by active tickets count (descending)
      workloadMetrics.sort((a, b) => 
        (b['active_tickets'] as int).compareTo(a['active_tickets'] as int));
      
      return workloadMetrics;
    } catch (e, stackTrace) {
      log('❌ Error getting CSR workload metrics: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Get CSR performance trends (resolution rates over time)
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
            .inFilter('id', csrIds);
      }
      
      Map<String, List<Map<String, dynamic>>> trends = {};
      
      // For each CSR, calculate weekly performance metrics
      for (final csr in csrs) {
        final csrId = csr['id'] as String;
        final csrName = csr['display_name'] ?? csr['email'] ?? 'Unknown';
        
        // Calculate start date
        final endDate = DateTime.now();
        final startDate = endDate.subtract(Duration(days: days));
        
        // Get all resolved tickets in the date range
        final tickets = await _supabase
            .from('support_tickets')
            .select('uid, created_at, last_updated, status')
            .eq('assigned_csr_id', csrId)
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String());
        
        // Group tickets by week
        Map<String, List<Map<String, dynamic>>> ticketsByWeek = {};
        
        for (final ticket in tickets) {
          final createdAt = DateTime.parse(ticket['created_at']);
          // Get the start of the week (Monday)
          final weekStart = createdAt.subtract(Duration(days: createdAt.weekday - 1));
          final weekKey = weekStart.toIso8601String().split('T')[0];
          
          if (!ticketsByWeek.containsKey(weekKey)) {
            ticketsByWeek[weekKey] = [];
          }
          
          ticketsByWeek[weekKey]!.add(ticket);
        }
        
        // Calculate weekly performance metrics
        List<Map<String, dynamic>> csrTrend = [];
        
        ticketsByWeek.forEach((weekStart, weekTickets) {
          int totalTickets = weekTickets.length;
          int resolvedTickets = weekTickets.where((t) => 
            t['status'] == TicketStatus.resolved.toString().split('.').last ||
            t['status'] == TicketStatus.closed.toString().split('.').last
          ).length;
          
          double resolutionRate = totalTickets > 0 ? resolvedTickets / totalTickets : 0;
          
          // Calculate average resolution time for resolved tickets
          int totalResolutionMilliseconds = 0;
          int resolvedCount = 0;
          
          for (final ticket in weekTickets) {
            if (ticket['status'] == TicketStatus.resolved.toString().split('.').last &&
                ticket['last_updated'] != null) {
              final createdAt = DateTime.parse(ticket['created_at']);
              final resolvedAt = DateTime.parse(ticket['last_updated']);
              totalResolutionMilliseconds += resolvedAt.difference(createdAt).inMilliseconds;
              resolvedCount++;
            }
          }
          
          Duration? averageResolutionTime = resolvedCount > 0 
              ? Duration(milliseconds: totalResolutionMilliseconds ~/ resolvedCount)
              : null;
          
          csrTrend.add({
            'week_start': weekStart,
            'total_tickets': totalTickets,
            'resolved_tickets': resolvedTickets,
            'resolution_rate': resolutionRate,
            'average_resolution_time': averageResolutionTime,
          });
        });
        
        // Sort by week
        csrTrend.sort((a, b) => a['week_start'].compareTo(b['week_start']));
        
        trends[csrId] = csrTrend;
      }
      
      return trends;
    } catch (e, stackTrace) {
      log('❌ Error getting CSR performance trends: $e', error: e, stackTrace: stackTrace);
      return {};
    }
  }
}