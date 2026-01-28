import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageWidget extends StatefulWidget {
  final double radius;
  final bool isDarkMode;

  const ProfileImageWidget({
    super.key,
    required this.radius,
    required this.isDarkMode,
  });

  @override
  _ProfileImageWidgetState createState() => _ProfileImageWidgetState();
}

class _ProfileImageWidgetState extends State<ProfileImageWidget> {
  final user = FirebaseAuth.instance.currentUser;
  String? _imagePath;

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

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.isDarkMode
          ? const Color(0xFFB0C4DE).withOpacity(0.2)
          : const Color(0xFF415A77).withOpacity(0.2),
      backgroundImage: _imagePath != null && File(_imagePath!).existsSync()
          ? FileImage(File(_imagePath!))
          : null,
      child: _imagePath == null || !File(_imagePath!).existsSync()
          ? Icon(
              Icons.person,
              size: widget.radius * 1.33,
              color: widget.isDarkMode
                  ? const Color(0xFFB0C4DE)
                  : const Color(0xFF415A77),
            )
          : null,
    );
  }
}
