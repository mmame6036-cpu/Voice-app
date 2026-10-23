import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'beautify_screen.dart';

class UploadCoverScreen extends StatefulWidget {
  const UploadCoverScreen({Key? key}) : super(key: key);

  @override
  State<UploadCoverScreen> createState() => _UploadCoverScreenState();
}

class _UploadCoverScreenState extends State<UploadCoverScreen> {
  File? _selectedImage;
  final TextEditingController _titleController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Start live',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // የማሳሰቢያ ባነር
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '3 Steps to Going Live - Make Money Daily!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFEA580C),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // 3ቱ ደረጃዎች (ደረጃ 2 ነቅቷል)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepItem(1, 'Verification', isDone: true, isActive: false),
                  _buildStepDivider(isActive: true),
                  _buildStepItem(2, 'Upload Cover', isDone: false, isActive: true),
                  _buildStepDivider(isActive: false),
                  _buildStepItem(3, 'Beautify', isDone: false, isActive: false),
                ],
              ),

              const SizedBox(height: 35),

              // የሽፋን ፎቶ ማስገቢያ ሳጥን (Cover Upload Box)
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )

: null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_photo_alternate_rounded,
                                size: 48, color: Color(0xFF94A3B8)),
                            SizedBox(height: 8),
                            Text(
                              'Upload Cover Photo',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 25),

              // የክፍሉ ርዕስ መጻፊያ (Room Title Input)
              TextField(
                controller: _titleController,
