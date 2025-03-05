import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auction_model.dart';
import '../services/auction_service.dart';

class CreateAuctionScreen extends StatefulWidget {
  const CreateAuctionScreen({super.key});

  @override
  CreateAuctionScreenState createState() => CreateAuctionScreenState();
}

class CreateAuctionScreenState extends State<CreateAuctionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController startingPriceController = TextEditingController();
  final TextEditingController bidIncrementController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();

  File? _selectedImage;
  bool _isUploading = false;
  final _auctionService = AuctionService();
  final user = Supabase.instance.client.auth.currentUser;

  /// **Pick an image from the gallery**
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  /// **Upload image to Supabase Storage and return URL**
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage.from('auction_images').upload(fileName, imageFile);
      return Supabase.instance.client.storage.from('auction_images').getPublicUrl(fileName);
    } catch (e) {
      if (!mounted) return null; // ✅ Check if widget is still active
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error uploading image: $e")));
      return null;
    }
  }

  /// **Create Auction**
  Future<void> _createAuction() async {
    if (!_formKey.currentState!.validate()) return;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You must be logged in to create an auction.")));
      return;
    }

    setState(() => _isUploading = true);

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage(_selectedImage!);
    }

final auction = Auction(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  title: titleController.text,
  description: descriptionController.text,
  startingPrice: double.parse(startingPriceController.text),
  bidIncrement: double.parse(bidIncrementController.text), // ✅ Ensure bid increment is included
  highestBid: 0.0,
  highestBidderId: null,
  sellerId: user?.id ?? "unknown", // ✅ Use null-aware operator
  isActive: true,
  imageUrls: imageUrl != null ? [imageUrl] : [], // ✅ FIXED: Ensure it's a List<String>
  endTime: DateTime.parse(endTimeController.text),
);

    await _auctionService.createAuction(auction);

    setState(() => _isUploading = false);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Auction created successfully!")));
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("Create Auction")),
    body: SafeArea(  // Add SafeArea for better edge handling
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(  // Ensure the form can scroll
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,  // Stretch widgets to fill width
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Auction Title"),
                  validator: (value) => value!.isEmpty ? "Title is required" : null,
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                  validator: (value) => value!.isEmpty ? "Description is required" : null,
                ),
                TextFormField(
                  controller: startingPriceController,
                  decoration: const InputDecoration(labelText: "Starting Price (\$)"),
                  keyboardType: TextInputType.number,
                  validator: (value) => (value == null || double.tryParse(value) == null) ? "Enter a valid price" : null,
                ),
                TextFormField(
                  controller: bidIncrementController,
                  decoration: const InputDecoration(labelText: "Bid Increment (\$)"),
                  keyboardType: TextInputType.number,
                  validator: (value) => (value == null || double.tryParse(value) == null) ? "Enter a valid bid increment" : null,
                ),
                TextFormField(
                  controller: endTimeController,
                  decoration: const InputDecoration(labelText: "End Time (YYYY-MM-DD HH:MM:SS)"),
                  validator: (value) => value!.isEmpty ? "End time is required" : null,
                ),
                const SizedBox(height: 10),
                _selectedImage == null
                    ? ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text("Upload Image"),
                      )
                    : Image.file(_selectedImage!, height: 150),
                const SizedBox(height: 10),
                _isUploading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _createAuction,
                        child: const Text("Create Auction"),
                      ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
