import 'package:rpg_companion/core/markdown/wiki_link.dart';

enum InlineStyle {
  bold,
  italic,
  underline,
  code,
}

/// Inline content within a markdown block.
sealed class InlineNode {
  const InlineNode();
}

class TextInlineNode extends InlineNode {
  const TextInlineNode(this.text, {this.styles = const {}});

  final String text;
  final Set<InlineStyle> styles;
}

class WikiLinkInlineNode extends InlineNode {
  const WikiLinkInlineNode(this.link);

  final WikiLink link;
}

/// Block-level markdown content.
sealed class MarkdownBlock {
  const MarkdownBlock();
}

class HeadingBlock extends MarkdownBlock {
  const HeadingBlock({required this.level, required this.inlines});

  final int level;
  final List<InlineNode> inlines;
}

class ParagraphBlock extends MarkdownBlock {
  const ParagraphBlock(this.inlines);

  final List<InlineNode> inlines;
}

class BulletListBlock extends MarkdownBlock {
  const BulletListBlock(this.items);

  final List<List<InlineNode>> items;
}

class OrderedListBlock extends MarkdownBlock {
  const OrderedListBlock(this.items);

  final List<List<InlineNode>> items;
}

class MarkdownDocument {
  const MarkdownDocument(this.blocks);

  final List<MarkdownBlock> blocks;

  static const empty = MarkdownDocument([]);
}
