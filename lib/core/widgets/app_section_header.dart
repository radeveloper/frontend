import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry margin;
  const AppSectionHeader({
    super.key,
    required this.title,
    this.margin = const EdgeInsets.only(top: 24, bottom: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
