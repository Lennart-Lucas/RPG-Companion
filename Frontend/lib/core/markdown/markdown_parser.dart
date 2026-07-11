import 'package:markdown/markdown.dart' as md;
import 'package:rpg_companion/core/markdown/markdown_document.dart';
import 'package:rpg_companion/core/markdown/wiki_link.dart';

/// Parses markdown source into a [MarkdownDocument] with wiki-link support.
abstract final class MarkdownParser {
  static MarkdownDocument parse(String source) {
    if (source.trim().isEmpty) {
      return MarkdownDocument.empty;
    }

    final blocks = <MarkdownBlock>[];
    final lines = source.split('\n');
    var index = 0;

    while (index < lines.length) {
      final line = lines[index];
      final trimmed = line.trimRight();

      if (trimmed.isEmpty) {
        index++;
        continue;
      }

      final headingMatch = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(trimmed);
      if (headingMatch != null) {
        blocks.add(
          HeadingBlock(
            level: headingMatch.group(1)!.length,
            inlines: parseInline(headingMatch.group(2)!),
          ),
        );
        index++;
        continue;
      }

      if (RegExp(r'^[-*+]\s+').hasMatch(trimmed)) {
        final items = <List<InlineNode>>[];
        while (index < lines.length) {
          final current = lines[index].trimRight();
          final itemMatch = RegExp(r'^[-*+]\s+(.*)$').firstMatch(current);
          if (itemMatch == null) break;
          items.add(parseInline(itemMatch.group(1)!));
          index++;
        }
        blocks.add(BulletListBlock(items));
        continue;
      }

      if (RegExp(r'^\d+\.\s+').hasMatch(trimmed)) {
        final items = <List<InlineNode>>[];
        while (index < lines.length) {
          final current = lines[index].trimRight();
          final itemMatch = RegExp(r'^\d+\.\s+(.*)$').firstMatch(current);
          if (itemMatch == null) break;
          items.add(parseInline(itemMatch.group(1)!));
          index++;
        }
        blocks.add(OrderedListBlock(items));
        continue;
      }

      final paragraphLines = <String>[];
      while (index < lines.length) {
        final current = lines[index].trimRight();
        if (current.isEmpty) break;
        if (RegExp(r'^(#{1,3})\s+').hasMatch(current)) break;
        if (RegExp(r'^[-*+]\s+').hasMatch(current)) break;
        if (RegExp(r'^\d+\.\s+').hasMatch(current)) break;
        paragraphLines.add(current);
        index++;
      }
      blocks.add(ParagraphBlock(parseInline(paragraphLines.join('\n'))));
    }

    return MarkdownDocument(blocks);
  }

  /// Parses inline markdown + wiki links within a single line of text.
  static List<InlineNode> parseInline(String text) {
    if (text.isEmpty) return const [];

    final nodes = <InlineNode>[];
    var cursor = 0;

    for (final match in findWikiLinkMatches(text)) {
      if (match.start > cursor) {
        nodes.addAll(_parseStyledText(text.substring(cursor, match.start)));
      }
      final link = WikiLink.tryParse(match.group(0)!);
      if (link != null) {
        nodes.add(WikiLinkInlineNode(link));
      } else {
        nodes.add(TextInlineNode(match.group(0)!));
      }
      cursor = match.end;
    }

    if (cursor < text.length) {
      nodes.addAll(_parseStyledText(text.substring(cursor)));
    }

    return nodes;
  }

  static List<InlineNode> _parseStyledText(String text) {
    if (text.isEmpty) return const [];

    final document = md.Document(
      extensionSet: md.ExtensionSet.none,
      encodeHtml: false,
    );
    final astNodes = document.parseInline(text);

    final output = <InlineNode>[];
    for (final node in astNodes) {
      _collectInlineNodes(node, output, {});
    }

    if (output.isEmpty && text.isNotEmpty) {
      output.addAll(_parseCustomDelimiters(text));
    }

    return output.isEmpty ? [TextInlineNode(text)] : output;
  }

  static void _collectInlineNodes(
    md.Node node,
    List<InlineNode> output,
    Set<InlineStyle> styles,
  ) {
    if (node is md.Text) {
      final value = node.text;
      if (value.isNotEmpty) {
        output.addAll(_parseCustomDelimiters(value, baseStyles: styles));
      }
      return;
    }

    if (node is md.Element) {
      final nextStyles = Set<InlineStyle>.from(styles);
      switch (node.tag) {
        case 'strong':
        case 'b':
          nextStyles.add(InlineStyle.bold);
        case 'em':
        case 'i':
          nextStyles.add(InlineStyle.italic);
        case 'code':
          nextStyles.add(InlineStyle.code);
      }

      for (final child in node.children ?? const <md.Node>[]) {
        _collectInlineNodes(child, output, nextStyles);
      }
    }
  }

  static List<InlineNode> _parseCustomDelimiters(
    String text, {
    Set<InlineStyle> baseStyles = const {},
  }) {
    if (!text.contains('++')) {
      if (baseStyles.isEmpty) {
        return text.isEmpty ? const [] : [TextInlineNode(text)];
      }
      return [TextInlineNode(text, styles: baseStyles)];
    }

    final nodes = <InlineNode>[];
    final parts = text.split('++');
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) continue;
      final styles = Set<InlineStyle>.from(baseStyles);
      if (i.isOdd) {
        styles.add(InlineStyle.underline);
      }
      if (styles.isEmpty) {
        nodes.add(TextInlineNode(part));
      } else {
        nodes.add(TextInlineNode(part, styles: styles));
      }
    }
    return nodes;
  }
}
