import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, ghost }
enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.trailing,
    this.expand = false,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final bool expand;
  final AppButtonVariant variant;
  final AppButtonSize size;

  // ---- Tokens ---------------------------------------------------------------

  double get _height => switch (size) {
    AppButtonSize.sm => 36,
    AppButtonSize.md => 44,
    AppButtonSize.lg => 52,
  };

  double get _hPadding => switch (size) {
    AppButtonSize.sm => 12,
    AppButtonSize.md => 16,
    AppButtonSize.lg => 20,
  };

  double get _iconSize => switch (size) {
    AppButtonSize.sm => 18,
    AppButtonSize.md => 20,
    AppButtonSize.lg => 22,
  };

  double get _gap => 8;

  // ---- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final ButtonStyle style = switch (variant) {
      AppButtonVariant.primary => ElevatedButton.styleFrom(
        minimumSize: Size(0, _height),
        padding: EdgeInsets.symmetric(horizontal: _hPadding),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      AppButtonVariant.secondary => OutlinedButton.styleFrom(
        minimumSize: Size(0, _height),
        padding: EdgeInsets.symmetric(horizontal: _hPadding),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: scheme.outlineVariant),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      AppButtonVariant.ghost => TextButton.styleFrom(
        minimumSize: Size(0, _height),
        padding: EdgeInsets.symmetric(horizontal: _hPadding),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    };

    final child = _buildAdaptiveChild(context);

    final button = switch (variant) {
      AppButtonVariant.primary =>
          ElevatedButton(onPressed: onPressed, style: style, child: child),
      AppButtonVariant.secondary =>
          OutlinedButton(onPressed: onPressed, style: style, child: child),
      AppButtonVariant.ghost =>
          TextButton(onPressed: onPressed, style: style, child: child),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  /// Çok dar alanlarda (ör. maxWidth ~16) overflow atmamak için
  /// içeriği FittedBox ile **scale-down** ederiz.
  Widget _buildAdaptiveChild(BuildContext context) {
    final row = _buildRow();

    // Erişilebilirlik için metni Semantics ile de verelim
    final semantic = Semantics(
      // buton olduğu zaten biliniyor ama label önemli
      label: label,
      child: row,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // constraints.maxWidth çok küçükse (örn 16), Row taşar.
        // FittedBox(fit: scaleDown) → içeriği orantısal küçültür, overflow atmaz.
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: ConstrainedBox(
            // minWidth 1 verip Row'un ölçümünü güvene alıyoruz.
            constraints: const BoxConstraints(minWidth: 1),
            child: semantic,
          ),
        );
      },
    );
  }

  Widget _buildRow() {
    final text = Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    final children = <Widget>[
      if (leading != null)
        Padding(
          padding: EdgeInsets.only(right: _gap),
          child: IconTheme.merge(
            data: IconThemeData(size: _iconSize),
            child: leading!,
          ),
        ),
      text,
      if (trailing != null)
        Padding(
          padding: EdgeInsets.only(left: _gap),
          child: IconTheme.merge(
            data: IconThemeData(size: _iconSize),
            child: trailing!,
          ),
        ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}
