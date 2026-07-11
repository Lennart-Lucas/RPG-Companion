import 'package:flutter/material.dart';

/// Theme-backed decorations for RPG Companion forms.
class RpgFormStyles {
  RpgFormStyles._();

  static const double fieldSpacing = 8;
  static const double sectionHeaderMarginTop = 24;
  static const double sectionHeaderMarginBottom = 12;

  static InputDecoration fieldDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.inputDecorationTheme;

    return InputDecoration(
      filled: base.filled,
      fillColor: base.fillColor,
      border: base.border,
      enabledBorder: base.enabledBorder,
      focusedBorder: base.focusedBorder,
      errorBorder: base.errorBorder,
      focusedErrorBorder: base.focusedErrorBorder,
      disabledBorder: base.disabledBorder,
      contentPadding: base.contentPadding,
      isDense: base.isDense,
    );
  }

  static Color fieldFillColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.inputDecorationTheme.fillColor ??
        theme.colorScheme.surface;
  }

  static Color submitButtonColor(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.elevatedButtonTheme.style;
    return style?.backgroundColor?.resolve(const {}) ??
        theme.colorScheme.primary;
  }

  static Color submitButtonForegroundColor(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.elevatedButtonTheme.style;
    return style?.foregroundColor?.resolve(const {}) ??
        theme.colorScheme.onPrimary;
  }
}
