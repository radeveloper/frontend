import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final border = 6.0;
    final box = size + border * 2;

    return Container(
      width: box,
      height: box,
      padding: EdgeInsets.all(border + 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: border),
      ),
      child: const FittedBox(
        child: Icon(Icons.code_rounded, color: AppColors.primary),
      ),
    );
  }
}
