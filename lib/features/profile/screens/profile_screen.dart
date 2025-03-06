import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/helpers.dart';
import '../../../shared/services/role_service.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final RoleService _roleService = RoleService();
  final _formKey = GlobalKey<FormState>();
  
  // Text editing controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  // State variables
  bool _isLoading = false;
  bool _isEditing = false;
  File? _profileImage;
  Map<String, dynamic>? _userData;
  String _activeRole = 'buyer';
  Map<String, dynamic> _roleStatus = {
    'buyer': true,
    'seller': false,
    'seller_status': 'unknown'
  };
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRoleStatus();
  }
  
  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        // Navigate to login screen if no user
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }
      
      // Get user data from profiles table
      final userData = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
          
      if (userData != null) {
        // Get active role from secure storage
        final activeRole = await _roleService.getActiveRole();
        
        if (!mounted) return;
        setState(() {
          _userData = userData;
          _activeRole = activeRole ?? 'buyer';
          
          // Initialize controllers with existing data
          _nameController.text = userData['full_name'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _bioController.text = userData['bio'] ?? '';
        });
      } else {
        // Create profile if it doesn't exist
        await _createUserProfile(user);
      }
    } catch (e) {
      log('Error loading user data: $e');
      if (mounted) {
        showSnackBar(context, 'Error loading profile data');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _createUserProfile(User user) async {
    try {
      final email = user.email;
      
      // Insert new profile record
      await _supabase.from('profiles').insert({
        'id': user.id,
        'email': email,
        'full_name': email?.split('@').first,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Reload data after creating profile
      await _loadUserData();
    } catch (e) {
      log('Error creating user profile: $e');
      if (mounted) {
        showSnackBar(context, 'Error creating profile');
      }
    }
  }
  
  Future<void> _loadRoleStatus() async {
    try {
      final roles = await _roleService.getUserRoles();
      if (mounted) {
        setState(() => _roleStatus = roles);
      }
    } catch (e) {
      log('Error loading role status: $e');
    }
  }
  
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() => _profileImage = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error selecting image: $e');
      }
    }
  }
  
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      String? profileImageUrl;
      
      // Upload profile image if selected
      if (_profileImage != null) {
        final fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage.from('profiles').upload(fileName, _profileImage!);
        profileImageUrl = _supabase.storage.from('profiles').getPublicUrl(fileName);
      }
      
      // Update profile data
      await _supabase.from('profiles').update({
        'full_name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'bio': _bioController.text,
        'updated_at': DateTime.now().toIso8601String(),
        if (profileImageUrl != null) 'avatar_url': profileImageUrl,
      }).eq('id', user.id);
      
      if (!mounted) return;
      
      // Reload data and exit edit mode
      await _loadUserData();
      setState(() => _isEditing = false);
      
      showSnackBar(context, 'Profile updated successfully');
    } catch (e) {
      log('Error updating profile: $e');
      if (mounted) {
        showSnackBar(context, 'Error updating profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _signOut() async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmText: 'Sign Out',
      cancelText: 'Cancel',
      confirmColor: Colors.red,
    );
    
    if (confirmed) {
      setState(() => _isLoading = true);
      
      try {
        await _supabase.auth.signOut();
        if (!mounted) return;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } catch (e) {
        log('Error signing out: $e');
        if (mounted) {
          showSnackBar(context, 'Error signing out');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
  
  Widget _buildRoleStatusBadge() {
    if (_activeRole == 'seller') {
      final status = _roleStatus['seller_status'];
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: getKycStatusColor(status).withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: getKycStatusColor(status)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(getKycStatusIcon(status), size: 16, color: getKycStatusColor(status)),
            const SizedBox(width: 4),
            Text(
              status == 'verified' ? 'Verified Seller' :
              status == 'pending' ? 'Verification Pending' :
              status == 'rejected' ? 'Verification Rejected' : 'Seller',
              style: TextStyle(color: getKycStatusColor(status), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, size: 16, color: Colors.blue),
            SizedBox(width: 4),
            Text(
              'Buyer',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
  }
  
  Widget _buildProfileView() {
    final avatarUrl = _userData?['avatar_url'];
    final name = _userData?['full_name'] ?? 'User';
    final email = _userData?['email'] ?? '';
    final phone = _userData?['phone'] ?? 'Not provided';
    final address = _userData?['address'] ?? 'Not provided';
    final bio = _userData?['bio'] ?? 'No bio provided';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        
        // Profile image
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? const Icon(Icons.person, size: 80, color: Colors.grey)
                  : null,
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.green,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                onPressed: () => setState(() => _isEditing = true),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // User name
        Text(
          name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        
        const SizedBox(height: 8),
        
        // Role badge
        _buildRoleStatusBadge(),
        
        const SizedBox(height: 16),
        
        // User details
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(email),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone),
                  title: const Text('Phone'),
                  subtitle: Text(phone),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on),
                  title: const Text('Address'),
                  subtitle: Text(address),
                ),
              ],
            ),
          ),
        ),
        
        // Bio
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About Me',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                Text(bio),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Sign out button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        
        const SizedBox(height: 32),
      ],
    );
  }
  
  Widget _buildProfileEdit() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            
            // Profile image
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : _userData?['avatar_url'] != null && _userData!['avatar_url'].isNotEmpty
                          ? NetworkImage(_userData!['avatar_url'])
                          : null,
                  child: _profileImage == null && (_userData?['avatar_url'] == null || _userData!['avatar_url'].isEmpty)
                      ? const Icon(Icons.person, size: 80, color: Colors.grey)
                      : null,
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.photo_camera, size: 16, color: Colors.white),
                    onPressed: _pickImage,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Form fields
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: _isEditing ? _buildProfileEdit() : _buildProfileView(),
            ),
      bottomNavigationBar: BottomNavigation(
        currentDestination: NavDestination.profile,
        onDestinationSelected: (destination) {
          handleNavigation(context, destination, _activeRole == 'seller');
        },
        isSellerMode: _activeRole == 'seller',
      ),
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}