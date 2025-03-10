// lib/features/support/screens/admin_system_config_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/app_config.dart';
import '../widgets/admin_drawer.dart';

class AdminSystemConfigScreen extends StatefulWidget {
  const AdminSystemConfigScreen({super.key});

  @override
  State<AdminSystemConfigScreen> createState() => _AdminSystemConfigScreenState();
}

class _AdminSystemConfigScreenState extends State<AdminSystemConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _hasChanges = false;
  
  // Commission settings
  final _baseFeeController = TextEditingController();
  final _buyerFeePercentController = TextEditingController();
  final _sellerFeePercentController = TextEditingController();
  
  // Content settings
  bool _enableContentModeration = true;
  bool _enableUserReporting = true;
  int _maxImagesPerListing = 5;
  
  // Auction settings
  bool _enableBuyNow = true;
  bool _enableAutoBidding = true;
  int _minimumBidIncrementPercentage = 5;
  int _defaultAuctionDurationDays = 7;
  
  // Notification settings
  bool _enableEmailNotifications = true;
  bool _enablePushNotifications = true;
  bool _enableSMSNotifications = false;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }
  
  @override
  void dispose() {
    _baseFeeController.dispose();
    _buyerFeePercentController.dispose();
    _sellerFeePercentController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCurrentSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Replace with actual settings from Supabase
      // For now, using placeholder values from AppConfig
      
      // Commission settings
      _baseFeeController.text = '1.50'; // Base fee in currency
      _buyerFeePercentController.text = '3.0'; // 3% buyer fee
      _sellerFeePercentController.text = '5.0'; // 5% seller fee
      
      // Content settings
      _enableContentModeration = true;
      _enableUserReporting = true;
      _maxImagesPerListing = AppConfig.maxImagesPerAuction;
      
      // Auction settings
      _enableBuyNow = true;
      _enableAutoBidding = true;
      _minimumBidIncrementPercentage = 5;
      _defaultAuctionDurationDays = AppConfig.maxAuctionDurationDays ~/ 2;
      
      // Notification settings
      _enableEmailNotifications = true;
      _enablePushNotifications = AppConfig.enablePushNotifications;
      _enableSMSNotifications = false;
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }
  
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // TODO: Store settings in Supabase
      
      // Simulate a network delay
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }
  
  void _markHasChanges() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("System Configuration"),
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text("Save"),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSettingsForm(),
    );
  }

  Widget _buildSettingsForm() {
    return Form(
      key: _formKey,
      onChanged: () => _markHasChanges(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Commission Settings Section
            _buildSectionHeader('Commission Settings'),
            _buildTextField(
              controller: _baseFeeController,
              label: 'Base Fee (\$)',
              hint: 'Fixed fee added to each transaction',
              prefixIcon: Icons.attach_money,
              validator: _validateCurrency,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            _buildTextField(
              controller: _buyerFeePercentController,
              label: 'Buyer Fee (%)',
              hint: 'Percentage fee charged to buyers',
              prefixIcon: Icons.person,
              validator: _validatePercentage,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            _buildTextField(
              controller: _sellerFeePercentController,
              label: 'Seller Fee (%)',
              hint: 'Percentage fee charged to sellers',
              prefixIcon: Icons.store,
              validator: _validatePercentage,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            
            const SizedBox(height: 24),
            
            // Content Settings Section
            _buildSectionHeader('Content Settings'),
            _buildSwitchTile(
              title: 'Enable Content Moderation',
              subtitle: 'Require approval for listings and content',
              value: _enableContentModeration,
              onChanged: (value) {
                setState(() {
                  _enableContentModeration = value;
                  _markHasChanges();
                });
              },
            ),
            _buildSwitchTile(
              title: 'Enable User Reporting',
              subtitle: 'Allow users to report inappropriate content',
              value: _enableUserReporting,
              onChanged: (value) {
                setState(() {
                  _enableUserReporting = value;
                  _markHasChanges();
                });
              },
            ),
            _buildSliderTile(
              title: 'Max Images Per Listing',
              subtitle: 'Maximum number of images allowed per auction listing',
              value: _maxImagesPerListing.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_maxImagesPerListing',
              onChanged: (value) {
                setState(() {
                  _maxImagesPerListing = value.round();
                  _markHasChanges();
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Auction Settings Section
            _buildSectionHeader('Auction Settings'),
            _buildSwitchTile(
              title: 'Enable Buy Now',
              subtitle: 'Allow sellers to set a "Buy Now" price',
              value: _enableBuyNow,
              onChanged: (value) {
                setState(() {
                  _enableBuyNow = value;
                  _markHasChanges();
                });
              },
            ),
            _buildSwitchTile(
              title: 'Enable Auto-Bidding',
              subtitle: 'Allow buyers to set maximum bids',
              value: _enableAutoBidding,
              onChanged: (value) {
                setState(() {
                  _enableAutoBidding = value;
                  _markHasChanges();
                });
              },
            ),
            _buildSliderTile(
              title: 'Minimum Bid Increment (%)',
              subtitle: 'Minimum percentage increase for new bids',
              value: _minimumBidIncrementPercentage.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_minimumBidIncrementPercentage%',
              onChanged: (value) {
                setState(() {
                  _minimumBidIncrementPercentage = value.round();
                  _markHasChanges();
                });
              },
            ),
            _buildSliderTile(
              title: 'Default Auction Duration (Days)',
              subtitle: 'Default length of auctions in days',
              value: _defaultAuctionDurationDays.toDouble(),
              min: 1,
              max: 14,
              divisions: 13,
              label: '$_defaultAuctionDurationDays ${_defaultAuctionDurationDays == 1 ? 'day' : 'days'}',
              onChanged: (value) {
                setState(() {
                  _defaultAuctionDurationDays = value.round();
                  _markHasChanges();
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Notification Settings Section
            _buildSectionHeader('Notification Settings'),
            _buildSwitchTile(
              title: 'Enable Email Notifications',
              subtitle: 'Send email notifications to users',
              value: _enableEmailNotifications,
              onChanged: (value) {
                setState(() {
                  _enableEmailNotifications = value;
                  _markHasChanges();
                });
              },
            ),
            _buildSwitchTile(
              title: 'Enable Push Notifications',
              subtitle: 'Send push notifications to users\' devices',
              value: _enablePushNotifications,
              onChanged: (value) {
                setState(() {
                  _enablePushNotifications = value;
                  _markHasChanges();
                });
              },
            ),
            _buildSwitchTile(
              title: 'Enable SMS Notifications',
              subtitle: 'Send SMS notifications to users\' phones',
              value: _enableSMSNotifications,
              onChanged: (value) {
                setState(() {
                  _enableSMSNotifications = value;
                  _markHasChanges();
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Maintenance Mode Section
            _buildSectionHeader('Maintenance & Backup'),
            _buildActionButton(
              icon: Icons.cloud_upload,
              label: 'Backup Database',
              onPressed: () {
                // TODO: Implement database backup
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Database backup initiated')),
                );
              },
            ),
            _buildActionButton(
              icon: Icons.build,
              label: 'Enter Maintenance Mode',
              onPressed: () {
                // TODO: Implement maintenance mode
                _showMaintenanceModeDialog();
              },
            ),
            
            const SizedBox(height: 32),
            
            // Save button at bottom
            if (_hasChanges)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Save All Settings'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(prefixIcon),
          border: const OutlineInputBorder(),
        ),
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onChanged: (_) => _markHasChanges(),
      ),
    );
  }
  
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        secondary: Icon(
          value ? Icons.check_circle : Icons.circle_outlined,
          color: value ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
  
  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(title),
            subtitle: Text(subtitle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(min.round().toString()),
                Expanded(
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions,
                    label: label,
                    onChanged: onChanged,
                  ),
                ),
                Text(max.round().toString()),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          alignment: Alignment.centerLeft,
          minimumSize: const Size(double.infinity, 0),
        ),
      ),
    );
  }
  
  void _showMaintenanceModeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final durationController = TextEditingController(text: '30');
        final messageController = TextEditingController(
          text: 'The system is currently undergoing scheduled maintenance. Please check back soon.',
        );
        
        return AlertDialog(
          title: const Text('Enter Maintenance Mode'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Warning: This will make the platform inaccessible to all users except administrators.',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Maintenance Message',
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
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement maintenance mode activation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Maintenance mode activated for ${durationController.text} minutes',
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('ACTIVATE'),
            ),
          ],
        );
      },
    );
  }
  
  String? _validateCurrency(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    
    if (double.parse(value) < 0) {
      return 'Value cannot be negative';
    }
    
    return null;
  }
  
  String? _validatePercentage(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    
    final percentage = double.parse(value);
    if (percentage < 0) {
      return 'Percentage cannot be negative';
    }
    
    if (percentage > 100) {
      return 'Percentage cannot exceed 100%';
    }
    
    return null;
  }
}