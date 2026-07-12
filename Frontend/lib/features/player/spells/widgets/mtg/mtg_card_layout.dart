import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Width ÷ height for a standard Magic card (2.5 in × 3.5 in).
const double kMtgCardAspectRatio = 5 / 7;

/// ISO / tournament dimensions for a Magic card: **2.5 in × 3.5 in**.
const double kMtgCardWidthMm = 63.5;
const double kMtgCardHeightMm = 88.9;

const double kMmPerInch = 25.4;
const double kFlutterLogicalPixelsPerInch = 96.0;

/// Calibrates nominal mm→logical so on-screen size matches a physical card.
const double kMtgCardPhysicalMatchCalibration = 4.0 / 3.0;

const double kMtgTargetWidthLogical =
    kMtgCardWidthMm *
    kFlutterLogicalPixelsPerInch /
    kMmPerInch *
    kMtgCardPhysicalMatchCalibration;
const double kMtgTargetHeightLogical =
    kMtgCardHeightMm *
    kFlutterLogicalPixelsPerInch /
    kMmPerInch *
    kMtgCardPhysicalMatchCalibration;

/// Alpha for the large watermark icon behind body text on MTG-style cards.
const double kItemCardWatermarkIconAlpha = 0.35;

/// MTG card corner radius used by spell sheets.
const double kMtgCardBorderRadius = 14.0;

Size computeMtgCardLogicalSize(
  BuildContext context,
  BoxConstraints constraints,
) {
  final mq = MediaQuery.of(context);
  final screen = mq.size;

  final maxW = constraints.maxWidth.isFinite
      ? constraints.maxWidth
      : screen.width;

  final double maxH;
  if (constraints.maxHeight.isFinite) {
    maxH = constraints.maxHeight;
  } else {
    final viewportH = screen.height - mq.padding.vertical;
    maxH = math.max(160, viewportH * 0.92);
  }

  const tw = kMtgTargetWidthLogical;
  const th = kMtgTargetHeightLogical;
  final scale = math.min(1.0, math.min(maxW / tw, maxH / th));
  return Size(tw * scale, th * scale);
}
