import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'app_button.dart';

class AppDialog {
  static Future<bool?> confirm(
      BuildContext context, {
        required String title,
        required String message,
        String confirmText = 'Confirm',
        String cancelText = 'Cancel',
      }) {
    return showDialog<bool>(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 20)),
                const SizedBox(height: AppSpacing.s),
                Text(message, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.l),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: cancelText,
                        variant: AppButtonVariant.secondary,
                        size: AppButtonSize.medium,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: AppButton(
                        label: confirmText,
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.medium,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
