import 'package:flutter/material.dart';

/// Light wrapper for form fields on pages with [AnvilBackgroundIcon].
class TransparentFormPanel extends StatelessWidget {
  const TransparentFormPanel({
    super.key,
    required this.child,
    this.opacity = 0,
  });

  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clampedOpacity = opacity.clamp(0.0, 1.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: clampedOpacity > 0
            ? scheme.surface.withValues(alpha: clampedOpacity)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: child,
      ),
    );
  }
}
