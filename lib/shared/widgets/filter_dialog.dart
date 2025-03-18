// lib/shared/widgets/filter_dialog.dart
import 'package:flutter/material.dart';

class FilterDialog extends StatefulWidget {
  final RangeValues currentPriceRange;
  final bool activeOnly;
  final String sortBy;
  final String? categoryFilter;
  
  const FilterDialog({
    super.key,
    required this.currentPriceRange,
    required this.activeOnly,
    required this.sortBy,
    this.categoryFilter,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late RangeValues _priceRange;
  late bool _activeOnly;
  late String _sortBy;
  String? _categoryFilter;
  
  // Sample categories - in a real app these would come from the API
  final List<String> _categories = [
    'All',
    'Succulents',
    'Flowering Plants',
    'Fruit Trees',
    'Indoor Plants',
    'Outdoor Plants',
    'Rare Plants',
    'Herbs',
    'Cacti',
  ];

  @override
  void initState() {
    super.initState();
    _priceRange = widget.currentPriceRange;
    _activeOnly = widget.activeOnly;
    _sortBy = widget.sortBy;
    _categoryFilter = widget.categoryFilter;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Options'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Price Range
            const Text(
              'Price Range',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 1000,
              divisions: 20,
              labels: RangeLabels(
                '\$${_priceRange.start.round()}',
                '\$${_priceRange.end.round()}',
              ),
              onChanged: (values) {
                setState(() => _priceRange = values);
              },
            ),
            Text(
              'Price: \$${_priceRange.start.round()} - \$${_priceRange.end.round()}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            
            const SizedBox(height: 16),
            
            // Active Auctions Only
            SwitchListTile(
              title: const Text('Active Auctions Only'),
              subtitle: const Text('Hide ended auctions'),
              value: _activeOnly,
              onChanged: (value) {
                setState(() => _activeOnly = value);
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            const Divider(),
            
            // Sort Options
            const Text(
              'Sort By',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildSortOption('newest', 'Newest'),
            _buildSortOption('endingSoon', 'Ending Soon'),
            _buildSortOption('priceAsc', 'Price: Low to High'),
            _buildSortOption('priceDesc', 'Price: High to Low'),
            
            const Divider(),
            
            // Categories
            const Text(
              'Categories',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = category == 'All' 
                    ? _categoryFilter == null
                    : _categoryFilter == category;
                
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _categoryFilter = selected 
                          ? (category == 'All' ? null : category)
                          : null;
                    });
                  },
                );
              }).toList(),
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
            Navigator.pop(context, {
              'priceRange': _priceRange,
              'activeOnly': _activeOnly,
              'sortBy': _sortBy,
              'categoryFilter': _categoryFilter,
            });
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
  
  Widget _buildSortOption(String value, String label) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _sortBy,
      onChanged: (value) {
        if (value != null) {
          setState(() => _sortBy = value);
        }
      },
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}