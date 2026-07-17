import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '/utils/profile_image_notifier.dart';
import '/services/storage_service.dart';
import '/widgets/theme_toggle_button.dart';
import '/widgets/profile_image_widget.dart';
import '/ui/ui.dart';
import '/utils/theme.dart';
import '/utils/name_utils.dart';
import '/utils/app_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  /// When true, used as a dashboard tab (shell owns the app bar).
  final bool embedded;

  const ProfileScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _savingName = false;
  bool _savingPhone = false;

  bool _editingPhone = false;
  bool _editingName = false;
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  String _selectedCountryCode = '+91';

  @override
  void initState() {
    super.initState();
    ProfileImageNotifier.init();
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final file = File(pickedFile.path);
      if (!await file.exists()) {
        if (mounted) {
          AppSnackBar.error(context, 'Could not read that image. Try another.');
        }
        return;
      }

      // Show local preview immediately while upload runs.
      await ProfileImageNotifier.updateImagePath(pickedFile.path);

      final downloadUrl = await StorageService.uploadProfileImage(
        uid: user!.uid,
        file: file,
      );

      // Use set+merge so missing student docs still get the field.
      await FirebaseFirestore.instance.collection('students').doc(user!.uid).set(
        {
          'profileImageUrl': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await ProfileImageNotifier.updateFromUpload(
        localPath: pickedFile.path,
        downloadUrl: downloadUrl,
      );

      if (mounted) {
        AppSnackBar.success(context, 'Profile image updated');
      }
    } catch (e) {
      debugPrint('Profile image upload failed: $e');
      if (mounted) {
        AppSnackBar.error(
          context,
          'Could not upload photo. Check Storage rules and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _showImageSourceSheet() async {
    if (_isUploading) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                minVerticalPadding: 16,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUpload(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                minVerticalPadding: 16,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUpload(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveName() async {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    if (first.isEmpty) {
      AppSnackBar.error(context, 'First name is required');
      return;
    }
    setState(() => _savingName = true);
    try {
      final nameFields = NameUtils.firestoreNameFields(
        firstName: first,
        lastName: last,
      );
      await FirebaseFirestore.instance
          .collection('students')
          .doc(user!.uid)
          .update(nameFields);
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set(
        {'name': nameFields['name']},
        SetOptions(merge: true),
      );
      if (mounted) {
        setState(() => _editingName = false);
        AppSnackBar.success(context, 'Name updated');
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, 'Could not update name. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _savePhone() async {
    final number = _phoneController.text.trim();
    if (number.isEmpty) {
      AppSnackBar.error(context, 'Please enter a phone number');
      return;
    }
    if (_selectedCountryCode == '+91' && number.length != 10) {
      AppSnackBar.error(context, 'Phone must be 10 digits');
      return;
    }
    setState(() => _savingPhone = true);
    try {
      final fullPhone = '$_selectedCountryCode$number';
      await FirebaseFirestore.instance
          .collection('students')
          .doc(user!.uid)
          .update({'phone': fullPhone});
      if (mounted) {
        setState(() => _editingPhone = false);
        AppSnackBar.success(context, 'Phone updated');
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, 'Could not update phone. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _savingPhone = false);
    }
  }

  void _beginEditPhone(String phone) {
    setState(() {
      _editingPhone = true;
      if (phone != 'N/A' && phone.startsWith('+')) {
        if (phone.startsWith('+91')) {
          _selectedCountryCode = '+91';
          _phoneController.text = phone.substring(3);
        } else if (phone.startsWith('+1')) {
          _selectedCountryCode = '+1';
          _phoneController.text = phone.substring(2);
        } else {
          _selectedCountryCode = '+91';
          _phoneController.text =
              phone.replaceAll(RegExp(r'^\+\d+\s?'), '');
        }
      } else {
        _selectedCountryCode = '+91';
        _phoneController.text = phone == 'N/A' ? '' : phone;
      }
    });
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
    final accent = isDarkMode ? AppTheme.accentBlue : AppTheme.primaryMid;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted = isDarkMode ? AppTheme.accentBlue : AppTheme.textMuted;

    final body = StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoading(message: 'Loading profile…');
        }
        if (snapshot.hasError) {
          return AppEmptyState.error(
            title: 'Error loading profile',
            message: 'Could not load your profile. Pull to refresh or try again.',
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const AppEmptyState(
            icon: Icons.person_off_outlined,
            title: 'No profile data found',
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final firstName = data['firstName'] ?? 'N/A';
        final lastName = data['lastName'] ?? 'N/A';
        final email = data['email'] ?? user?.email ?? 'N/A';
        final phone = data['phone'] ?? 'N/A';

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Stack(
                children: [
                  const ProfileImageWidget(radius: 60),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: isDarkMode
                          ? AppTheme.primaryMid
                          : AppTheme.bgLight,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _isUploading ? null : _showImageSourceSheet,
                        child: Semantics(
                          button: true,
                          label: 'Change profile photo',
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: _isUploading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.camera_alt_outlined,
                                      size: 20,
                                      color: isDarkMode
                                          ? AppTheme.bgLight
                                          : AppTheme.primaryDark,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                NameUtils.composeName(
                  firstName == 'N/A' ? '' : firstName,
                  lastName == 'N/A' ? '' : lastName,
                ).isEmpty
                    ? 'Student'
                    : NameUtils.composeName(
                        firstName == 'N/A' ? '' : firstName,
                        lastName == 'N/A' ? '' : lastName,
                      ),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Student Profile',
                style: TextStyle(fontSize: 15, color: muted),
              ),
              const SizedBox(height: 28),

              // ── Name ──
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline, color: accent, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Full name',
                            style: TextStyle(fontSize: 14, color: muted),
                          ),
                        ),
                        if (!_editingName)
                          IconButton(
                            tooltip: 'Edit name',
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            icon: Icon(Icons.edit_outlined, color: accent),
                            onPressed: () {
                              setState(() {
                                _editingName = true;
                                _firstNameController.text =
                                    firstName == 'N/A' ? '' : firstName;
                                _lastNameController.text =
                                    lastName == 'N/A' ? '' : lastName;
                              });
                            },
                          ),
                      ],
                    ),
                    if (!_editingName)
                      Padding(
                        padding: const EdgeInsets.only(left: 38),
                        child: Text(
                          '$firstName $lastName',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                      )
                    else ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'First name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Last name',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _savingName
                                  ? null
                                  : () => setState(() => _editingName = false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _savingName ? null : _saveName,
                              child: _savingName
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Email (read-only) ──
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.email_outlined, color: accent, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: TextStyle(fontSize: 14, color: muted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Email is tied to your account and cannot be '
                            'changed here. Contact support if you need to update it.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Phone ──
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, color: accent, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Phone number',
                            style: TextStyle(fontSize: 14, color: muted),
                          ),
                        ),
                        if (!_editingPhone)
                          IconButton(
                            tooltip: 'Edit phone',
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            icon: Icon(Icons.edit_outlined, color: accent),
                            onPressed: () => _beginEditPhone(phone),
                          ),
                      ],
                    ),
                    if (!_editingPhone)
                      Padding(
                        padding: const EdgeInsets.only(left: 38),
                        child: Text(
                          phone,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                      )
                    else ...[
                      const SizedBox(height: 12),
                      IntlPhoneField(
                        controller: _phoneController,
                        style: TextStyle(color: onSurface),
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                        ),
                        initialCountryCode: 'IN',
                        onChanged: (p) {
                          setState(() => _selectedCountryCode = p.countryCode);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _savingPhone
                                  ? null
                                  : () =>
                                      setState(() => _editingPhone = false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _savingPhone ? null : _savePhone,
                              child: _savingPhone
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );

    if (widget.embedded) {
      return AppGradientBody(child: body);
    }

    return AppScaffold(
      title: 'Profile',
      actions: const [ThemeToggleButton(color: AppTheme.bgLight)],
      body: body,
    );
  }
}
