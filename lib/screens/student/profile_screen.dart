import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/utils/profile_image_notifier.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;

  const ProfileScreen({
    super.key,
    required this.toggleDarkMode,
    required this.isDarkMode,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _imagePath;
  final _imageCacheKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadImagePath();
  }

  Future<void> _loadImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _imagePath = prefs.getString('profile_image_path_${user!.uid}');
    });
  }

  Future<void> _uploadProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      // Save image to app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${user!.uid}.jpg';
      final filePath = '${directory.path}/$fileName';

      // Delete the existing file if it exists to ensure overwriting
      final existingFile = File(filePath);
      if (await existingFile.exists()) {
        await existingFile.delete();
      }

      // Save the new image
      final file = File(pickedFile.path);
      await file.copy(filePath);

      // Update the image path using the notifier
      await ProfileImageNotifier.updateImagePath(filePath);

      setState(() {
        _imagePath = filePath;
      });

      Fluttertoast.showToast(msg: 'Profile image updated successfully!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error uploading image: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFFFF),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF415A77), Color(0xFF1B263B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFFFFFFFF),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.isDarkMode
                ? [const Color(0xFF1B263B), const Color(0xFF0A111F)]
                : [const Color(0xFFFFFFFF), const Color(0xFFF5F7FA)],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('students')
                .doc(user!.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: widget.isDarkMode
                        ? const Color(0xFFB0C4DE)
                        : const Color(0xFF415A77),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading profile',
                    style: TextStyle(
                      color: widget.isDarkMode
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF1B263B),
                      fontSize: 18,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                  child: Text(
                    'No profile data found',
                    style: TextStyle(
                      color: widget.isDarkMode
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF1B263B),
                      fontSize: 18,
                    ),
                  ),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final firstName = data['firstName'] ?? 'N/A';
              final lastName = data['lastName'] ?? 'N/A';
              final email = data['email'] ?? 'N/A';
              final phone = data['phone'] ?? 'N/A';

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Stack(
                      children: [
                        CircleAvatar(
                          key: _imageCacheKey,
                          radius: 60,
                          backgroundColor: widget.isDarkMode
                              ? const Color(0xFFB0C4DE).withOpacity(0.2)
                              : const Color(0xFF415A77).withOpacity(0.2),
                          backgroundImage: _imagePath != null &&
                                  File(_imagePath!).existsSync()
                              ? FileImage(File(_imagePath!))
                              : null,
                          child: _imagePath == null ||
                                  !File(_imagePath!).existsSync()
                              ? Icon(
                                  Icons.person,
                                  size: 80,
                                  color: widget.isDarkMode
                                      ? const Color(0xFFB0C4DE)
                                      : const Color(0xFF415A77),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUploading ? null : _uploadProfileImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.isDarkMode
                                    ? const Color(0xFF415A77)
                                    : const Color(0xFFFFFFFF),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: _isUploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: widget.isDarkMode
                                          ? const Color(0xFFFFFFFF)
                                          : const Color(0xFF1B263B),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$firstName $lastName',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFF1B263B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Student Profile',
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.isDarkMode
                            ? const Color(0xFFB0C4DE)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildProfileCard(
                      icon: Icons.person,
                      title: 'Full Name',
                      value: '$firstName $lastName',
                      isDarkMode: widget.isDarkMode,
                    ),
                    const SizedBox(height: 16),
                    _buildProfileCard(
                      icon: Icons.email,
                      title: 'Email',
                      value: email,
                      isDarkMode: widget.isDarkMode,
                    ),
                    const SizedBox(height: 16),
                    _buildProfileCard(
                      icon: Icons.phone,
                      title: 'Phone Number',
                      value: phone,
                      isDarkMode: widget.isDarkMode,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF2A3A5A)
            : const Color(0xFFFFFFFF).withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color:
                isDarkMode ? const Color(0xFFB0C4DE) : const Color(0xFF415A77),
            size: 28,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? const Color(0xFFB0C4DE)
                      : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF1B263B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
