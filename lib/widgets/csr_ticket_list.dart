// lib/widgets/csr_ticket_list.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/support_ticket_model.dart';
import '../screens/ticket_detail_screen.dart';
import '../services/support_ticket_service.dart';
import '../utils/helpers.dart';

class CSRTicketList extends StatefulWidget {
  final TicketStatus statusFilter;
  final TicketPriority? priorityFilter;
  final TicketType? typeFilter;
  final String? assignedCsrId;
  final Function? onRefreshData;

  const CSRTicketList({
    required this.statusFilter,
    this.priorityFilter,
    this.typeFilter,
    this.assignedCsrId,
    this.onRefreshData,
    super.key,
  });

  @override
  State<CSRTicketList> createState() => _CSRTicketListState();
}

class _CSRTicketListState extends State<CSRTicketList> {
  final SupportTicketService _ticketService = SupportTicketService();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<SupportTicket> _tickets = [];
  String? _currentCsrId;
  String _sortBy = 'date';
  bool _sortAscending = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _getCurrentCsrId();
    _loadTickets();
  }

  Future<void> _getCurrentCsrId() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentCsrId = user.id;
      });
    }
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    
    try {
      // Get all tickets matching filters
      final tickets = await _ticketService.getAllTickets(
        statusFilter: widget.statusFilter,
        priorityFilter: widget.priorityFilter,
        typeFilter: widget.typeFilter,
        assignedCsrId: widget.assignedCsrId,
      );
      
      // Apply search filter if provided
      List<SupportTicket> filteredTickets = tickets;
      if (_searchQuery.isNotEmpty) {
        filteredTickets = tickets.where((ticket) {
          return ticket.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 ticket.description.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
      
      // Apply sorting
      _sortTickets(filteredTickets);
      
      setState(() {
        _tickets = filteredTickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tickets: $e')),
        );
      }
    }
  }
  
  void _sortTickets(List<SupportTicket> tickets) {
    switch (_sortBy) {
      case 'date':
        tickets.sort((a, b) => _sortAscending
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt));
        break;
      case 'priority':
        tickets.sort((a, b) => _sortAscending
            ? a.priority.index.compareTo(b.priority.index)
            : b.priority.index.compareTo(a.priority.index));
        break;
      case 'type':
        tickets.sort((a, b) => _sortAscending
            ? a.type.toString().compareTo(b.type.toString())
            : b.type.toString().compareTo(a.type.toString()));
        break;
    }
  }
  
  Future<void> _assignToMe(SupportTicket ticket) async {
    if (_currentCsrId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _ticketService.assignTicket(ticket.id, _currentCsrId!);
      await _ticketService.updateTicketStatus(ticket.id, TicketStatus.inProgress);
      
      // Reload tickets
      await _loadTickets();
      
      // Call parent refresh if provided
      widget.onRefreshData?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket assigned to you and moved to In Progress')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning ticket: $e')),
        );
      }
    }
  }
  
  Future<void> _quickUpdateStatus(SupportTicket ticket, TicketStatus newStatus) async {
    setState(() => _isLoading = true);
    
    try {
      await _ticketService.updateTicketStatus(ticket.id, newStatus);
      
      // Reload tickets
      await _loadTickets();
      
      // Call parent refresh if provided
      widget.onRefreshData?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ticket moved to ${newStatus.toString().split('.').last}')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating ticket: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No ${widget.statusFilter.toString().split('.').last} tickets found',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadTickets,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Search and sort controls
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Search field
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search tickets...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _loadTickets();
                  },
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Sort dropdown
              DropdownButton<String>(
                value: _sortBy,
                icon: const Icon(Icons.sort),
                underline: Container(height: 2, color: Theme.of(context).primaryColor),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      // If selecting the same sort field, toggle direction
                      if (_sortBy == newValue) {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortBy = newValue;
                        // Default to descending for date, ascending for others
                        _sortAscending = newValue != 'date';
                      }
                      
                      _sortTickets(_tickets);
                    });
                  }
                },
                items: <String>['date', 'priority', 'type']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Text('Sort by ${value.capitalize()}'),
                        const SizedBox(width: 4),
                        Icon(
                          _sortBy == value
                              ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                              : null,
                          size: 16,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        
        // Tickets list
        Expanded(
          child: ListView.builder(
            itemCount: _tickets.length,
            itemBuilder: (context, index) {
              final ticket = _tickets[index];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  onTap: () {
                    // Navigate to ticket detail
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TicketDetailScreen(
                          ticketId: ticket.id,
                          onTicketUpdated: () {
                            _loadTickets();
                            widget.onRefreshData?.call();
                          },
                        ),
                      ),
                    );
                  },
                  leading: _buildPriorityIndicator(ticket.priority),
                  title: Text(
                    ticket.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        truncateWithEllipsis(ticket.description, 100),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildTypeChip(ticket.type),
                          const SizedBox(width: 8),
                          Text(
                            'Created: ${formatRelativeTime(ticket.createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: widget.statusFilter == TicketStatus.open &&
                             ticket.assignedCsrId == null ? 
                    TextButton(
                      onPressed: () => _assignToMe(ticket),
                      child: const Text('Assign to me'),
                    ) : 
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showTicketActions(ticket),
                    ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildPriorityIndicator(TicketPriority priority) {
    Color color;
    String tooltip;
    
    switch (priority) {
      case TicketPriority.low:
        color = Colors.green;
        tooltip = 'Low Priority';
        break;
      case TicketPriority.medium:
        color = Colors.orange;
        tooltip = 'Medium Priority';
        break;
      case TicketPriority.high:
        color = Colors.red;
        tooltip = 'High Priority';
        break;
      case TicketPriority.urgent:
        color = Colors.purple;
        tooltip = 'Urgent Priority';
        break;
    }
    
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
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
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  void _showTicketActions(SupportTicket ticket) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View Ticket Details'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TicketDetailScreen(
                        ticketId: ticket.id,
                        onTicketUpdated: () {
                          _loadTickets();
                          widget.onRefreshData?.call();
                        },
                      ),
                    ),
                  );
                },
              ),
              
              if (widget.statusFilter != TicketStatus.open)
                ListTile(
                  leading: const Icon(Icons.replay),
                  title: const Text('Move to Open'),
                  onTap: () {
                    Navigator.pop(context);
                    _quickUpdateStatus(ticket, TicketStatus.open);
                  },
                ),
              
              if (widget.statusFilter != TicketStatus.inProgress)
                ListTile(
                  leading: const Icon(Icons.work),
                  title: const Text('Move to In Progress'),
                  onTap: () {
                    Navigator.pop(context);
                    _quickUpdateStatus(ticket, TicketStatus.inProgress);
                  },
                ),
              
              if (widget.statusFilter != TicketStatus.pendingUser)
                ListTile(
                  leading: const Icon(Icons.hourglass_top),
                  title: const Text('Awaiting User Response'),
                  onTap: () {
                    Navigator.pop(context);
                    _quickUpdateStatus(ticket, TicketStatus.pendingUser);
                  },
                ),
              
              if (widget.statusFilter != TicketStatus.resolved)
                ListTile(
                  leading: const Icon(Icons.check_circle),
                  title: const Text('Mark as Resolved'),
                  onTap: () {
                    Navigator.pop(context);
                    _quickUpdateStatus(ticket, TicketStatus.resolved);
                  },
                ),
              
              if (widget.statusFilter != TicketStatus.closed)
                ListTile(
                  leading: const Icon(Icons.archive),
                  title: const Text('Close Ticket'),
                  onTap: () {
                    Navigator.pop(context);
                    _quickUpdateStatus(ticket, TicketStatus.closed);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}