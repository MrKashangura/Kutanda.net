// lib/screens/kyc_submission_screen.dart - Fixed issues
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/services/role_service.dart';

class KycSubmissionScreen extends StatefulWidget {
  const KycSubmissionScreen({super.key});

  @override
  KycSubmissionScreenState createState() => KycSubmissionScreenState();
}

class KycSubmissionScreenState extends State<KycSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _registrationNumberController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  final RoleService _roleService = RoleService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  String _kycStatus = 'unknown';
  bool _isActive = false;
  
  // Fixed: Made these final since they're just collections
  final List<File> _selectedDocuments = [];
  final List<String> _documentNames = [];

  @override
  void initState() {
    super.initState();
    _checkExistingKycStatus();
  }
  
  Future<void> _checkExistingKycStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final kycData = await _roleService.checkKycStatus();
      setState(() {
        _kycStatus = kycData['status'];
        _isActive = kycData['is_active'];
      });
      
      // If user already has a pending or verified KYC, load their data
      if (_kycStatus == 'pending' || _kycStatus == 'verified') {
        _loadExistingSellerData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking KYC status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _loadExistingSellerData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      final sellerData = await _supabase
          .from('sellers')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (sellerData != null && mounted) {
        setState(() {
          _businessNameController.text = sellerData['business_name'] ?? '';
          _registrationNumberController.text = sellerData['business_registration_number'] ?? '';
          _taxIdController.text = sellerData['tax_id'] ?? '';
          _addressController.text = sellerData['address'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading seller data: $e')),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() {
          _selectedDocuments.add(File(pickedFile.path));
          _documentNames.add(pickedFile.name);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking document: $e')),
        );
      }
    }
  }
  
  Future<List<String>> _uploadDocuments() async {
    List<String> documentUrls = [];
    
    try {
      for (int i = 0; i < _selectedDocuments.length; i++) {
        final file = _selectedDocuments[i];
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_documentNames[i]}';
        
        await _supabase.storage.from('kyc_documents').upload(fileName, file);
        final publicUrl = _supabase.storage.from('kyc_documents').getPublicUrl(fileName);
        
        documentUrls.add(publicUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading documents: $e')),
        );
      }
    }
    
    return documentUrls;
  }

  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDocuments.isEmpty && _kycStatus == 'unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one document')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      List<String> documentUrls = [];
      
      if (_selectedDocuments.isNotEmpty) {
        documentUrls = await _uploadDocuments();
      }
      
      final sellerData = {
        'business_name': _businessNameController.text,
        'business_registration_number': _registrationNumberController.text,
        'tax_id': _taxIdController.text,
        'address': _addressController.text,
      };
      
      final success = await _roleService.requestSellerRole(sellerData, documentUrls);
      
      if (!mounted) return;
      
      if (success) {
        setState(() {
          _kycStatus = 'pending';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC documents submitted successfully. Awaiting verification.')),
        );
        
        // Navigate back to previous screen
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit KYC documents. Please try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting KYC: $e')),
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // If KYC is already verified, show success screen
    if (_kycStatus == 'verified' && _isActive) {
      return Scaffold(
        appBar: AppBar(title: const Text("Seller Verification")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text(
                "Your seller account is verified!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "You can now list plants for auction.",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Return to Dashboard"),
              ),
            ],
          ),
        ),
      );
    }
    
    // If KYC is pending verification, show pending screen
    if (_kycStatus == 'pending') {
      return Scaffold(
        appBar: AppBar(title: const Text("Seller Verification")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top, color: Colors.orange, size: 80),
              const SizedBox(height: 20),
              const Text(
                "Verification Pending",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your KYC documents are being reviewed.\nThis process usually takes 1-2 business days.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Return to Dashboard"),
              ),
            ],
          ),
        ),
      );
    }
    
    // Show KYC submission form
    return Scaffold(
      appBar: AppBar(title: const Text("Seller Verification")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Complete Seller Verification",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "To list plants for auction, we need to verify your information. This helps maintain trust in our marketplace.",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              
              // Business Information
              const Text(
                "Business Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: "Business Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Business name is required";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _registrationNumberController,
                decoration: const InputDecoration(
                  labelText: "Business Registration Number",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Registration number is required";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _taxIdController,
                decoration: const InputDecoration(
                  labelText: "Tax ID (Optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Business Address",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Business address is required";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Document Upload
              const Text(
                "Upload Verification Documents",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please upload at least one of the following documents:\n• Business registration certificate\n• Government-issued ID\n• Tax registration document",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              // Document List
              ..._documentNames.asMap().entries.map((entry) {
                int idx = entry.key;
                String name = entry.value;
                return ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedDocuments.removeAt(idx);
                        _documentNames.removeAt(idx);
                      });
                    },
                  ),
                );
              }),
              
              // Upload Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: _pickDocument,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Upload Document"),
                ),
              ),
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitKyc,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit for Verification", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _businessNameController.dispose();
    _registrationNumberController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}