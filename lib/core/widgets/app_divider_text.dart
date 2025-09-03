import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class AppDividerText extends StatelessWidget {
  final String text;
  const AppDividerText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
      ],
    );
  }
}
