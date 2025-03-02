// lib/models/support_ticket_model.dart
import 'package:uuid/uuid.dart';

/// Status options for a support ticket
enum TicketStatus {
  open,        // Newly created ticket
  inProgress,  // CSR is working on it
  pendingUser, // Waiting for user response
  resolved,    // Issue has been resolved
  closed       // Ticket is closed and archived
}

/// Priority levels for tickets
enum TicketPriority {
  low,
  medium,
  high,
  urgent
}

/// Types of support tickets
enum TicketType {
  general,      // General inquiries
  auction,      // Auction-related issues
  payment,      // Payment issues
  shipping,     // Shipping and delivery
  account,      // Account-related issues
  dispute,      // Dispute between buyer and seller
  verification, // Account verification issues
  report,       // Reporting content or users
  other         // Miscellaneous
}

/// Main support ticket model
class SupportTicket {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime createdAt;
  final TicketStatus status;
  final TicketPriority priority;
  final TicketType type;
  final String? assignedCsrId;
  final DateTime? lastUpdated;
  final List<TicketMessage> messages;
  final Map<String, dynamic>? metadata; // For additional data like auction ID, order ID, etc.
  
  SupportTicket({
    String? id,
    required this.userId,
    required this.title,
    required this.description,
    DateTime? createdAt,
    this.status = TicketStatus.open,
    this.priority = TicketPriority.medium,
    required this.type,
    this.assignedCsrId,
    this.lastUpdated,
    List<TicketMessage>? messages,
    this.metadata,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    messages = messages ?? [],
    lastUpdated = lastUpdated ?? DateTime.now();
  
  /// Create a copy of this ticket with updated fields
  SupportTicket copyWith({
    String? userId,
    String? title,
    String? description,
    TicketStatus? status,
    TicketPriority? priority,
    TicketType? type,
    String? assignedCsrId,
    List<TicketMessage>? messages,
    Map<String, dynamic>? metadata,
  }) {
    return SupportTicket(
      id: id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      type: type ?? this.type,
      assignedCsrId: assignedCsrId ?? this.assignedCsrId,
      lastUpdated: DateTime.now(), // Always update lastUpdated
      messages: messages ?? this.messages,
      metadata: metadata ?? this.metadata,
    );
  }
  
  /// Add a message to this ticket and update lastUpdated
  SupportTicket addMessage(TicketMessage message) {
    final updatedMessages = List<TicketMessage>.from(messages)..add(message);
    return copyWith(
      messages: updatedMessages,
    );
  }
  
  /// Convert to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'type': type.toString().split('.').last,
      'assigned_csr_id': assignedCsrId,
      'last_updated': lastUpdated?.toIso8601String(),
      'metadata': metadata,
    };
  }
  
  /// Create from Map from Supabase
  factory SupportTicket.fromMap(Map<String, dynamic> map, {List<TicketMessage>? messages}) {
    return SupportTicket(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      description: map['description'],
      createdAt: DateTime.parse(map['created_at']),
      status: _stringToTicketStatus(map['status']),
      priority: _stringToTicketPriority(map['priority']),
      type: _stringToTicketType(map['type']),
      assignedCsrId: map['assigned_csr_id'],
      lastUpdated: map['last_updated'] != null 
          ? DateTime.parse(map['last_updated']) 
          : null,
      messages: messages ?? [],
      metadata: map['metadata'],
    );
  }
  
  static TicketStatus _stringToTicketStatus(String status) {
    switch (status) {
      case 'open': return TicketStatus.open;
      case 'inProgress': return TicketStatus.inProgress;
      case 'pendingUser': return TicketStatus.pendingUser;
      case 'resolved': return TicketStatus.resolved;
      case 'closed': return TicketStatus.closed;
      default: return TicketStatus.open;
    }
  }
  
  static TicketPriority _stringToTicketPriority(String priority) {
    switch (priority) {
      case 'low': return TicketPriority.low;
      case 'medium': return TicketPriority.medium;
      case 'high': return TicketPriority.high;
      case 'urgent': return TicketPriority.urgent;
      default: return TicketPriority.medium;
    }
  }
  
  static TicketType _stringToTicketType(String type) {
    switch (type) {
      case 'general': return TicketType.general;
      case 'auction': return TicketType.auction;
      case 'payment': return TicketType.payment;
      case 'shipping': return TicketType.shipping;
      case 'account': return TicketType.account;
      case 'dispute': return TicketType.dispute;
      case 'verification': return TicketType.verification;
      case 'report': return TicketType.report;
      case 'other': return TicketType.other;
      default: return TicketType.general;
    }
  }
  
