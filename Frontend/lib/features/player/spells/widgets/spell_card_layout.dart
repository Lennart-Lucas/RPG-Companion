/// Layout constants for spell cards sized like MTG playing cards (2.5" × 3.5").
abstract final class SpellCardLayout {
  /// Standard MTG width in inches.
  static const aspectWidth = 2.5;

  /// Standard MTG height in inches.
  static const aspectHeight = 3.5;

  /// Display width in logical pixels (maintains 5:7 aspect ratio).
  static const width = 350.0;

  /// Display height matching MTG aspect ratio.
  static const height = width * aspectHeight / aspectWidth;

  static const bodyPadding = 12.0;
  static const borderRadius = 10.0;

  static const headerHeight = 40.0;
  static const subheaderHeight = 32.0;
  static const infoBlockHeight = 84.0;
  static const infoBlockHorizontalPadding = 12.0;
  static const footerHeight = 36.0;

  static const bodyMaxHeightFirstPage = height -
      headerHeight -
      subheaderHeight -
      infoBlockHeight -
      footerHeight -
      bodyPadding;

  static const bodyMaxHeightContinuation = height -
      headerHeight -
      subheaderHeight -
      footerHeight -
      bodyPadding;

  static const bodyContentWidth = width - (bodyPadding * 2);
}
