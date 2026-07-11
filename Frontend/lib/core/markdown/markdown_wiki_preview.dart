import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rpg_companion/core/markdown/markdown_wiki_display.dart';

/// Debounced read-only preview pane for markdown + wiki links.
class MarkdownWikiPreview extends StatefulWidget {
  const MarkdownWikiPreview({
    super.key,
    required this.source,
    this.debounce = const Duration(milliseconds: 150),
  });

  final String source;
  final Duration debounce;

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
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
    );
  }
}
