import 'package:flutter/material.dart';
import 'package:rpg_companion/core/markdown/markdown_wiki_display.dart';
import 'package:rpg_companion/features/player/spells/widgets/mtg/mtg_card_rules_scale.dart';

/// Scales markdown body text to fit the available card height without scrolling.
class MtgCardMarkdownFit extends StatefulWidget {
  const MtgCardMarkdownFit({
    super.key,
    required this.source,
    required this.onSurface,
    this.maxFontSize = kMtgCardRulesMaxFontSize,
    this.scaleController,
  });

  final String source;
  final Color onSurface;
  final double maxFontSize;
  final MtgCardRulesScaleController? scaleController;

  @override
  State<MtgCardMarkdownFit> createState() => _MtgCardMarkdownFitState();
}

class _MtgCardMarkdownFitState extends State<MtgCardMarkdownFit> {
  static const double _kBaseFont = 11.5;
  static const double _kBaseHeight = 1.25;
  static const double _kMinScale = 0.3;
  static const int _kMaxBinaryIters = 16;

  int _phase = 0;
  int _binaryIter = 0;
  double? _lo;
  double? _hi;

  double _scale = 1.0;
  final GlobalKey _measureKey = GlobalKey();
  double? _heightBudget;
  double? _prevLayoutMaxH;

  double get _maxScale => widget.maxFontSize / _kBaseFont;

  @override
  void initState() {
    super.initState();
    _scale = widget.scaleController?.sharedScale?.clamp(_kMinScale, _maxScale) ??
        _maxScale;
    widget.scaleController?.addListener(_onSharedScaleChanged);
  }

  @override
  void didUpdateWidget(covariant MtgCardMarkdownFit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scaleController != widget.scaleController) {
      oldWidget.scaleController?.removeListener(_onSharedScaleChanged);
      widget.scaleController?.addListener(_onSharedScaleChanged);
      _onSharedScaleChanged();
    }
    if (widget.source != oldWidget.source ||
        widget.maxFontSize != oldWidget.maxFontSize) {
      _beginFit();
    }
  }

  @override
  void dispose() {
    widget.scaleController?.removeListener(_onSharedScaleChanged);
    super.dispose();
  }

  void _onSharedScaleChanged() {
    if (!mounted) return;
    final shared = widget.scaleController?.sharedScale;
    if (shared == null) return;
    final clamped = shared.clamp(_kMinScale, _maxScale);
    if ((_scale - clamped).abs() < 0.001) return;
    setState(() => _scale = clamped);
  }

  void _beginFit() {
    if (!mounted) return;
    _phase = 0;
    _binaryIter = 0;
    _lo = null;
    _hi = null;
    setState(() => _scale = _maxScale);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitStep());
  }

  void _fitStep() {
    if (!mounted) return;
    final maxH = _heightBudget;
    if (maxH == null || maxH.isInfinite || maxH <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitStep());
      return;
    }
    final box = _measureKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitStep());
      return;
    }
    final h = box.size.height;
    final maxScale = _maxScale;

    if (_phase == 0) {
      if (h <= maxH + 1.0) {
        if ((_scale - maxScale).abs() > 0.001) {
          setState(() => _scale = maxScale);
        }
        widget.scaleController?.offerScale(_scale);
        return;
      }
      _phase = 1;
      setState(() => _scale = _kMinScale);
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitStep());
      return;
    }

    if (_phase == 1) {
      if (h > maxH + 0.5) {
        setState(() => _scale = _kMinScale);
        widget.scaleController?.offerScale(_kMinScale);
        return;
      }
      _phase = 2;
      _lo = _kMinScale;
      _hi = maxScale;
      _binaryIter = 0;
      setState(() => _scale = ((_lo! + _hi!) / 2).clamp(_kMinScale, maxScale));
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitStep());
      return;
    }

    if (_phase == 2) {
      if (h <= maxH + 0.75) {
        _lo = _scale;
      } else {
        _hi = _scale;
      }

      if (_hi! - _lo! < 0.004 || _binaryIter >= _kMaxBinaryIters) {
        final resolved = _lo!.clamp(_kMinScale, maxScale);
        setState(() => _scale = resolved);
        widget.scaleController?.offerScale(resolved);
        _phase = 0;
        _lo = null;
        _hi = null;
        return;
      }

      _binaryIter++;
      setState(() {
        _scale = ((_lo! + _hi!) / 2).clamp(_kMinScale, maxScale);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitStep());
    }
  }

  TextStyle get _bodyStyle => TextStyle(
        color: widget.onSurface,
        fontSize: _kBaseFont * _scale,
        height: _kBaseHeight,
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _heightBudget = constraints.maxHeight;
        final w = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        final mh = maxH.isFinite ? maxH : 0.0;
        if (mh > 0) {
          if (_prevLayoutMaxH == null || (mh - _prevLayoutMaxH!).abs() > 0.5) {
            _prevLayoutMaxH = mh;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _beginFit();
            });
          }
        }

        return SizedBox(
          width: w,
          height: maxH,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: w,
              maxWidth: w,
              minHeight: 0,
              maxHeight: double.infinity,
              child: SizedBox(
                key: _measureKey,
                width: w,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: Theme.of(context).textTheme.apply(
                          fontSizeFactor: _scale,
                          bodyColor: widget.onSurface,
                          displayColor: widget.onSurface,
                        ),
                  ),
                  child: DefaultTextStyle(
                    style: _bodyStyle,
                    child: MarkdownWikiDisplay(source: widget.source),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
