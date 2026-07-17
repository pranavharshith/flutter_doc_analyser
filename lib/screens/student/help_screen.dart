import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '/ui/ui.dart';
import '/utils/theme.dart';
import '/utils/app_constants.dart';
import '/utils/app_snackbar.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        AppSnackBar.error(context, 'Could not open ${uri.scheme} link');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, 'Could not open that link. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.accentBlue
        : AppTheme.textMuted;

    return AppScaffold(
      title: 'Help',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Step-by-step guides',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: muted,
                ),
          ),
          const SizedBox(height: 8),
          _guide(
            context,
            title: 'How to navigate the Dashboard',
            content:
                '1. Home — see upload progress and per-document status.\n'
                '2. Documents — submit required documents.\n'
                '3. Alerts — verification updates and notifications.\n'
                '4. Profile — edit name, phone, and photo.',
          ),
          _guide(
            context,
            title: 'How to upload documents',
            content:
                '1. Open the Documents tab.\n'
                '2. Tap a document type.\n'
                '3. Enter details (step 1), then upload a clear image (step 2).\n'
                '4. Review the OCR result (step 3) and wait for admin review if needed.',
          ),
          const SizedBox(height: 20),
          Text(
            'Contact support',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: muted,
                ),
          ),
          const SizedBox(height: 8),
          AppCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.zero,
            onTap: () => _launch(
              context,
              Uri.parse(
                'mailto:${AppConstants.supportEmail}?subject=Vortex%20support%20request',
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email Support'),
              subtitle: Text(
                AppConstants.supportEmail,
                style: TextStyle(color: muted),
              ),
              trailing: const Icon(Icons.open_in_new, size: 18),
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            onTap: () => _launch(
              context,
              Uri(scheme: 'tel', path: AppConstants.supportPhoneTel),
            ),
            child: ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Phone Support'),
              subtitle: Text(
                AppConstants.supportPhone,
                style: TextStyle(color: muted),
              ),
              trailing: const Icon(Icons.open_in_new, size: 18),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a contact to open your email or phone app. '
            'You can also reach your institution’s admin team for account issues.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }

  Widget _guide(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
