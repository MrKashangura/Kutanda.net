// lib/screens/csr_content_moderation_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/helpers.dart';
import '../../../data/models/support_ticket_model.dart';
import '../../../services/content_moderation_service.dart';
import '../../../services/support_ticket_service.dart';
import '../widgets/csr_drawer.dart';

class CSRContentModerationScreen extends StatefulWidget {
  const CSRContentModerationScreen({super.key});

  @override
  State<CSRContentModerationScreen> createState() => _CSRContentModerationScreenState();
}

class _CSRContentModerationScreenState extends State<CSRContentModerationScreen>
    with SingleTickerProviderStateMixin {
  final ContentModerationService _moderationService = ContentModerationService();
  final SupportTicketService _ticketService = SupportTicketService();
  final SupabaseClient _supabase = Supabase.instance.client;
  late TabController _tabController;
  
  bool _isLoading = true;
  String? _currentCsrId;
  
  // Content lists
  List<Map<String, dynamic>> _pendingAuctions = [];
  List<Map<String, dynamic>> _reportedReviews = [];
  List<Map<String, dynamic>> _contentReports = [];
  List<Map<String, dynamic>> _reportedUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _getCurrentCsrId();
    _loadContentData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _getCurrentCsrId() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentCsrId = user.id;
      });
    }
  }

  Future<void> _loadContentData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all content categories
      final pendingAuctions = await _moderationService.getPendingAuctions();
      final reportedReviews = await _moderationService.getReportedReviews();
      final contentReports = await _moderationService.getContentReportsWithDetails();
      final reportedUsers = await _moderationService.getReportedUsers();
      
      setState(() {
        _pendingAuctions = pendingAuctions;
        _reportedReviews = reportedReviews;
        _contentReports = contentReports;
        _reportedUsers = reportedUsers;
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
    if (_currentCsrId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _moderationService.moderateAuction(
        auctionId,
        approve,
        _currentCsrId!,
        rejectionReason,
      );
      
      // Log the moderation action
      await _moderationService.logModeration(
        _currentCsrId!,
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
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error moderating auction: $e')),
        );
      }
    }
  }
  
  Future<void> _moderateReview(String reviewId, bool keep, {String? moderationNotes}) async {
    if (_currentCsrId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _moderationService.moderateReview(
        reviewId,
        keep,
        _currentCsrId!,
        moderationNotes,
      );
      
      // Log the moderation action
      await _moderationService.logModeration(
        _currentCsrId!,
        keep ? 'keep' : 'remove',
        'review',
        reviewId,
        moderationNotes,
      );
      
      // Reload content data
      await _loadContentData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review ${keep ? 'kept' : 'removed'} successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error moderating review: $e')),
        );
      }
    }
  }
  
  Future<void> _moderateContentReport(
    String reportId,
    ContentReportStatus decision,
    {String? notes}
  ) async {
    if (_currentCsrId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _ticketService.moderateContentReport(
        reportId,
        decision,
        _currentCsrId!,
        notes,
      );
      
      // Log the moderation action
      await _moderationService.logModeration(
        _currentCsrId!,
        decision == ContentReportStatus.approved ? 'approve_report' : 'reject_report',
        'content_report',
        reportId,
        notes,
      );
      
      // Reload content data
      await _loadContentData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Content report ${decision == ContentReportStatus.approved ? 'approved' : 'rejected'} successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error handling content report: $e')),
        );
      }
    }
  }
  
  Future<void> _moderateUser(
    String userId,
    String action,
    {String? moderationNotes}
  ) async {
    if (_currentCsrId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _moderationService.moderateUser(
        userId,
        action,
        _currentCsrId!,
        moderationNotes,
      );
      
      // Log the moderation action
      await _moderationService.logModeration(
        _currentCsrId!,
        action,
        'user',
        userId,
        moderationNotes,
      );
      
      // Reload content data
      await _loadContentData();
      
      if (mounted) {
        String actionVerb;
        switch (action) {
          case 'warn':
            actionVerb = 'warned';
            break;
          case 'suspend':
            actionVerb = 'suspended';
            break;
          case 'ban':
            actionVerb = 'banned';
            break;
          case 'clear':
            actionVerb = 'cleared';
            break;
          default:
            actionVerb = 'moderated';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User $actionVerb successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error moderating user: $e')),
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
  
  void _showReviewModerationDialog(String reviewId, String reviewContent) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Moderate Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Review Content:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(reviewContent),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  hintText: 'Moderation notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _moderateReview(reviewId, true, moderationNotes: notesController.text);
              },
              child: const Text('Keep Review'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _moderateReview(reviewId, false, moderationNotes: notesController.text);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remove Review'),
            ),
          ],
        );
      },
    );
  }
  
  void _showContentReportModerationDialog(String reportId, Map<String, dynamic> report) {
    final contentType = report['content_type'] as String;
    final notesController = TextEditingController();
    final contentDetails = report['content_details'] as Map<String, dynamic>;
    
    // Extract relevant content to show
    String contentPreview = 'Content not available';
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
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Moderate Reported Content'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Content Type: ${contentType.capitalize()}', 
                style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Report Reason: ${report['reason'] ?? 'N/A'}'),
              const SizedBox(height: 16),
              const Text('Content Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(contentPreview),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  hintText: 'Moderation notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _moderateContentReport(
                  reportId,
                  ContentReportStatus.rejected,
                  notes: notesController.text,
                );
              },
              child: const Text('Reject Report'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _moderateContentReport(
                  reportId,
                  ContentReportStatus.approved,
                  notes: notesController.text,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Approve & Remove Content'),
            ),
          ],
        );
      },
    );
  }
  
  void _showUserModerationDialog(String userId, Map<String, dynamic> userData) {
    final notesController = TextEditingController();
    String email = userData['email'] ?? 'N/A';
    String displayName = userData['display_name'] ?? 'N/A';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Take Action on User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User: $email', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Name: $displayName'),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  hintText: 'Moderation notes (required)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (notesController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter moderation notes')),
                  );
                  return;
                }
                Navigator.pop(context);
                _moderateUser(userId, 'warn', moderationNotes: notesController.text);
              },
              child: const Text('Warn User'),
            ),
            ElevatedButton(
              onPressed: () {
                if (notesController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter moderation notes')),
                  );
                  return;
                }
                Navigator.pop(context);
                _moderateUser(userId, 'suspend', moderationNotes: notesController.text);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Suspend (7 days)'),
            ),
            ElevatedButton(
              onPressed: () {
                if (notesController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter moderation notes')),
                  );
                  return;
                }
                Navigator.pop(context);
                _moderateUser(userId, 'ban', moderationNotes: notesController.text);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Ban User'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _moderateUser(userId, 'clear', moderationNotes: 'Cleared user flags');
              },
              child: const Text('Clear Flags'),
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
        appBar: AppBar(title: const Text("Content Moderation")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Content Moderation"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Auctions (${_pendingAuctions.length})"),
            Tab(text: "Reviews (${_reportedReviews.length})"),
            Tab(text: "Reports (${_contentReports.length})"),
            Tab(text: "Users (${_reportedUsers.length})"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContentData,
            tooltip: 'Refresh Content',
          ),
        ],
      ),
      drawer: const CSRDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Auctions Tab
          _buildPendingAuctionsTab(),
          
          // Reviews Tab
          _buildReportedReviewsTab(),
          
          // Content Reports Tab
          _buildContentReportsTab(),
          
          // Reported Users Tab
          _buildReportedUsersTab(),
        ],
      ),
    );
  }
  
  Widget _buildPendingAuctionsTab() {
    if (_pendingAuctions.isEmpty) {
      return const Center(
        child: Text('No pending auctions to review'),
      );
    }
    
    return ListView.builder(
      itemCount: _pendingAuctions.length,
      itemBuilder: (context, index) {
        final auction = _pendingAuctions[index];
        final seller = auction['users'] as Map<String, dynamic>; // Joined data
        
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
                subtitle: Text('Seller: ${seller['display_name'] ?? seller['email'] ?? 'Unknown'}'),
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
  
  Widget _buildReportedReviewsTab() {
    if (_reportedReviews.isEmpty) {
      return const Center(
        child: Text('No reported reviews to moderate'),
      );
    }
    
    return ListView.builder(
      itemCount: _reportedReviews.length,
      itemBuilder: (context, index) {
        final review = _reportedReviews[index];
        final author = review['author'] as Map<String, dynamic>; // Joined data
        final reporter = review['reporter'] as Map<String, dynamic>; // Joined data
        
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with review author and reporter
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Author: ${author['display_name'] ?? author['email'] ?? 'Unknown'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reported by: ${reporter['display_name'] ?? reporter['email'] ?? 'Unknown'}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Rating
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${review['rating'] ?? 'N/A'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Review content
                const Text(
                  'Review Content:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(review['content'] ?? 'No content'),
                
                const SizedBox(height: 16),
                
                // Report information
                const Text(
                  'Report Reason:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(review['report_reason'] ?? 'Reason not specified'),
                
                const SizedBox(height: 16),
                
                // Timestamp
                Row(
                  children: [
                    Text(
                      'Reported: ${formatRelativeTime(DateTime.parse(review['reported_at'] ?? review['created_at']))}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => _showReviewModerationDialog(
                        review['id'],
                        review['content'] ?? 'No content',
                      ),
                      child: const Text('Moderate Review'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildContentReportsTab() {
    if (_contentReports.isEmpty) {
      return const Center(
        child: Text('No content reports to moderate'),
      );
    }
    
    return ListView.builder(
      itemCount: _contentReports.length,
      itemBuilder: (context, index) {
        final report = _contentReports[index];
        final reporter = report['reporter'] as Map<String, dynamic>; // Joined data
        final contentType = report['content_type'] as String;
        final contentDetails = report['content_details'] as Map<String, dynamic>;
        
        // Format content preview based on type
        String contentPreview = 'Content preview not available';
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
        
        // Truncate content preview if too long
        if (contentPreview.length > 100) {
          contentPreview = '${contentPreview.substring(0, 97)}...';
        }
        
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with report type and ID
                Row(
                  children: [
                    _buildContentTypeChip(contentType),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Report ID: ${report['id'].substring(0, 8)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Reporter info
                Text(
                  'Reported by: ${reporter['display_name'] ?? reporter['email'] ?? 'Unknown'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                
                const SizedBox(height: 8),
                
                // Report reason
                const Text(
                  'Reason for Report:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(report['reason'] ?? 'No reason provided'),
                
                const SizedBox(height: 8),
                
                // Content preview
                const Text(
                  'Content Preview:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(contentPreview),
                
                const SizedBox(height: 8),
                
                // Timestamp
                Text(
                  'Reported: ${formatRelativeTime(DateTime.parse(report['created_at']))}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                
                const SizedBox(height: 16),
                
                // Action button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => _showContentReportModerationDialog(
                        report['id'],
                        report,
                      ),
                      child: const Text('Review Report'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildReportedUsersTab() {
    if (_reportedUsers.isEmpty) {
      return const Center(
        child: Text('No reported users to moderate'),
      );
    }
    
    return ListView.builder(
      itemCount: _reportedUsers.length,
      itemBuilder: (context, index) {
        final user = _reportedUsers[index];
        
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User information
                ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      (user['email'] as String?)?.isNotEmpty == true
                          ? (user['email'] as String)[0].toUpperCase()
                          : 'U',
                    ),
                  ),
                  title: Text(
                    user['display_name'] ?? 'No Display Name',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(user['email'] ?? 'No Email'),
                  trailing: _buildUserStatusChips(user),
                ),
                
                const SizedBox(height: 8),
                
                // Role and join date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Text(
                        'Role: ${user['role'] ?? 'Unknown'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Joined: ${formatDate(DateTime.parse(user['created_at']))}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Report information
                const Text(
                  'Report Information:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(user['report_reason'] ?? 'No specific reason provided'),
                
                const SizedBox(height: 16),
                
                // Action button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => _showUserModerationDialog(
                        user['id'],
                        user,
                      ),
                      child: const Text('Take Action'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildContentTypeChip(String contentType) {
    Color color;
    IconData icon;
    String label;
    
    switch (contentType) {
      case 'auction':
        color = Colors.green;
        icon = Icons.gavel;
        label = 'Auction';
        break;
      case 'review':
        color = Colors.amber;
        icon = Icons.star;
        label = 'Review';
        break;
      case 'user':
        color = Colors.blue;
        icon = Icons.person;
        label = 'User';
        break;
      case 'message':
        color = Colors.purple;
        icon = Icons.message;
        label = 'Message';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        label = 'Unknown';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserStatusChips(Map<String, dynamic> user) {
    // Check for various flags
    final bool isReported = user['is_reported'] == true;
    final bool isWarned = user['is_warned'] == true;
    final bool isSuspended = user['is_suspended'] == true;
    final bool isBanned = user['is_banned'] == true;
    
    if (!isReported && !isWarned && !isSuspended && !isBanned) {
      return const SizedBox.shrink();
    }
    
    // Choose the most severe status to display
    if (isBanned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red),
        ),
        child: const Text(
          'BANNED',
          style: TextStyle(
            fontSize: 12,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (isSuspended) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange),
        ),
        child: const Text(
          'SUSPENDED',
          style: TextStyle(
            fontSize: 12,
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (isWarned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber),
        ),
        child: const Text(
          'WARNED',
          style: TextStyle(
            fontSize: 12,
            color: Colors.amber,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple),
        ),
        child: const Text(
          'REPORTED',
          style: TextStyle(
            fontSize: 12,
            color: Colors.purple,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}