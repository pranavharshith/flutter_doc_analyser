import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '/utils/profile_image_notifier.dart';
import '/services/storage_service.dart'; // FIX: upload to Firebase Storage

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

  // Edit mode controllers
  bool _editingPhone = false;
  bool _editingName = false;
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  String _selectedCountryCode = '+91'; // Default to India

  @override
  void initState() {
    super.initState();
    _loadImagePath();
  }

  Future<void> _loadImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _imagePath = prefs.getString('profile_image_path_${user!.uid}');
      });
    }
  }

  Future<void> _uploadProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final file = File(pickedFile.path);

      // FIX: Upload to Firebase Storage so image persists across reinstalls
      final downloadUrl = await StorageService.uploadProfileImage(
        uid: user!.uid,
        file: file,
      );

      // Also save path locally for quick offline access
      await ProfileImageNotifier.updateImagePath(pickedFile.path);

      // Save the Firebase Storage URL to Firestore for cross-device access
      await FirebaseFirestore.instance
          .collection('students')
          .doc(user!.uid)
          .update({'profileImageUrl': downloadUrl});

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path_${user!.uid}', pickedFile.path);

      if (mounted) {
        setState(() => _imagePath = pickedFile.path);
      }

      Fluttertoast.showToast(msg: 'Profile image updated!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error uploading image: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveField(String field, String value) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('students').doc(user!.uid);
      await userRef.update({field: value.trim()});

      if (field == 'firstName' || field == 'lastName') {
        // Fetch current document to get full name
        final doc = await userRef.get();
        if (doc.exists) {
          final data = doc.data()!;
          final firstName = data['firstName'] ?? '';
          final lastName = data['lastName'] ?? '';
          final fullName = '$firstName $lastName'.trim();

          // 1. Update in past submissions in student's documents
          // Note: The submissions under `students -> documents -> uploads` don't store the name directly,
          // but they keep the name in the parent document and in adminNotifications.
          // The admin dashboard fetches the name from the student's root doc! So updating the root doc is actually enough for the dashboard.
          
          // However, we should update the name field in the 'users' collection to keep them perfectly synced.
          await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
            'name': fullName,
          }).catchError((_) {}); // Ignore if field doesn't exist yet
        }
      }

      Fluttertoast.showToast(msg: 'Updated successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to update: $e');
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
              color: Colors.white,
            ),
            onPressed: widget.toggleDarkMode,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF1B263B), const Color(0xFF0A111F)]
                : [const Color(0xFFFFFFFF), const Color(0xFFF5F7FA)],
          ),
        ),
        // FIX: Use StreamBuilder so profile data stays live and reflects updates
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('students')
                .doc(user!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: isDarkMode
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
                      color: isDarkMode
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF1B263B),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                  child: Text(
                    'No profile data found',
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF1B263B),
                    ),
                  ),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final firstName = data['firstName'] ?? 'N/A';
              final lastName = data['lastName'] ?? 'N/A';
              final email = data['email'] ?? user?.email ?? 'N/A';
              final phone = data['phone'] ?? 'N/A';
              final profileImageUrl = data['profileImageUrl'] as String?;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // ── Profile avatar ──
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: isDarkMode
                              ? const Color(0xFFB0C4DE).withOpacity(0.2)
                              : const Color(0xFF415A77).withOpacity(0.2),
                          backgroundImage: _imagePath != null &&
                                  File(_imagePath!).existsSync()
                              ? FileImage(File(_imagePath!))
                              : profileImageUrl != null
                                  ? NetworkImage(profileImageUrl)
                                      as ImageProvider
                                  : null,
                          child: (_imagePath == null ||
                                      !File(_imagePath!).existsSync()) &&
                                  profileImageUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 80,
                                  color: isDarkMode
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
                                color: isDarkMode
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
                                      color: isDarkMode
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
                        color: isDarkMode
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFF1B263B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Student Profile',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode
                            ? const Color(0xFFB0C4DE)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Full Name editable ──
                    _buildEditableCard(
                      icon: Icons.person,
                      title: 'Full Name',
                      value: '$firstName $lastName',
                      isDarkMode: isDarkMode,
                      isEditing: _editingName,
                      onEditToggle: () {
                        setState(() {
                          _editingName = !_editingName;
                          if (_editingName) {
                            _firstNameController.text = firstName;
                            _lastNameController.text = lastName;
                          }
                        });
                      },
                      editWidget: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                hintText: 'First Name',
                                hintStyle: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white38
                                        : Colors.black38),
                              ),
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                hintText: 'Last Name',
                                hintStyle: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white38
                                        : Colors.black38),
                              ),
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black),
                            ),
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              await _saveField('firstName',
                                  _firstNameController.text);
                              await _saveField(
                                  'lastName', _lastNameController.text);
                              setState(() => _editingName = false);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Email (read-only) ──
                    _buildProfileCard(
                      icon: Icons.email,
                      title: 'Email',
                      value: email,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 16),

                    // ── Phone editable ──
                    _buildEditableCard(
                      icon: Icons.phone,
                      title: 'Phone Number',
                      value: phone,
                      isDarkMode: isDarkMode,
                      isEditing: _editingPhone,
                      onEditToggle: () {
                        setState(() {
                          _editingPhone = !_editingPhone;
                          if (_editingPhone) {
                            if (phone != 'N/A' && phone.startsWith('+')) {
                              // Rough heuristic for initializing country code
                              if (phone.startsWith('+91')) {
                                _selectedCountryCode = '+91';
                                _phoneController.text = phone.substring(3);
                              } else if (phone.startsWith('+1')) {
                                _selectedCountryCode = '+1';
                                _phoneController.text = phone.substring(2);
                              } else {
                                _selectedCountryCode = '+91'; // default fallback
                                _phoneController.text = phone.replaceAll(RegExp(r'^\+\d+\s?'), '');
                              }
                            } else {
                              _selectedCountryCode = '+91';
                              _phoneController.text = phone == 'N/A' ? '' : phone;
                            }
                          }
                        });
                      },
                      editWidget: Row(
                        children: [
                          Expanded(
                            child: IntlPhoneField(
                              controller: _phoneController,
                              style: TextStyle( color: isDarkMode ? Colors.white : Colors.black ),
                              decoration: InputDecoration(
                                hintText: 'Phone Number',
                                hintStyle: TextStyle(
                                  color: isDarkMode ? Colors.white38 : Colors.black38,
                                ),
                              ),
                              initialCountryCode: 'IN', // Default to India
                              onChanged: (phone) {
                                setState(() {
                                  _selectedCountryCode = phone.countryCode;
                                });
                              },
                              validator: (phone) {
                                if (phone == null || phone.number.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                // Validate length based on country code
                                if (_selectedCountryCode == '+91' && phone.number.length != 10) {
                                  return 'Must be 10 digits';
                                }
                                if (_selectedCountryCode == '+1' && phone.number.length != 10) {
                                  return 'Must be 10 digits';
                                }
                                return null;
                              },
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              final fullPhone = '$_selectedCountryCode${_phoneController.text.trim()}';
                              await _saveField('phone', fullPhone);
                              setState(() => _editingPhone = false);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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
            color: isDarkMode
                ? const Color(0xFFB0C4DE)
                : const Color(0xFF415A77),
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

  Widget _buildEditableCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isDarkMode,
    required bool isEditing,
    required VoidCallback onEditToggle,
    required Widget editWidget,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isDarkMode
                    ? const Color(0xFFB0C4DE)
                    : const Color(0xFF415A77),
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
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
                    if (!isEditing)
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
              ),
              IconButton(
                icon: Icon(
                  isEditing ? Icons.close : Icons.edit,
                  size: 18,
                  color: isDarkMode
                      ? const Color(0xFFB0C4DE)
                      : const Color(0xFF415A77),
                ),
                onPressed: onEditToggle,
              ),
            ],
          ),
          if (isEditing) ...[
            const SizedBox(height: 12),
            editWidget,
          ],
        ],
      ),
    );
  }
}
