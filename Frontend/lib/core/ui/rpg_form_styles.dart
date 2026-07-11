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
}