  /// Get user-friendly status text
  String get statusText {
    switch (status) {
      case TicketStatus.open: return 'Open';
      case TicketStatus.inProgress: return 'In Progress';
      case TicketStatus.pendingUser: return 'Pending User';
      case TicketStatus.resolved: return 'Resolved';
      case TicketStatus.closed: return 'Closed';
    }
  }
  
  /// Get user-friendly priority text
  String get priorityText {
    switch (priority) {
      case TicketPriority.low: return 'Low';
      case TicketPriority.medium: return 'Medium';
      case TicketPriority.high: return 'High';
      case TicketPriority.urgent: return 'Urgent';
    }
  }
  
  /// Get user-friendly type text
  String get typeText {
    switch (type) {
      case TicketType.general: return 'General';
      case TicketType.auction: return 'Auction';
      case TicketType.payment: return 'Payment';
      case TicketType.shipping: return 'Shipping';
      case TicketType.account: return 'Account';
      case TicketType.dispute: return 'Dispute';
      case TicketType.verification: return 'Verification';
      case TicketType.report: return 'Report';
      case TicketType.other: return 'Other';
    }
  }
}

/// Message within a support ticket
class TicketMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isFromCSR;
  final List<String>? attachmentUrls;
  
  TicketMessage({
    String? id,
    required this.ticketId,
    required this.senderId,
    required this.content,
    DateTime? timestamp,
    required this.isFromCSR,
    this.attachmentUrls,
  }) : 
    id = id ?? const Uuid().v4(),
    timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'sender_id': senderId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'is_from_csr': isFromCSR,
      'attachment_urls': attachmentUrls,
    };
  }
  
  factory TicketMessage.fromMap(Map<String, dynamic> map) {
    return TicketMessage(
      id: map['id'],
      ticketId: map['ticket_id'],
      senderId: map['sender_id'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
      isFromCSR: map['is_from_csr'] ?? false,
      attachmentUrls: map['attachment_urls'] != null 
          ? List<String>.from(map['attachment_urls'])
          : null,
    );
  }
}

