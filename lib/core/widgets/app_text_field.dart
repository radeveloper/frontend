// lib/core/widgets/app_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppTextFieldSize { sm, md, lg }

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hint,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.borderRadius,
    this.size = AppTextFieldSize.md,
  });

  final TextEditingController? controller;
  final String? hint;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;

  // ✅ Yeni/opsiyonel alanlar:
  final TextInputType? keyboardType;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  final int? minLines;
  final int? maxLines;
  final bool enabled;

  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double? borderRadius;
  final AppTextFieldSize size;

  double get _hPadding => switch (size) {
    AppTextFieldSize.sm => 12,
    AppTextFieldSize.md => 14,
    AppTextFieldSize.lg => 16,
  };

  double get _vPadding => switch (size) {
    AppTextFieldSize.sm => 8,
    AppTextFieldSize.md => 12,
    AppTextFieldSize.lg => 16,
  };

  double get _fontSize => switch (size) {
    AppTextFieldSize.sm => 14,
    AppTextFieldSize.md => 16,
    AppTextFieldSize.lg => 18,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(borderRadius ?? 12);

    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,              // ✅ geçirildi
      textCapitalization: textCapitalization,        // ✅ geçirildi
      minLines: minLines,
      maxLines: maxLines,
      enabled: enabled,
      style: TextStyle(fontSize: _fontSize),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(horizontal: _hPadding, vertical: _vPadding),
        border: OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: .5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
      ),
    );
  }
}
