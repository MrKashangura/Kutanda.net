// lib/screens/ticket_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/helpers.dart';
import '../../../data/models/support_ticket_model.dart';
import '../../../services/support_ticket_service.dart';
import '../../../services/user_management_service.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  final Function? onTicketUpdated;

  const TicketDetailScreen({
    required this.ticketId,
    this.onTicketUpdated,
    super.key,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final SupportTicketService _ticketService = SupportTicketService();
  final UserManagementService _userService = UserManagementService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  bool _isSending = false;
  SupportTicket? _ticket;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _csrData;
  String? _currentCsrId;
  String? _currentCsrName;
  List<DropdownMenuItem<TicketStatus>> _statusOptions = [];
  List<DropdownMenuItem<TicketPriority>> _priorityOptions = [];

  @override
  void initState() {
    super.initState();
    _setupDropdowns();
    _getCurrentCsrInfo();
    _loadTicketData();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _setupDropdowns() {
    // Status options
    _statusOptions = [
      const DropdownMenuItem(
        value: TicketStatus.open,
        child: Text('Open'),
      ),
      const DropdownMenuItem(
        value: TicketStatus.inProgress,
        child: Text('In Progress'),
      ),
      const DropdownMenuItem(
        value: TicketStatus.pendingUser,
        child: Text('Pending User'),
      ),
      const DropdownMenuItem(
        value: TicketStatus.resolved,
        child: Text('Resolved'),
      ),
      const DropdownMenuItem(
        value: TicketStatus.closed,
        child: Text('Closed'),
      ),
    ];
    
    // Priority options
    _priorityOptions = [
      const DropdownMenuItem(
        value: TicketPriority.low,
        child: Text('Low'),
      ),
      const DropdownMenuItem(
        value: TicketPriority.medium,
        child: Text('Medium'),
      ),
      const DropdownMenuItem(
        value: TicketPriority.high,
        child: Text('High'),
      ),
      const DropdownMenuItem(
        value: TicketPriority.urgent,
        child: Text('Urgent'),
      ),
    ];
  }
  
  Future<void> _getCurrentCsrInfo() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        _currentCsrId = user.id;
        
        final userData = await _supabase
            .from('users')
            .select('display_name')
            .eq('uid', user.id)
            .single();
        
        setState(() {
          _currentCsrName = userData['display_name'] ?? 'CSR';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting CSR info: $e')),
        );
      }
    }
  }

  Future<void> _loadTicketData() async {
    setState(() => _isLoading = true);
    
    try {
        // Get ticket data
      var ticket = await _ticketService.getTicket(widget.ticketId);
      
      if (ticket == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket not found')),
          );
          Navigator.pop(context);
        }
        return;
      }
      
      // Get user data
      final userData = await _userService.getUserProfile(ticket.userId);
      
      // Get assigned CSR data if available
      Map<String, dynamic>? csrData;
      if (ticket.assignedCsrId != null) {
        final String csrId = ticket.assignedCsrId!;
        final csrResponse = await _supabase
            .from('users')
            .select('display_name, email')
            .eq('uid', csrId)
            .maybeSingle();
        
        if (csrResponse != null) {
          csrData = Map<String, dynamic>.from(csrResponse);
        }
      }
      
      // Auto-assign ticket to current CSR if not already assigned
      if (ticket.assignedCsrId == null && _currentCsrId != null &&
          ticket.status == TicketStatus.open) {
        await _ticketService.assignTicket(ticket.id, _currentCsrId!);
        await _ticketService.updateTicketStatus(ticket.id, TicketStatus.inProgress);
        
        // Reload ticket data after assigning
        final updatedTicket = await _ticketService.getTicket(widget.ticketId);
        if (updatedTicket != null) {
          ticket = updatedTicket;
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket automatically assigned to you')),
          );
        }
      }
      
      setState(() {
        _ticket = ticket;
        _userData = userData;
        _csrData = csrData;
        _isLoading = false;
      });
      
      // Scroll to bottom of messages after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ticket data: $e')),
        );
      }
    }
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _ticket == null || _currentCsrId == null) return;
    
    setState(() => _isSending = true);
    
    try {
      // Create message
      final ticketMessage = TicketMessage(
        ticketId: _ticket!.id,
        senderId: _currentCsrId!,
        content: message,
        isFromCSR: true,
      );
      
      // Add message to ticket
      await _ticketService.addMessage(ticketMessage);
      
      // If status is resolved or closed, update to in-progress
      if (_ticket!.status == TicketStatus.resolved || 
          _ticket!.status == TicketStatus.closed) {
        await _ticketService.updateTicketStatus(_ticket!.id, TicketStatus.inProgress);
      }
      
      // Clear message input
      _messageController.clear();
      
      // Reload ticket data
      await _loadTicketData();
      
      // Notify parent if callback provided
      widget.onTicketUpdated?.call();
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }
  
  Future<void> _updateTicketStatus(TicketStatus newStatus) async {
    if (_ticket == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _ticketService.updateTicketStatus(_ticket!.id, newStatus);
      
      // If changing to resolved or closed, add system message
      if (newStatus == TicketStatus.resolved || newStatus == TicketStatus.closed) {
        final statusMessage = TicketMessage(
          ticketId: _ticket!.id,
          senderId: _currentCsrId ?? 'system',
          content: 'Ticket marked as ${newStatus == TicketStatus.resolved ? 'resolved' : 'closed'} by ${_currentCsrName ?? 'CSR'}',
          isFromCSR: true,
        );
        
        await _ticketService.addMessage(statusMessage);
      }
      
      // Reload ticket data
      await _loadTicketData();
      
      // Notify parent if callback provided
      widget.onTicketUpdated?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ticket status updated to ${newStatus.toString().split('.').last}')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating ticket status: $e')),
        );
      }
    }
  }
  
  Future<void> _updateTicketPriority(TicketPriority newPriority) async {
    if (_ticket == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Create updated ticket with new priority
      final updatedTicket = _ticket!.copyWith(
        priority: newPriority,
      );
      
      await _ticketService.updateTicket(updatedTicket);
      
      // Add system message about priority change
      final priorityMessage = TicketMessage(
        ticketId: _ticket!.id,
        senderId: _currentCsrId ?? 'system',
        content: 'Ticket priority changed to ${newPriority.toString().split('.').last} by ${_currentCsrName ?? 'CSR'}',
        isFromCSR: true,
      );
      
      await _ticketService.addMessage(priorityMessage);
      
      // Reload ticket data
      await _loadTicketData();
      
      // Notify parent if callback provided
      widget.onTicketUpdated?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ticket priority updated to ${newPriority.toString().split('.').last}')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating ticket priority: $e')),
        );
      }
    }
  }
  
  Future<void> _createDisputeTicket() async {
    if (_ticket == null || _ticket!.metadata == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot create dispute: missing auction information')),
      );
      return;
    }
    
    // Check if we have auction ID in metadata
    final auctionId = _ticket!.metadata!['auction_id'];
    final buyerId = _ticket!.metadata!['buyer_id'];
    final sellerId = _ticket!.metadata!['seller_id'];
    
    if (auctionId == null || buyerId == null || sellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot create dispute: missing required information')),
      );
      return;
    }
    
    // Show dialog to confirm and get more information
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final issueController = TextEditingController();
        final amountController = TextEditingController();
        
        return AlertDialog(
          title: const Text('Create Dispute Ticket'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This will create a formal dispute ticket that will be handled through the dispute resolution process.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: issueController,
                  decoration: const InputDecoration(
                    labelText: 'Dispute Issue',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Disputed Amount (optional)',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (issueController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter the dispute issue')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                
                // Create dispute ticket
                final dispute = DisputeTicket(
                  ticketId: _ticket!.id,
                  auctionId: auctionId,
                  buyerId: buyerId,
                  sellerId: sellerId,
                  issue: issueController.text,
                  disputeAmount: double.tryParse(amountController.text),
                );
                
                setState(() => _isLoading = true);
                
                try {
                  final createdDispute = await _ticketService.createDispute(dispute);
                  
                  if (createdDispute != null) {
                    // Add system message about dispute creation
                    final disputeMessage = TicketMessage(
                      ticketId: _ticket!.id,
                      senderId: _currentCsrId ?? 'system',
                      content: 'Dispute ticket created by ${_currentCsrName ?? 'CSR'} and moved to dispute resolution process',
                      isFromCSR: true,
                    );
                    
                    await _ticketService.addMessage(disputeMessage);
                    
                    // Update ticket status
                    await _ticketService.updateTicketStatus(_ticket!.id, TicketStatus.inProgress);
                    
                    // Reload ticket data
                    await _loadTicketData();
                    
                    // Notify parent if callback provided
                    widget.onTicketUpdated?.call();
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dispute ticket created successfully')),
                      );
                    }
                  }
                } catch (e) {
                  setState(() => _isLoading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating dispute: $e')),
                    );
                  }
                }
              },
              child: const Text('Create Dispute'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Ticket Details")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Ticket Details")),
        body: const Center(child: Text('Ticket not found')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ticket Details"),
        actions: [
          if (_ticket!.type == TicketType.dispute || _ticket!.metadata?['auction_id'] != null)
            IconButton(
              icon: const Icon(Icons.gavel),
              tooltip: 'Create Dispute',
              onPressed: _createDisputeTicket,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadTicketData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Ticket info panel
          _buildTicketInfoPanel(),
          
          // Message history
          Expanded(
            child: _buildMessageList(),
          ),
          
          // Reply input
          _buildReplyInput(),
        ],
      ),
    );
  }
  
  Widget _buildTicketInfoPanel() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and ID
            Row(
              children: [
                Expanded(
                  child: Text(
                    _ticket!.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'ID: ${_ticket!.id.substring(0, 8)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Text(_ticket!.description),
            
            const SizedBox(height: 16),
            
            // Control row with status and priority
            Row(
              children: [
                // Type chip
                _buildTypeChip(_ticket!.type),
                
                const SizedBox(width: 16),
                
                // Status dropdown
                DropdownButton<TicketStatus>(
                  value: _ticket!.status,
                  items: _statusOptions,
                  onChanged: (newValue) {
                    if (newValue != null && newValue != _ticket!.status) {
                      _updateTicketStatus(newValue);
                    }
                  },
                  hint: const Text('Status'),
                ),
                
                const SizedBox(width: 16),
                
                // Priority dropdown
                DropdownButton<TicketPriority>(
                  value: _ticket!.priority,
                  items: _priorityOptions,
                  onChanged: (newValue) {
                    if (newValue != null && newValue != _ticket!.priority) {
                      _updateTicketPriority(newValue);
                    }
                  },
                  hint: const Text('Priority'),
                ),
              ],
            ),
            
            const Divider(),
            
            // Customer info
            Row(
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 8),
                Text(
                  'From: ${_userData?['email'] ?? 'User'}',
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Created: ${formatDate(_ticket!.createdAt)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Assigned CSR
            Row(
              children: [
                const Icon(Icons.support_agent, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Assigned to: ${_csrData?['display_name'] ?? 'Unassigned'}',
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                const Icon(Icons.update, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Updated: ${formatDate(_ticket!.lastUpdated ?? _ticket!.createdAt)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessageList() {
    final messages = _ticket!.messages;
  
  if (messages.isEmpty) {
    return const Center(
      child: Text('No messages yet'),
    );
  }
  
    return Expanded(  // Make sure the ListView is wrapped in an Expanded widget
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
        final message = messages[index];
        final isFromCSR = message.isFromCSR;
        
        return Align(
          alignment: isFromCSR ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              color: isFromCSR ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFromCSR ? Icons.support_agent : Icons.person,
                      size: 16,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFromCSR ? 'CSR' : 'Customer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatRelativeTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(message.content),
              ],
            ),
          ),
        );
      },
      )
    );
  }
  
  Widget _buildReplyInput() {
    // Don't show reply input for closed tickets
    if (_ticket!.status == TicketStatus.closed) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[200],
        child: Row(
          children: [
            const Icon(Icons.info, color: Colors.grey),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'This ticket is closed. To continue the conversation, please reopen the ticket.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => _updateTicketStatus(TicketStatus.open),
              child: const Text('Reopen'),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your response...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              textInputAction: TextInputAction.newline,
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
          ),
          const SizedBox(width: 8),
          // Add attachment button
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // TODO: Implement attachment picking
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attachments not yet implemented')),
              );
            },
          ),
          const SizedBox(width: 8),
          // Send button
          ElevatedButton(
            onPressed: _isSending ? null : _sendMessage,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
            ),
            child: _isSending
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTypeChip(TicketType type) {
    String label;
    Color color;
    
    switch (type) {
      case TicketType.general:
        label = 'General';
        color = Colors.blue;
        break;
      case TicketType.auction:
        label = 'Auction';
        color = Colors.green;
        break;
      case TicketType.payment:
        label = 'Payment';
        color = Colors.purple;
        break;
      case TicketType.shipping:
        label = 'Shipping';
        color = Colors.orange;
        break;
      case TicketType.account:
        label = 'Account';
        color = Colors.teal;
        break;
      case TicketType.dispute:
        label = 'Dispute';
        color = Colors.red;
        break;
      case TicketType.verification:
        label = 'Verification';
        color = Colors.amber;
        break;
      case TicketType.report:
        label = 'Report';
        color = Colors.brown;
        break;
      case TicketType.other:
        label = 'Other';
        color = Colors.grey;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}