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
  late String? _categoryFilter;
  final List<String> _availableCategories = [
    'Flowers',
    'Trees',
    'Succulents',
    'Herbs',
    'Indoor',
    'Outdoor',
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(),
            
            // Active only filter
            SwitchListTile(
              title: const Text('Show active listings only'),
              value: _activeOnly,
              onChanged: (value) {
                setState(() {
                  _activeOnly = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 16),
            
            // Price range
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
                '\$${_priceRange.end.round()}'
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _priceRange = values;
                });
              },
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${_priceRange.start.round()}'),
                Text('\$${_priceRange.end.round()}'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Sort options
            const Text(
              'Sort By',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            
            RadioListTile<String>(
              title: const Text('Newest'),
              value: 'newest',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            
            RadioListTile<String>(
              title: const Text('Ending Soon'),
              value: 'ending_soon',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            
            RadioListTile<String>(
              title: const Text('Price: Low to High'),
              value: 'price_low',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            
            RadioListTile<String>(
              title: const Text('Price: High to Low'),
              value: 'price_high',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            
            const SizedBox(height: 16),
            
            // Category filter
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            
            Container(
              height: 120,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: _availableCategories.map((category) {
                  return CheckboxListTile(
                    title: Text(category),
                    value: _categoryFilter == category,
                    onChanged: (value) {
                      setState(() {
                        _categoryFilter = value! ? category : null;
                      });
                    },
                    dense: true,
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _priceRange = const RangeValues(0, 1000);
                      _activeOnly = true;
                      _sortBy = 'newest';
                      _categoryFilter = null;
                    });
                  },
                  child: const Text('Reset All'),
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
                  child: const Text('Apply Filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}