// lib/features/auctions/widgets/cart_item_widget.dart
import 'package:flutter/material.dart';

import '../../../core/utils/helpers.dart';
import '../../../data/models/fixed_price_listing_model.dart';

class CartItemWidget extends StatefulWidget {
  final FixedPriceListing listing;
  final int quantity;
  final Function(FixedPriceListing, int) onQuantityChanged;
  final Function(FixedPriceListing) onRemove;

  const CartItemWidget({
    Key? key,
    required this.listing,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.quantity;
  }

  @override
  void didUpdateWidget(CartItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) {
      _quantity = widget.quantity;
    }
  }

  void _updateQuantity(int delta) {
    final newQuantity = _quantity + delta;
    if (newQuantity <= 0) {
      // Show removal confirmation
      _showRemoveDialog();
      return;
    }
    
    if (newQuantity > widget.listing.quantityAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only ${widget.listing.quantityAvailable} available')),
      );
      return;
    }
    
    setState(() => _quantity = newQuantity);
    widget.onQuantityChanged(widget.listing, newQuantity);
  }

  void _showRemoveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: const Text('Are you sure you want to remove this item from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onRemove(widget.listing);
            },
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.listing.price * _quantity;
    
    return Dismissible(
      key: Key('cart_${widget.listing.id}'),
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.red,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove Item'),
            content: const Text('Are you sure you want to remove this item from your cart?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('REMOVE'),
              ),
            ],
          ),
        );
        return result ?? false;
      },
      onDismissed: (direction) {
        widget.onRemove(widget.listing);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Item info row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: widget.listing.imageUrls.isNotEmpty
                          ? Image.network(
                              widget.listing.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Item details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.listing.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatCurrency(widget.listing.price),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.listing.quantityAvailable} available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Remove button
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _showRemoveDialog(),
                    tooltip: 'Remove',
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              // Quantity and subtotal row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Quantity selector
                  Row(
                    children: [
                      const Text(
                        'Qty: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _updateQuantity(-1),
                        iconSize: 20,
                        splashRadius: 20,
                      ),
                      Text(
                        _quantity.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _updateQuantity(1),
                        iconSize: 20,
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  
                  // Subtotal
                  Text(
                    'Subtotal: ${formatCurrency(subtotal)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}