// lib/features/payment/widgets/delivery_address_form.dart
import 'package:flutter/material.dart';

class DeliveryAddressForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Map<String, dynamic> initialAddress;
  final Function(Map<String, dynamic>) onAddressChanged;

  const DeliveryAddressForm({
    super.key,
    required this.formKey,
    required this.initialAddress,
    required this.onAddressChanged,
  });

  @override
  State<DeliveryAddressForm> createState() => _DeliveryAddressFormState();
}

class _DeliveryAddressFormState extends State<DeliveryAddressForm> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  
  final _addressData = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }
  
  @override
  void didUpdateWidget(DeliveryAddressForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAddress != widget.initialAddress) {
      _initializeForm();
    }
  }
  
  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    // Set initial values if available
    _fullNameController.text = widget.initialAddress['full_name'] ?? '';
    _phoneController.text = widget.initialAddress['phone'] ?? '';
    _addressLine1Controller.text = widget.initialAddress['address_line1'] ?? '';
    _addressLine2Controller.text = widget.initialAddress['address_line2'] ?? '';
    _cityController.text = widget.initialAddress['city'] ?? '';
    _stateController.text = widget.initialAddress['state'] ?? '';
    _zipCodeController.text = widget.initialAddress['zip_code'] ?? '';
    _countryController.text = widget.initialAddress['country'] ?? '';
  }

  void _updateAddressData() {
    _addressData['full_name'] = _fullNameController.text;
    _addressData['phone'] = _phoneController.text;
    _addressData['address_line1'] = _addressLine1Controller.text;
    _addressData['address_line2'] = _addressLine2Controller.text;
    _addressData['city'] = _cityController.text;
    _addressData['state'] = _stateController.text;
    _addressData['zip_code'] = _zipCodeController.text;
    _addressData['country'] = _countryController.text;
    
    widget.onAddressChanged(_addressData);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      onChanged: _updateAddressData,
      child: Column(
        children: [
          // Full Name
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
            onSaved: (value) {
              _addressData['full_name'] = value;
            },
          ),
          const SizedBox(height: 16),
          
          // Phone Number
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
            onSaved: (value) {
              _addressData['phone'] = value;
            },
          ),
          const SizedBox(height: 16),
          
          // Address Line 1
          TextFormField(
            controller: _addressLine1Controller,
            decoration: const InputDecoration(
              labelText: 'Address Line 1',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
            onSaved: (value) {
              _addressData['address_line1'] = value;
            },
          ),
          const SizedBox(height: 16),
          
          // Address Line 2 (Optional)
          TextFormField(
            controller: _addressLine2Controller,
            decoration: const InputDecoration(
              labelText: 'Address Line 2 (Optional)',
              border: OutlineInputBorder(),
            ),
            onSaved: (value) {
              _addressData['address_line2'] = value;
            },
          ),
          const SizedBox(height: 16),
          
          // City and State
          Row(
            children: [
              // City
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your city';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _addressData['city'] = value;
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // State/Province
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State/Province',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your state';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _addressData['state'] = value;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Zip Code and Country
          Row(
            children: [
              // Zip/Postal Code
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _zipCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Zip/Postal Code',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your zip code';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _addressData['zip_code'] = value;
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // Country
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your country';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _addressData['country'] = value;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}