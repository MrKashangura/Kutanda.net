// lib/data/repositories/support_repository.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/support_ticket_model.dart';

class SupportRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new support ticket
  Future<SupportTicket?> createTicket(SupportTicket ticket) async {
    try {
      // Insert ticket data
      final response = await _supabase
          .from('support_tickets')
          .insert(ticket.toMap())
          .select()
          .single();
      
      // Insert initial message if provided
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
  
  /// Get tickets by user
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
  
  /// Get a single ticket by ID with messages
  Future<SupportTicket?> getTicketById(String ticketId) async {
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
  
  /// Get all tickets with filtering options (for CSR/Admin)
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
      
      // Apply pagination and ordering
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      List<SupportTicket> tickets = [];
      
      for (final ticketData in response) {
        // Get messages for this ticket (limit to last 5 for efficiency)
        final messagesResponse = await _supabase
            .from('ticket_messages')
            .select()
            .eq('ticket_id', ticketData['id'])
            .order('timestamp', ascending: false)
            .limit(5);
        
        final messages = messagesResponse
            .map((msgData) => TicketMessage.fromMap(msgData))
            .toList()
            .reversed
            .toList();
        
        tickets.add(SupportTicket.fromMap(ticketData, messages: messages));
      }
      
      return tickets;
    } catch (e, stackTrace) {
      log('❌ Error getting tickets: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Add a message to a ticket
  Future<bool> addTicketMessage(TicketMessage message) async {
    try {
      // Insert message
      await _supabase
          .from('ticket_messages')
          .insert(message.toMap());
      
      // Update ticket last updated time
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
  
  /// Update ticket priority
  Future<bool> updateTicketPriority(String ticketId, TicketPriority priority) async {
    try {
      await _supabase
          .from('support_tickets')
          .update({
            'priority': priority.toString().split('.').last,
            'last_updated': DateTime.now().toIso8601String()
          })
          .eq('id', ticketId);
      
      log('✅ Ticket priority updated: $priority');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error updating ticket priority: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Assign ticket to CSR
  Future<bool> assignTicket(String ticketId, String csrId) async {
    try {
      await _supabase
          .from('support_tickets')
          .update({
            'assigned_csr_id': csrId,
            'last_updated': DateTime.now().toIso8601String()
          })
          .eq('id', ticketId);
      
      log('✅ Ticket assigned to: $csrId');
      return true;
    } catch (e, stackTrace) {
      log('❌ Error assigning ticket: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Create a dispute ticket
  Future<DisputeTicket?> createDispute(DisputeTicket dispute) async {
    try {
      final response = await _supabase
          .from('dispute_tickets')
          .insert(dispute.toMap())
          .select()
          .single();
      
      log('✅ Dispute created: ${response['id']}');
      return DisputeTicket.fromMap(response);
    } catch (e, stackTrace) {
      log('❌ Error creating dispute: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Get all disputes with filtering
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
  
  /// Get analytics for tickets
  Future<Map<String, dynamic>> getTicketAnalytics({int? lastDays}) async {
    try {
      // Query tickets
      PostgrestFilterBuilder query = _supabase
          .from('support_tickets')
          .select('status, priority, type, created_at, last_updated');
      
      // Filter by date range if specified
      if (lastDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));
        query = query.gte('created_at', cutoffDate.toIso8601String());
      }
      
      final tickets = await query;
      
      // Count by status
      Map<String, int> statusCounts = {
        'open': 0,
        'inProgress': 0,
        'pendingUser': 0,
        'resolved': 0,
        'closed': 0,
      };
      
      // Count by priority
      Map<String, int> priorityCounts = {
        'low': 0,
        'medium': 0,
        'high': 0,
        'urgent': 0,
      };
      
      // Count by type
      Map<String, int> typeCounts = {};
      
      // Calculate resolution times
      Map<String, List<Duration>> resolutionTimes = {
        'low': [],
        'medium': [],
        'high': [],
        'urgent': [],
      };
      
      for (final ticket in tickets) {
        // Count by status
        final status = ticket['status'] as String;
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        
        // Count by priority
        final priority = ticket['priority'] as String;
        priorityCounts[priority] = (priorityCounts[priority] ?? 0) + 1;
        
        // Count by type
        final type = ticket['type'] as String;
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
        
        // Calculate resolution time for resolved tickets
        if (status == 'resolved' && ticket['last_updated'] != null) {
          final createdAt = DateTime.parse(ticket['created_at']);
          final resolvedAt = DateTime.parse(ticket['last_updated']);
          final duration = resolvedAt.difference(createdAt);
          
          resolutionTimes[priority]?.add(duration);
        }
      }
      
      // Calculate average resolution time by priority
      Map<String, Duration> avgResolutionByPriority = {};
      
      for (final entry in resolutionTimes.entries) {
        final priorityData = entry.value;
        if (priorityData.isNotEmpty) {
          final totalMs = priorityData.fold<int>(
            0, (sum, duration) => sum + duration.inMilliseconds);
          avgResolutionByPriority[entry.key] = 
              Duration(milliseconds: totalMs ~/ priorityData.length);
        }
      }
      
      return {
        'total_tickets': tickets.length,
        'status_counts': statusCounts,
        'priority_counts': priorityCounts,
        'type_counts': typeCounts,
        'avg_resolution_by_priority': avgResolutionByPriority,
      };
    } catch (e, stackTrace) {
      log('❌ Error getting ticket analytics: $e', error: e, stackTrace: stackTrace);
      return {};
    }
  }
}