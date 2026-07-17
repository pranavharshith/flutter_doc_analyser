import 'package:flutter/material.dart';
import '/utils/theme.dart';

/// Simple 3-step progress for document flow: Details → Upload → Result.
class WizardStepper extends StatelessWidget {
  final int currentStep; // 0-based
  final List<String> labels;

  const WizardStepper({
    super.key,
    required this.currentStep,
    this.labels = const ['Details', 'Upload', 'Result'],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = isDark ? AppTheme.accentBlue : AppTheme.primaryMid;
    final inactive = isDark ? Colors.white24 : Colors.black26;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final afterStep = i ~/ 2;
            final done = currentStep > afterStep;
            return Expanded(
              child: Container(
                height: 2,
                color: done ? active : inactive,
              ),
            );
          }
          final step = i ~/ 2;
          final isActive = step == currentStep;
          final isDone = step < currentStep;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone || isActive ? active : Colors.transparent,
                  border: Border.all(
                    color: isDone || isActive ? active : inactive,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${step + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? Colors.white
                              : (isDark ? AppTheme.accentBlue : AppTheme.textMuted),
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[step],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive || isDone
                      ? (isDark ? AppTheme.accentBlue : AppTheme.primaryDark)
                      : AppTheme.textMuted,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
