// lib/features/auctions/widgets/auto_bid_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/helpers.dart';
import '../../../data/repositories/bid_repository.dart';

class AutoBidWidget extends StatefulWidget {
  final String auctionId;
  final double currentBid;
  final double bidIncrement;
  final Function(bool success) onAutoBidSet;

  const AutoBidWidget({
    super.key,
    required this.auctionId,
    required this.currentBid,
    required this.bidIncrement,
    required this.onAutoBidSet,
  });

  @override
  State<AutoBidWidget> createState() => _AutoBidWidgetState();
}

class _AutoBidWidgetState extends State<AutoBidWidget> {
  final TextEditingController _maxBidController = TextEditingController();
  final TextEditingController _incrementController = TextEditingController();
  final BidRepository _bidRepository = BidRepository();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  bool _hasExistingAutoBid = false;
  double? _existingMaxAmount;
  double? _existingIncrement;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _incrementController.text = widget.bidIncrement.toStringAsFixed(2);
    _checkExistingAutoBid();
  }

  @override
  void dispose() {
    _maxBidController.dispose();
    _incrementController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingAutoBid() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final autoBid = await _supabase
          .from('auto_bids')
          .select()
          .eq('auction_id', widget.auctionId)
          .eq('bidder_id', user.id)
          .maybeSingle();
      
      if (autoBid != null) {
        setState(() {
          _hasExistingAutoBid = true;
          _existingMaxAmount = (autoBid['max_amount'] as num).toDouble();
          _existingIncrement = (autoBid['increment'] as num).toDouble();
          _isActive = autoBid['is_active'] ?? false;
          
          _maxBidController.text = _existingMaxAmount!.toStringAsFixed(2);
          _incrementController.text = _existingIncrement!.toStringAsFixed(2);
        });
      } else {
        setState(() {
          _maxBidController.text = (widget.currentBid + widget.bidIncrement * 3).toStringAsFixed(2);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking auto-bids: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setAutoBid() async {
    if (_maxBidController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a maximum bid amount')),
      );
      return;
    }
    
    final maxAmount = double.tryParse(_maxBidController.text);
    if (maxAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid maximum bid amount')),
      );
      return;
    }
    
    if (maxAmount <= widget.currentBid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum bid must be greater than ${formatCurrency(widget.currentBid)}')),
      );
      return;
    }
    
    final increment = double.tryParse(_incrementController.text) ?? widget.bidIncrement;
    if (increment <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bid increment must be greater than zero')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');
      
      final success = await _bidRepository.createAutoBid(
        widget.auctionId,
        user.id,
        maxAmount,
        increment,
      );
      
      widget.onAutoBidSet(success);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Auto-bid set successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          setState(() {
            _hasExistingAutoBid = true;
            _existingMaxAmount = maxAmount;
            _existingIncrement = increment;
            _isActive = true;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to set auto-bid'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting auto-bid: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelAutoBid() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');
      
      final success = await _bidRepository.cancelAutoBid(
        widget.auctionId,
        user.id,
      );
      
      widget.onAutoBidSet(!success);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Auto-bid cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
          
          setState(() {
            _isActive = false;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel auto-bid'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling auto-bid: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Auto Bidding',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_hasExistingAutoBid)
                  Switch(
                    value: _isActive,
                    onChanged: (value) {
                      if (value) {
                        _setAutoBid();
                      } else {
                        _cancelAutoBid();
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Set a maximum bid amount and let the system automatically bid for you up to that limit.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _maxBidController,
              decoration: InputDecoration(
                labelText: 'Maximum Bid Amount',
                hintText: 'Enter the maximum amount you\'re willing to bid',
                border: const OutlineInputBorder(),
                prefixText: '\$ ',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('This is the maximum amount you\'re willing to spend on this item')),
                    );
                  },
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _incrementController,
              decoration: InputDecoration(
                labelText: 'Bid Increment',
                hintText: 'Amount to increase each bid by',
                border: const OutlineInputBorder(),
                prefixText: '\$ ',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('This is how much your bid will increase each time someone outbids you')),
                    );
                  },
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),
            
            if (_hasExistingAutoBid && _isActive)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Auto-bidding is active',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'Maximum bid: ${formatCurrency(_existingMaxAmount!)} with ${formatCurrency(_existingIncrement!)} increments',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (_hasExistingAutoBid && !_isActive)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pause_circle_filled, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text(
                      'Auto-bidding is paused',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : _hasExistingAutoBid && _isActive
                        ? _cancelAutoBid
                        : _setAutoBid,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _hasExistingAutoBid && _isActive
                      ? Colors.red
                      : Theme.of(context).primaryColor,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _hasExistingAutoBid && _isActive
                            ? 'Cancel Auto-Bid'
                            : _hasExistingAutoBid && !_isActive
                                ? 'Resume Auto-Bid'
                                : 'Set Auto-Bid',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}