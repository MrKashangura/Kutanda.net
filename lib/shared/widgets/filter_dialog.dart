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
  
  // Plant categories
  final List<String> _categories = [
    'Flowers',
    'Trees',
    'Succulents',
    'Herbs',
    'Indoor Plants',
    'Outdoor Plants',
    'Rare Species',
    'Seeds',
    'Seedlings',
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
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price Range Slider
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
                onChanged: (RangeValues values) {
                  setState(() {
                    _priceRange = values;
                  });
                },
              ),
              Text(
                'Price: \$${_priceRange.start.round()} - \$${_priceRange.end.round()}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 16),
              
              // Show Active Auctions Only
              CheckboxListTile(
                title: const Text('Show active items only'),
                value: _activeOnly,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (bool? value) {
                  setState(() {
                    _activeOnly = value ?? true;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Sort By Options
              const Text(
                'Sort By',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildSortOption('newest', 'Newest'),
              _buildSortOption('endingSoon', 'Ending Soon'),
              _buildSortOption('priceAsc', 'Price: Low to High'),
              _buildSortOption('priceDesc', 'Price: High to Low'),
              const SizedBox(height: 16),
              
              // Category Filter
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final isSelected = _categoryFilter == category;
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _categoryFilter = selected ? category : null;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
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
        OutlinedButton(
          onPressed: () {
            setState(() {
              _priceRange = const RangeValues(0, 1000);
              _activeOnly = true;
              _sortBy = 'newest';
              _categoryFilter = null;
            });
          },
          child: const Text('Reset'),
        ),
      ],
    );
  }

  Widget _buildSortOption(String value, String label) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _sortBy,
      contentPadding: EdgeInsets.zero,
      dense: true,
      onChanged: (String? newValue) {
        setState(() {
          _sortBy = newValue!;
        });
      },
    );
  }
}