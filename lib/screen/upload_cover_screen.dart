import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
                maxLength: 40,
                decoration: InputDecoration(
                  hintText: 'Enter Room Title (e.g. Chat & Music)',
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // የቀጣይ ቁልፍ (Next Step Button)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedImage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('እባክዎ መጀመሪያ የክፍሉን ሽፋን ፎቶ ይምረጡ'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    // ወደ ደረጃ 3 (Beautify / Go Live) የሚያሳልፍ ጥሪ እዚህ ይቀመጣል
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Next Step',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(int step, String title, {required bool isDone, required bool isActive}) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(

color: isDone
                ? const Color(0xFF10B981)
                : (isActive ? const Color(0xFF2563EB) : Colors.grey.shade300),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '$step',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: isActive || isDone ? Colors.black87 : Colors.grey,
            fontWeight: isActive || isDone ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider({required bool isActive}) {
    return Container(
      width: 45,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
      color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade300,
    );
  }
}
