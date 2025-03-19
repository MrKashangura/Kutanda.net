// lib/features/auctions/widgets/bid_history_widget.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/helpers.dart';

class BidHistoryWidget extends StatefulWidget {
  final String auctionId;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  const BidHistoryWidget({
    Key? key,
    required this.auctionId,
    this.isExpanded = false,
    this.onToggleExpanded,
  }) : super(key: key);

  @override
  State<BidHistoryWidget> createState() => _BidHistoryWidgetState();
}

class _BidHistoryWidgetState extends State<BidHistoryWidget> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _bids = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser?.id;
    _loadBidHistory();
  }

  Future<void> _loadBidHistory() async {
    setState(() => _isLoading = true);
    
    try {
      // Get bids with bidder profile information
      final response = await _supabase
          .from('bids')
          .select('*, bidder:profiles!bidder_id(display_name, email)')
          .eq('auction_id', widget.auctionId)
          .order('created_at', ascending: false);
      
      setState(() {
        _bids = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bid history: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isExpanded) {
      return _buildCollapsedView();
    }
    
    return _buildExpandedView();
  }

  Widget _buildCollapsedView() {
    final bidCount = _bids.length;
    
    return GestureDetector(
      onTap: widget.onToggleExpanded,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Bid History ($bidCount)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Icon(Icons.expand_more),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedView() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: widget.onToggleExpanded,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Bid History (${_bids.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Icon(Icons.expand_less),
                ],
              ),
            ),
          ),
          
          // Bid list
          _isLoading
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ))
              : _bids.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No bids yet')),
                    )
                  : Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: _bids.length,
                        separatorBuilder: (_, __) => Divider(color: Colors.grey[300]),
                        itemBuilder: (context, index) {
                          final bid = _bids[index];
                          final bidder = bid['bidder'] as Map<String, dynamic>?;
                          final bidAmount = (bid['amount'] as num).toDouble();
                          final bidTime = DateTime.parse(bid['created_at']);
                          final isAutoBid = bid['is_auto_bid'] ?? false;
                          final isCurrentUserBid = bid['bidder_id'] == _currentUserId;
                          
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: isCurrentUserBid 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.grey[300],
                              radius: 16,
                              child: Text(
                                (bidder?['display_name'] as String?)?.isNotEmpty == true
                                    ? (bidder!['display_name'] as String)[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  color: isCurrentUserBid ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(
                              bidder?['display_name'] ?? bidder?['email'] ?? 'Anonymous',
                              style: TextStyle(
                                fontWeight: isCurrentUserBid ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              formatRelativeTime(bidTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  formatCurrency(bidAmount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentUserBid 
                                        ? Theme.of(context).primaryColor 
                                        : Colors.black,
                                  ),
                                ),
                                if (isAutoBid) ...[
                                  const SizedBox(width: 4),
                                  Tooltip(
                                    message: 'Auto Bid',
                                    child: Icon(
                                      Icons.auto_awesome,
                                      size: 16,
                                      color: Colors.amber[700],
                                    ),
                                  ),
                                ],
                                if (index == 0) ...[
                                  const SizedBox(width: 4),
                                  const Tooltip(
                                    message: 'Highest Bid',
                                    child: Icon(
                                      Icons.emoji_events,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          
          // Footer
          if (!_isLoading && _bids.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _loadBidHistory,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}