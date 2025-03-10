// lib/features/support/screens/admin_content_moderation_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/helpers.dart';
import '../../../services/content_moderation_service.dart';
import '../widgets/admin_drawer.dart';

class AdminContentModerationScreen extends StatefulWidget {
  const AdminContentModerationScreen({super.key});

  @override
  State<AdminContentModerationScreen> createState() => _AdminContentModerationScreenState();
}

class _AdminContentModerationScreenState extends State<AdminContentModerationScreen> with SingleTickerProviderStateMixin {
  final ContentModerationService _moderationService = ContentModerationService();
  late TabController _tabController;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingAuctions = [];
  List<Map<String, dynamic>> _reportedContent = [];
  List<Map<String, dynamic>> _moderationLogs = [];
  Map<String, dynamic> _moderationStats = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadContentData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContentData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load content needing moderation
      final pendingAuctions = await _moderationService.getPendingAuctions();
      final reportedContent = await _moderationService.getContentReportsWithDetails();
      
      // Load moderation logs and stats
      final moderationLogs = await _moderationService.getModerationLogs();
      final moderationStats = await _moderationService.getModerationStats(lastDays: 30);
      
      setState(() {
        _pendingAuctions = pendingAuctions;
        _reportedContent = reportedContent;
        _moderationLogs = moderationLogs;
        _moderationStats = moderationStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading content data: $e')),
        );
      }
    }
  }
  
  Future<void> _moderateAuction(String auctionId, bool approve, {String? rejectionReason}) async {
    setState(() => _isLoading = true);
    
    try {
      final adminId = Supabase.instance.client.auth.currentUser?.id;
      if (adminId == null) {
        throw Exception('Admin ID not found');
      }
      
      final success = await _moderationService.moderateAuction(
        auctionId,
        approve,
        adminId,
        rejectionReason,
      );
      
      if (success) {
        // Log the moderation action
        await _moderationService.logModeration(
          adminId,
          approve ? 'approve' : 'reject',
          'auction',
          auctionId,
          rejectionReason,
        );
        
        // Reload content data
        await _loadContentData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Auction ${approve ? 'approved' : 'rejected'} successfully')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error moderating auction: $e')),
        );
      }
    }
  }
  
  void _showRejectionDialog(String auctionId) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rejection Reason'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              hintText: 'Enter reason for rejection',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _moderateAuction(auctionId, false, rejectionReason: reasonController.text);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }
  
  void _handleReportedContent(String reportId, String contentId, String contentType, bool approve, {String? notes}) async {
    setState(() => _isLoading = true);
    
    try {
      final adminId = Supabase.instance.client.auth.currentUser?.id;
      if (adminId == null) {
        throw Exception('Admin ID not found');
      }
      
      // Update the report status
      // TODO: Implement report status update in content_moderation_service.dart
      
      // Take action on the reported content
      bool success = false;
      switch (contentType) {
        case 'auction':
          success = await _moderationService.moderateAuction(
            contentId,
            !approve, // If approving the report, reject the auction
            adminId,
            notes,
          );
          break;
        
        case 'review':
          success = await _moderationService.moderateReview(
            contentId,
            !approve, // If approving the report, hide the review
            adminId,
            notes,
          );
          break;
        
        // Add other content types as needed
      }
      
      if (success) {
        // Log the moderation action
        await _moderationService.logModeration(
          adminId,
          approve ? 'approve_report' : 'reject_report',
          contentType,
          contentId,
          notes,
        );
        
        // Reload content data
        await _loadContentData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Report ${approve ? 'approved' : 'rejected'} successfully')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error handling report: $e')),
        );
      }
    }
  }
  
  void _showReportDialog(Map<String, dynamic> report) {
    final contentType = report['content_type'] as String;
    final contentId = report['content_id'] as String;
    final contentDetails = report['content_details'] as Map<String, dynamic>?;
    final reportId = report['id'] as String;
    final notesController = TextEditingController();
    
    // Extract relevant content to show
    String contentPreview = 'Content not available';
    if (contentDetails != null) {
      switch (contentType) {
        case 'auction':
          contentPreview = 'Title: ${contentDetails['title'] ?? 'N/A'}\n'
              'Description: ${contentDetails['description'] ?? 'N/A'}';
          break;
        case 'review':
          contentPreview = 'Review: ${contentDetails['content'] ?? 'N/A'}\n'
              'Rating: ${contentDetails['rating'] ?? 'N/A'}';
          break;
        case 'user':
          contentPreview = 'User: ${contentDetails['email'] ?? 'N/A'}\n'
              'Name: ${contentDetails['display_name'] ?? 'N/A'}';
          break;
        case 'message':
          contentPreview = 'Message: ${contentDetails['content'] ?? 'N/A'}';
          break;
      }
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Review Reported Content'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Content Type: ${contentType.capitalize()}', 
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Reporter: ${report['reporter']?['email'] ?? report['reporter_id'] ?? 'Unknown'}'),
                const SizedBox(height: 8),
                Text('Report Reason: ${report['reason'] ?? 'N/A'}'),
                const SizedBox(height: 16),
                const Text('Content Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(contentPreview),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Moderation Notes',
                    hintText: 'Add notes about this decision',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
              onPressed: () {
                Navigator.pop(context);
                _handleReportedContent(
                  reportId,
                  contentId,
                  contentType,
                  false, // Reject report
                  notes: notesController.text,
                );
              },
              child: const Text('Reject Report'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleReportedContent(
                  reportId,
                  contentId,
                  contentType,
                  true, // Approve report
                  notes: notesController.text,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remove Content'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Content Moderation"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContentData,
            tooltip: "Refresh Data",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Pending Approvals"),
            Tab(text: "Reported Content"),
            Tab(text: "Moderation Logs"),
          ],
        ),
      ),
      drawer: const AdminDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingAuctionsTab(),
                _buildReportedContentTab(),
                _buildModerationLogsTab(),
              ],
            ),
    );
  }

  Widget _buildPendingAuctionsTab() {
    if (_pendingAuctions.isEmpty) {
      return const Center(
        child: Text('No pending auctions to approve'),
      );
    }
    
    return ListView.builder(
      itemCount: _pendingAuctions.length,
      itemBuilder: (context, index) {
        final auction = _pendingAuctions[index];
        final seller = auction['users'] as Map<String, dynamic>?; // Joined data
        
        return Card(
          margin: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with auction title and seller
              ListTile(
                title: Text(
                  auction['title'] ?? 'Untitled Auction',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Seller: ${seller?['display_name'] ?? seller?['email'] ?? 'Unknown'}'),
                trailing: Text('\$${auction['starting_price']}'),
              ),
              
              // Image if available
              if (auction['image_urls'] != null && 
                  (auction['image_urls'] as List).isNotEmpty)
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Image.network(
                    (auction['image_urls'] as List).first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),
                ),
              
              // Description
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(auction['description'] ?? 'No description provided'),
                  ],
                ),
              ),
              
              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => _showRejectionDialog(auction['id']),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => _moderateAuction(auction['id'], true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Approve'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildReportedContentTab() {
    if (_reportedContent.isEmpty) {
      return const Center(
        child: Text('No reported content to review'),
      );
    }
    
    return ListView.builder(
      itemCount: _reportedContent.length,
      itemBuilder: (context, index) {
        final report = _reportedContent[index];
        final contentType = report['content_type'] as String;
        final contentDetails = report['content_details'] as Map<String, dynamic>?;
        final reporter = report['reporter'] as Map<String, dynamic>?;
        
        // Format content preview based on type
        String contentPreview = 'Content preview not available';
        if (contentDetails != null) {
          switch (contentType) {
            case 'auction':
              contentPreview = contentDetails['title'] ?? 'No title';
              break;
            case 'review':
              contentPreview = contentDetails['content'] ?? 'No content';
              break;
            case 'user':
              contentPreview = contentDetails['email'] ?? 'No email';
              break;
            case 'message':
              contentPreview = contentDetails['content'] ?? 'No content';
              break;
          }
        }
        
        // Truncate content preview if too long
        if (contentPreview.length > 100) {
          contentPreview = '${contentPreview.substring(0, 97)}...';
        }
        
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getContentTypeColor(contentType),
              child: Icon(
                _getContentTypeIcon(contentType),
                color: Colors.white,
              ),
            ),
            title: Text(
              'Reported ${contentType.capitalize()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reason: ${report['reason'] ?? 'No reason provided'}'),
                Text('Content: $contentPreview'),
                Text(
                  'Reported by: ${reporter?['display_name'] ?? reporter?['email'] ?? 'Unknown'} on ${formatRelativeTime(DateTime.parse(report['created_at']))}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showReportDialog(report),
            ),
            onTap: () => _showReportDialog(report),
            isThreeLine: true,
          ),
        );
      },
    );
  }
  
  Widget _buildModerationLogsTab() {
    if (_moderationLogs.isEmpty) {
      return const Center(
        child: Text('No moderation logs available'),
      );
    }
    
    return Column(
      children: [
        // Moderation stats summary
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Moderation Statistics (Last 30 Days)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      'Total Actions',
                      _moderationStats['total_actions']?.toString() ?? '0',
                      Icons.receipt_long,
                    ),
                    _buildStatColumn(
                      'Approval Rate',
                      '${((_moderationStats['auction_approval_rate'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                      Icons.check_circle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Logs list
        Expanded(
          child: ListView.builder(
            itemCount: _moderationLogs.length,
            itemBuilder: (context, index) {
              final log = _moderationLogs[index];
              final moderator = log['moderator'] as Map<String, dynamic>?;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getActionTypeColor(log['action_type']),
                    child: Icon(
                      _getActionTypeIcon(log['action_type']),
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    '${_formatActionType(log['action_type'])} ${log['content_type']?.toString().capitalize() ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (log['notes'] != null && (log['notes'] as String).isNotEmpty)
                        Text('Notes: ${log['notes']}'),
                      Text(
                        'By ${moderator?['display_name'] ?? moderator?['email'] ?? 'Unknown'} on ${formatDate(DateTime.parse(log['timestamp']))}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  isThreeLine: log['notes'] != null && (log['notes'] as String).isNotEmpty,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  IconData _getContentTypeIcon(String contentType) {
    switch (contentType) {
      case 'auction':
        return Icons.gavel;
      case 'review':
        return Icons.star;
      case 'user':
        return Icons.person;
      case 'message':
        return Icons.message;
      default:
        return Icons.content_paste;
    }
  }
  
  Color _getContentTypeColor(String contentType) {
    switch (contentType) {
      case 'auction':
        return Colors.green;
      case 'review':
        return Colors.amber;
      case 'user':
        return Colors.blue;
      case 'message':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getActionTypeIcon(String? actionType) {
    switch (actionType) {
      case 'approve':
        return Icons.check;
      case 'reject':
        return Icons.close;
      case 'approve_report':
        return Icons.report_problem;
      case 'reject_report':
        return Icons.remove_circle;
      default:
        return Icons.edit;
    }
  }
  
  Color _getActionTypeColor(String? actionType) {
    switch (actionType) {
      case 'approve':
        return Colors.green;
      case 'reject':
        return Colors.red;
      case 'approve_report':
        return Colors.orange;
      case 'reject_report':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  String _formatActionType(String? actionType) {
    if (actionType == null) return 'Unknown';
    
    // Convert from snake_case or camelCase to Title Case with spaces
    return actionType
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match[0]}') // Handle camelCase
        .replaceAll('_', ' ') // Handle snake_case
        .trim()
        .split(' ')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}