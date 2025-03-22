// lib/shared/widgets/item_carousel.dart
import 'package:flutter/material.dart';

class ItemCarousel<T> extends StatelessWidget {
  final List<T> items;
  final String title;
  final Widget Function(T item) itemBuilder;
  final void Function(T item)? onItemTap;
  final VoidCallback? onSeeAllTap;
  
  const ItemCarousel({
    super.key,
    required this.items,
    required this.title,
    required this.itemBuilder,
    this.onItemTap,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (items.length > 5)
                TextButton(
                  onPressed: onSeeAllTap,
                  child: const Text('See All'),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 240, // Fixed height for carousel
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[400], size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'No items available',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: SizedBox(
                        width: 180, // Fixed width for each item
                        child: GestureDetector(
                          onTap: onItemTap != null ? () => onItemTap!(item) : null,
                          child: itemBuilder(item),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}