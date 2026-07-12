import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rpg_companion/core/markdown/markdown_wiki_display.dart';
import 'package:rpg_companion/core/ui/rpg_form_styles.dart';

/// Debounced read-only preview pane for markdown + wiki links.
class MarkdownWikiPreview extends StatefulWidget {
  const MarkdownWikiPreview({
    super.key,
    required this.source,
    this.debounce = const Duration(milliseconds: 150),
    this.decoration,
  });

  final String source;
  final Duration debounce;
  final InputDecoration? decoration;

  @override
  State<MarkdownWikiPreview> createState() => _MarkdownWikiPreviewState();
}

class _MarkdownWikiPreviewState extends State<MarkdownWikiPreview> {
  Timer? _debounceTimer;
  String _displaySource = '';

  @override
  void initState() {
    super.initState();
    _displaySource = widget.source;
  }

  @override
  void didUpdateWidget(covariant MarkdownWikiPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _scheduleUpdate(widget.source);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _scheduleUpdate(String source) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () {
      if (!mounted) return;
      setState(() => _displaySource = source);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fieldDecoration =
        widget.decoration ?? RpgFormStyles.fieldDecoration(context);
    final fillColor =
        fieldDecoration.fillColor ?? RpgFormStyles.fieldFillColor(context);
    final enabledBorder = fieldDecoration.enabledBorder ?? fieldDecoration.border;
    final borderSide = enabledBorder is OutlineInputBorder
        ? enabledBorder.borderSide
        : BorderSide(color: theme.colorScheme.outline);
    final borderRadius = enabledBorder is OutlineInputBorder
        ? enabledBorder.borderRadius.resolve(Directionality.of(context))
        : BorderRadius.circular(4);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: borderRadius,
        border: Border.fromBorderSide(borderSide),
      ),
      child: Padding(
        padding: fieldDecoration.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            MarkdownWikiDisplay(source: _displaySource),
          ],
        ),
      ),
    );
  }
}
