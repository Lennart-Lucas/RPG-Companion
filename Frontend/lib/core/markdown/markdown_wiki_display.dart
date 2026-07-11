import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rpg_companion/core/markdown/linkable_record_registry.dart';
import 'package:rpg_companion/core/markdown/markdown_document.dart';
import 'package:rpg_companion/core/markdown/markdown_parser.dart';
import 'package:rpg_companion/core/markdown/record_link_index.dart';
import 'package:rpg_companion/core/markdown/record_link_navigator.dart';
import 'package:rpg_companion/core/markdown/wiki_link.dart';
import 'package:rpg_companion/core/records/rpg_record.dart';

/// Renders parsed markdown with clickable wiki links to record detail pages.
class MarkdownWikiDisplay extends StatelessWidget {
  const MarkdownWikiDisplay({
    super.key,
    required this.source,
    this.padding = EdgeInsets.zero,
  });

  final String source;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final document = MarkdownParser.parse(source);
    if (document.blocks.isEmpty) {
      return Padding(
        padding: padding,
        child: Text(
          source.isEmpty ? '' : source,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final block in document.blocks) _buildBlock(context, block),
        ],
      ),
    );
  }

  Widget _buildBlock(BuildContext context, MarkdownBlock block) {
    return switch (block) {
      HeadingBlock(:final level, :final inlines) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text.rich(
            TextSpan(
              children: _buildInlineSpans(context, inlines),
              style: _headingStyle(context, level),
            ),
          ),
        ),
      ParagraphBlock(:final inlines) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text.rich(
            TextSpan(
              children: _buildInlineSpans(context, inlines),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      BulletListBlock(:final items) => Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in items)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: _buildInlineSpans(context, item),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      OrderedListBlock(:final items) => Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}.  '),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: _buildInlineSpans(context, items[i]),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
    };
  }

  TextStyle? _headingStyle(BuildContext context, int level) {
    final theme = Theme.of(context).textTheme;
    return switch (level) {
      1 => theme.headlineSmall,
      2 => theme.titleLarge,
      _ => theme.titleMedium,
    };
  }

  List<InlineSpan> _buildInlineSpans(
    BuildContext context,
    List<InlineNode> inlines,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return [
      for (final node in inlines)
        switch (node) {
          TextInlineNode(:final text, :final styles) => TextSpan(
              text: text,
              style: _textStyle(context, styles),
            ),
          WikiLinkInlineNode(:final link) => _wikiLinkSpan(context, link, scheme),
        },
    ];
  }

  TextStyle? _textStyle(BuildContext context, Set<InlineStyle> styles) {
    if (styles.isEmpty) return null;

    var style = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    if (styles.contains(InlineStyle.bold)) {
      style = style.copyWith(fontWeight: FontWeight.bold);
    }
    if (styles.contains(InlineStyle.italic)) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }
    if (styles.contains(InlineStyle.underline)) {
      style = style.copyWith(decoration: TextDecoration.underline);
    }
    if (styles.contains(InlineStyle.code)) {
      style = style.copyWith(
        fontFamily: 'monospace',
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      );
    }
    return style;
  }

  InlineSpan _wikiLinkSpan(
    BuildContext context,
    WikiLink link,
    ColorScheme scheme,
  ) {
    final record = RecordLinkIndex.resolveRecord(link.type, link.id);
    final config = LinkableRecordRegistry.configFor(link.type);
    final label =
        link.alias ?? (record is RpgRecord ? record.name : null) ?? '${link.type}:${link.id}';
    final broken = record == null || config == null;

    return TextSpan(
      text: label,
      style: TextStyle(
        color: broken ? scheme.onSurfaceVariant : scheme.primary,
        decoration: TextDecoration.underline,
        decorationStyle: broken ? TextDecorationStyle.dotted : null,
      ),
      recognizer: broken
          ? null
          : (TapGestureRecognizer()
            ..onTap = () {
              RecordLinkNavigator.open(
                context,
                type: link.type,
                id: link.id,
                record: record,
              );
            }),
    );
  }
}
