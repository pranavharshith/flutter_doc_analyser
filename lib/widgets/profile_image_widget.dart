import 'dart:io';
import 'package:flutter/material.dart';
import '/providers/theme_controller.dart';
import '/utils/profile_image_notifier.dart';
import '/utils/theme.dart';

/// App-bar / drawer avatar. Listens to [ProfileImageNotifier] (URL preferred).
class ProfileImageWidget extends StatelessWidget {
  final double radius;

  const ProfileImageWidget({
    super.key,
    required this.radius,
  });

  ImageProvider? _provider(String? ref) {
    if (ref == null || ref.isEmpty) return null;
    // Prefer local file when present (instant after pick; works offline).
    if (!ProfileImageNotifier.isNetworkUrl(ref)) {
      final file = File(ref);
      if (file.existsSync()) return FileImage(file);
      return null;
    }
    return NetworkImage(ref);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final accent = isDark ? AppTheme.accentBlue : AppTheme.primaryMid;

    return ValueListenableBuilder<String?>(
      valueListenable: ProfileImageNotifier.imagePath,
      builder: (context, ref, _) {
        final image = _provider(ref);
        return Semantics(
          label: 'Profile photo',
          child: CircleAvatar(
            radius: radius,
            backgroundColor: accent.withValues(alpha: 0.2),
            backgroundImage: image,
            child: image == null
                ? Icon(
                    Icons.person,
                    size: radius * 1.33,
                    color: accent,
                  )
                : null,
          ),
        );
      },
    );
  }
}
