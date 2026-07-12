import 'package:flutter/material.dart';

/// Default largest rules-body font (logical px).
const double kMtgCardRulesMaxFontSize = 12.5;

/// Name line is this factor × [maxFontSize].
const double kMtgCardTitleToRulesMaxFontScale = 1.2;

/// Shares a common rules-text scale across multiple cards.
class MtgCardRulesScaleController extends ChangeNotifier {
  double? _sharedScale;

  double? get sharedScale => _sharedScale;

  void offerScale(double value) {
    if (value.isNaN || value.isInfinite || value <= 0) return;
    if (_sharedScale == null || value < _sharedScale! - 0.0005) {
      _sharedScale = value;
      notifyListeners();
    }
  }
}
