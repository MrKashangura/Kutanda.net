// lib/screens/csr_dispute_resolution_screen.dart
import 'package:flutter/material.dart';

import '../models/support_ticket_model.dart';
import '../services/support_ticket_service.dart';
import '../widgets/csr_drawer.dart';

extension DisputeStatusExtension on DisputeStatus {
  String get statusText {
    switch (this) {
      case DisputeStatus.opened:
        return 'Opened';
      case DisputeStatus.reviewing:
        return 'Reviewing';
      case DisputeStatus.awaitingBuyerInput:
        return 'Awaiting Buyer';
      case DisputeStatus.awaitingSellerInput:
        return 'Awaiting Seller';
      case DisputeStatus.resolved:
        return 'Resolved';
      case DisputeStatus.closed:
        return 'Closed';
    }
  }
}

class CSRDisputeResolutionScreen extends StatefulWidget {
  const CSRDisputeResolutionScreen({super.key});

  @override
  State<CSRDisputeResolutionScreen> createState() => _CSRDisputeResolutionScreenState();
}

class _CSRDisputeResolutionScreenState extends State<CSRDisputeResolutionScreen> {
  final SupportTicketService _ticketService = SupportTicketService();
  // Removed unused _currentCsrId field
  bool _isLoading = true;
  List<DisputeTicket> _disputes = [];
  
  @override
  void initState() {
    super.initState();
    _loadDisputes();
  }
  
  Future<void> _loadDisputes() async {
    setState(() => _isLoading = true);
    
    try {
      final disputes = await _ticketService.getAllDisputes(
        statusFilter: DisputeStatus.opened,
      );
      
      if (mounted) {
        setState(() {
          _disputes = disputes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading disputes: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Dispute Resolution")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dispute Resolution"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDisputes,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const CSRDrawer(),
      body: _disputes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.gavel, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No active disputes to resolve',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _disputes.length,
              itemBuilder: (context, index) {
                final dispute = _disputes[index];
                return _buildDisputeCard(dispute);
              },
            ),
    );
  }
  
  Widget _buildDisputeCard(DisputeTicket dispute) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dispute #${dispute.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(dispute.status),
              ],
            ),
            const SizedBox(height: 16),
            Text('Issue: ${dispute.issue}'),
            if (dispute.disputeAmount != null)
              Text(
                'Disputed Amount: \$${dispute.disputeAmount!.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 16),
            const Text(
              'Involved Parties:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 8),
                const Text('Buyer ID: '),
                Text(
                  dispute.buyerId.substring(0, 8),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.store, size: 16),
                const SizedBox(width: 8),
                const Text('Seller ID: '),
                Text(
                  dispute.sellerId.substring(0, 8),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    // Navigate to related ticket
                    Navigator.pushNamed(
                      context, 
                      '/ticket_detail',
                      arguments: dispute.ticketId,
                    );
                  },
                  child: const Text('View Ticket'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _showResolveDisputeDialog(dispute);
                  },
                  child: const Text('Resolve Dispute'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusChip(DisputeStatus status) {
    Color color;
    
    switch (status) {
      case DisputeStatus.opened:
        color = Colors.blue;
        break;
      case DisputeStatus.reviewing:
        color = Colors.orange;
        break;
      case DisputeStatus.awaitingBuyerInput:
        color = Colors.purple;
        break;
      case DisputeStatus.awaitingSellerInput:
        color = Colors.teal;
        break;
      case DisputeStatus.resolved:
        color = Colors.green;
        break;
      case DisputeStatus.closed:
        color = Colors.grey;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // Fixed deprecated withOpacity
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        status.statusText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  void _showResolveDisputeDialog(DisputeTicket dispute) {
    final resolutionController = TextEditingController();
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Resolve Dispute'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resolution Decision:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: resolutionController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your resolution decision',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Additional Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    hintText: 'Enter additional notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (resolutionController.text.isEmpty) {
                  // Fixed: Use dialogContext instead of context
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please enter a resolution decision')),
                  );
                  return;
                }
                
                // Store resolution and notes before popping the dialog
                final resolution = resolutionController.text;
                final notes = notesController.text;
                
                // Close the dialog
                Navigator.pop(dialogContext);
                
                // Show loading state
                setState(() => _isLoading = true);
                
                try {
                  await _ticketService.resolveDispute(
                    dispute.id,
                    resolution,
                    notes,
                  );
                  
                  // Reload the disputes list
                  await _loadDisputes();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dispute resolved successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error resolving dispute: $e')),
                    );
                  }
                }
              },
              child: const Text('Resolve'),
            ),
          ],
        );
      },
    );
  }
}