/// Model for dispute resolution
class DisputeTicket {
  final String id;
  final String ticketId; // Reference to the related support ticket
  final String auctionId;
  final String buyerId;
  final String sellerId;
  final String issue;
  final double? disputeAmount;
  final DisputeStatus status;
  final String? resolution;
  final String? csrNotes;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  
  DisputeTicket({
    String? id,
    required this.ticketId,
    required this.auctionId,
    required this.buyerId,
    required this.sellerId,
    required this.issue,
    this.disputeAmount,
    this.status = DisputeStatus.opened,
    this.resolution,
    this.csrNotes,
    DateTime? createdAt,
    this.resolvedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'auction_id': auctionId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'issue': issue,
      'dispute_amount': disputeAmount,
      'status': status.toString().split('.').last,
      'resolution': resolution,
      'csr_notes': csrNotes,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }
  
  factory DisputeTicket.fromMap(Map<String, dynamic> map) {
    return DisputeTicket(
      id: map['id'],
      ticketId: map['ticket_id'],
      auctionId: map['auction_id'],
      buyerId: map['buyer_id'],
      sellerId: map['seller_id'],
      issue: map['issue'],
      disputeAmount: map['dispute_amount'] != null 
          ? (map['dispute_amount'] as num).toDouble()
          : null,
      status: _stringToDisputeStatus(map['status']),
      resolution: map['resolution'],
      csrNotes: map['csr_notes'],
      createdAt: DateTime.parse(map['created_at']),
      resolvedAt: map['resolved_at'] != null 
          ? DateTime.parse(map['resolved_at'])
          : null,
    );
  }
  
  static DisputeStatus _stringToDisputeStatus(String status) {
    switch (status) {
      case 'opened': return DisputeStatus.opened;
      case 'reviewing': return DisputeStatus.reviewing;
      case 'awaitingBuyerInput': return DisputeStatus.awaitingBuyerInput;
      case 'awaitingSellerInput': return DisputeStatus.awaitingSellerInput;
      case 'resolved': return DisputeStatus.resolved;
      case 'closed': return DisputeStatus.closed;
      default: return DisputeStatus.opened;
    }
  }
  
  /// Create a copy with updated fields
  DisputeTicket copyWith({
    String? ticketId,
    String? auctionId,
    String? buyerId,
    String? sellerId,
    String? issue,
    double? disputeAmount,
    DisputeStatus? status,
    String? resolution,
    String? csrNotes,
    DateTime? resolvedAt,
  }) {
    return DisputeTicket(
      id: id,
      ticketId: ticketId ?? this.ticketId,
      auctionId: auctionId ?? this.auctionId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      issue: issue ?? this.issue,
      disputeAmount: disputeAmount ?? this.disputeAmount,
      status: status ?? this.status,
      resolution: resolution ?? this.resolution,
      csrNotes: csrNotes ?? this.csrNotes,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
  
  /// Get user-friendly status text
  String get statusText {
    switch (status) {
      case DisputeStatus.opened: return 'Opened';
      case DisputeStatus.reviewing: return 'Under Review';
      case DisputeStatus.awaitingBuyerInput: return 'Awaiting Buyer';
      case DisputeStatus.awaitingSellerInput: return 'Awaiting Seller';
      case DisputeStatus.resolved: return 'Resolved';
      case DisputeStatus.closed: return 'Closed';
    }
  }
}

/// Status options for a dispute
enum DisputeStatus {
  opened,              // New dispute
  reviewing,           // CSR is reviewing
  awaitingBuyerInput,  // Waiting for buyer response
  awaitingSellerInput, // Waiting for seller response
  resolved,            // Dispute has been resolved
  closed               // Dispute is closed
}

/// Model for content moderation
class ContentReport {
  final String id;
  final String reporterId;
  final String contentId; // Can be auction ID, review ID, etc.
  final ContentType contentType;
  final String reason;
  final List<String>? evidenceUrls;
  final ContentReportStatus status;
  final String? moderatorId;
  final String? moderatorNotes;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  
  ContentReport({
    String? id,
    required this.reporterId,
    required this.contentId,
    required this.contentType,
    required this.reason,
    this.evidenceUrls,
    this.status = ContentReportStatus.pending,
    this.moderatorId,
    this.moderatorNotes,
    DateTime? createdAt,
    this.reviewedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'content_id': contentId,
      'content_type': contentType.toString().split('.').last,
      'reason': reason,
      'evidence_urls': evidenceUrls,
      'status': status.toString().split('.').last,
      'moderator_id': moderatorId,
      'moderator_notes': moderatorNotes,
      'created_at': createdAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
    };
  }
  
  factory ContentReport.fromMap(Map<String, dynamic> map) {
    return ContentReport(
      id: map['id'],
      reporterId: map['reporter_id'],
      contentId: map['content_id'],
      contentType: _stringToContentType(map['content_type']),
      reason: map['reason'],
      evidenceUrls: map['evidence_urls'] != null 
          ? List<String>.from(map['evidence_urls'])
          : null,
      status: _stringToContentReportStatus(map['status']),
      moderatorId: map['moderator_id'],
      moderatorNotes: map['moderator_notes'],
      createdAt: DateTime.parse(map['created_at']),
      reviewedAt: map['reviewed_at'] != null 
          ? DateTime.parse(map['reviewed_at'])
          : null,
    );
  }
  
  static ContentType _stringToContentType(String type) {
    switch (type) {
      case 'auction': return ContentType.auction;
      case 'review': return ContentType.review;
      case 'user': return ContentType.user;
      case 'message': return ContentType.message;
      default: return ContentType.auction;
    }
  }
  
  static ContentReportStatus _stringToContentReportStatus(String status) {
    switch (status) {
      case 'pending': return ContentReportStatus.pending;
      case 'approved': return ContentReportStatus.approved;
      case 'rejected': return ContentReportStatus.rejected;
      default: return ContentReportStatus.pending;
    }
  }
  
  /// Create a copy with updated fields
  ContentReport copyWith({
    String? reporterId,
    String? contentId,
    ContentType? contentType,
    String? reason,
    List<String>? evidenceUrls,
    ContentReportStatus? status,
    String? moderatorId,
    String? moderatorNotes,
    DateTime? reviewedAt,
  }) {
    return ContentReport(
      id: id,
      reporterId: reporterId ?? this.reporterId,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      reason: reason ?? this.reason,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      status: status ?? this.status,
      moderatorId: moderatorId ?? this.moderatorId,
      moderatorNotes: moderatorNotes ?? this.moderatorNotes,
      createdAt: createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
  
  /// Get user-friendly content type text
  String get contentTypeText {
    switch (contentType) {
      case ContentType.auction: return 'Auction';
      case ContentType.review: return 'Review';
      case ContentType.user: return 'User';
      case ContentType.message: return 'Message';
    }
  }
  
  /// Get user-friendly status text
  String get statusText {
    switch (status) {
      case ContentReportStatus.pending: return 'Pending';
      case ContentReportStatus.approved: return 'Approved';
      case ContentReportStatus.rejected: return 'Rejected';
    }
  }
}

/// Types of content that can be reported
enum ContentType {
  auction,  // Plant auction listing
  review,   // User review
  user,     // User profile
  message   // Message content
}

/// Status of a content report
enum ContentReportStatus {
  pending,  // Awaiting moderation
  approved, // Report approved, content removed
  rejected  // Report rejected, content stays
}