import 'package:flutter/material.dart';
import 'package:rpg_companion/core/markdown/markdown_document.dart';
import 'package:rpg_companion/core/markdown/markdown_parser.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_layout.dart';

const kSpellCardWidth = SpellCardLayout.width;
const kSpellCardBodyPadding = SpellCardLayout.bodyPadding;
const kBodyMaxHeightFirstPage = SpellCardLayout.bodyMaxHeightFirstPage;
const kBodyMaxHeightContinuation = SpellCardLayout.bodyMaxHeightContinuation;

/// One paginated slice of spell card body content.
class SpellCardPage {
  const SpellCardPage({
    required this.markdownChunk,
    required this.showInfoBlock,
  });

  final String markdownChunk;
  final bool showInfoBlock;
}

/// Splits combined spell body markdown across one or more card pages.
List<SpellCardPage> paginateSpellBody(
  String source, {
  required double maxWidth,
  required TextStyle bodyStyle,
  required TextStyle headingSmallStyle,
  required TextStyle titleMediumStyle,
  required TextStyle titleLargeStyle,
}) {
  final trimmed = source.trim();
  if (trimmed.isEmpty) {
    return const [
      SpellCardPage(markdownChunk: '', showInfoBlock: true),
    ];
  }

  final document = MarkdownParser.parse(trimmed);
  if (document.blocks.isEmpty) {
    return const [
      SpellCardPage(markdownChunk: '', showInfoBlock: true),
    ];
  }

  final pages = <SpellCardPage>[];
  final queue = List<MarkdownBlock>.from(document.blocks);
  var pageBlocks = <MarkdownBlock>[];
  var isFirstPage = true;

  double maxHeightForCurrentPage() =>
      isFirstPage ? kBodyMaxHeightFirstPage : kBodyMaxHeightContinuation;

  double currentHeight() => _measureBlocks(
        pageBlocks,
        maxWidth: maxWidth,
        bodyStyle: bodyStyle,
        headingSmallStyle: headingSmallStyle,
        titleMediumStyle: titleMediumStyle,
        titleLargeStyle: titleLargeStyle,
      );

  void flushPage() {
    if (pageBlocks.isEmpty) return;
    pages.add(
      SpellCardPage(
        markdownChunk: _blocksToMarkdown(pageBlocks),
        showInfoBlock: isFirstPage,
      ),
    );
    pageBlocks = [];
    isFirstPage = false;
  }

  while (queue.isNotEmpty) {
    final block = queue.removeAt(0);
    final blockHeight = _measureBlock(
      block,
      maxWidth: maxWidth,
      bodyStyle: bodyStyle,
      headingSmallStyle: headingSmallStyle,
      titleMediumStyle: titleMediumStyle,
      titleLargeStyle: titleLargeStyle,
    );

    final maxHeight = maxHeightForCurrentPage();

    if (pageBlocks.isEmpty && blockHeight > maxHeight) {
      final split = _splitBlockToFit(
        block,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        bodyStyle: bodyStyle,
        headingSmallStyle: headingSmallStyle,
        titleMediumStyle: titleMediumStyle,
        titleLargeStyle: titleLargeStyle,
      );
      if (split.head != null) {
        pageBlocks.add(split.head!);
        flushPage();
      }
      if (split.tail != null) {
        queue.insert(0, split.tail!);
      }
      continue;
    }

    final projected = currentHeight() + (pageBlocks.isEmpty ? 0 : 8) + blockHeight;
    if (pageBlocks.isNotEmpty && projected > maxHeight) {
      flushPage();
      queue.insert(0, block);
      continue;
    }

    pageBlocks.add(block);
  }

  flushPage();

  if (pages.isEmpty) {
    return const [
      SpellCardPage(markdownChunk: '', showInfoBlock: true),
    ];
  }

  return pages;
}

class _BlockSplit {
  const _BlockSplit({this.head, this.tail});

  final MarkdownBlock? head;
  final MarkdownBlock? tail;
}

_BlockSplit _splitBlockToFit(
  MarkdownBlock block, {
  required double maxWidth,
  required double maxHeight,
  required TextStyle bodyStyle,
  required TextStyle headingSmallStyle,
  required TextStyle titleMediumStyle,
  required TextStyle titleLargeStyle,
}) {
  if (block is! ParagraphBlock) {
    return _BlockSplit(head: block);
  }

  final text = _inlinesToPlain(block.inlines);
  if (text.isEmpty) {
    return const _BlockSplit();
  }

  var low = 1;
  var high = text.length;
  var best = 0;

  while (low <= high) {
    final mid = (low + high) ~/ 2;
    final candidate = _splitAtWordBoundary(text, mid);
    final head = ParagraphBlock(
      MarkdownParser.parseInline(candidate),
    );
    final height = _measureBlock(
      head,
      maxWidth: maxWidth,
      bodyStyle: bodyStyle,
      headingSmallStyle: headingSmallStyle,
      titleMediumStyle: titleMediumStyle,
      titleLargeStyle: titleLargeStyle,
    );

    if (height <= maxHeight) {
      best = candidate.length;
      low = mid + 1;
    } else {
      high = mid - 1;
    }
  }

  if (best == 0) {
    return _BlockSplit(head: block);
  }

  final headText = text.substring(0, best).trimRight();
  final tailText = text.substring(best).trimLeft();

  if (headText.isEmpty) {
    return _BlockSplit(head: block);
  }

  final head = ParagraphBlock(MarkdownParser.parseInline(headText));
  if (tailText.isEmpty) {
    return _BlockSplit(head: head);
  }

  final tail = ParagraphBlock(MarkdownParser.parseInline(tailText));
  return _BlockSplit(head: head, tail: tail);
}

String _splitAtWordBoundary(String text, int maxLength) {
  if (maxLength >= text.length) return text;
  var index = maxLength;
  while (index > 0 && text[index - 1] != ' ') {
    index--;
  }
  if (index == 0) return text.substring(0, maxLength);
  return text.substring(0, index);
}

double _measureBlocks(
  List<MarkdownBlock> blocks, {
  required double maxWidth,
  required TextStyle bodyStyle,
  required TextStyle headingSmallStyle,
  required TextStyle titleMediumStyle,
  required TextStyle titleLargeStyle,
}) {
  var total = 0.0;
  for (final block in blocks) {
    total += _measureBlock(
      block,
      maxWidth: maxWidth,
      bodyStyle: bodyStyle,
      headingSmallStyle: headingSmallStyle,
      titleMediumStyle: titleMediumStyle,
      titleLargeStyle: titleLargeStyle,
    );
    total += 8;
  }
  if (blocks.isNotEmpty) total -= 8;
  return total;
}

double _measureBlock(
  MarkdownBlock block, {
  required double maxWidth,
  required TextStyle bodyStyle,
  required TextStyle headingSmallStyle,
  required TextStyle titleMediumStyle,
  required TextStyle titleLargeStyle,
}) {
  return switch (block) {
    HeadingBlock(:final level, :final inlines) => _measureText(
        _inlinesToPlain(inlines),
        maxWidth,
        switch (level) {
          1 => headingSmallStyle,
          2 => titleLargeStyle,
          _ => titleMediumStyle,
        },
      ),
    ParagraphBlock(:final inlines) => _measureText(
        _inlinesToPlain(inlines),
        maxWidth,
        bodyStyle,
      ),
    BulletListBlock(:final items) => items.fold<double>(
        0,
        (sum, item) =>
            sum +
            _measureText('•  ${_inlinesToPlain(item)}', maxWidth, bodyStyle) +
            4,
      ),
    OrderedListBlock(:final items) => items.fold<double>(
        0,
        (sum, item) {
          final index = items.indexOf(item);
          return sum +
              _measureText(
                '${index + 1}.  ${_inlinesToPlain(item)}',
                maxWidth,
                bodyStyle,
              ) +
              4;
        },
      ),
  };
}

double _measureText(String text, double maxWidth, TextStyle style) {
  if (text.isEmpty) return 0;
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: null,
  )..layout(maxWidth: maxWidth);
  return painter.size.height;
}

String _blocksToMarkdown(List<MarkdownBlock> blocks) {
  return blocks.map(_blockToMarkdown).join('\n\n');
}

String _blockToMarkdown(MarkdownBlock block) {
  return switch (block) {
    HeadingBlock(:final level, :final inlines) =>
      '${'#' * level} ${_inlinesToMarkdown(inlines)}',
    ParagraphBlock(:final inlines) => _inlinesToMarkdown(inlines),
    BulletListBlock(:final items) =>
      items.map((item) => '- ${_inlinesToMarkdown(item)}').join('\n'),
    OrderedListBlock(:final items) => items
        .asMap()
        .entries
        .map((entry) => '${entry.key + 1}. ${_inlinesToMarkdown(entry.value)}')
        .join('\n'),
  };
}

String _inlinesToPlain(List<InlineNode> inlines) {
  return inlines.map((node) {
    return switch (node) {
      TextInlineNode(:final text) => text,
      WikiLinkInlineNode(:final link) => link.alias ?? link.id,
    };
  }).join();
}

String _inlinesToMarkdown(List<InlineNode> inlines) {
  return inlines.map((node) {
    return switch (node) {
      TextInlineNode(:final text) => text,
      WikiLinkInlineNode(:final link) => link.serialize(),
    };
  }).join();
}

/// Exposed for tests.
@visibleForTesting
String blocksToMarkdownForTest(List<MarkdownBlock> blocks) =>
    _blocksToMarkdown(blocks);

/// Exposed for tests.
@visibleForTesting
double measureMarkdownHeightForTest(
  String source, {
  required double maxWidth,
  required TextStyle bodyStyle,
  TextStyle? headingSmallStyle,
  TextStyle? titleMediumStyle,
  TextStyle? titleLargeStyle,
}) {
  final document = MarkdownParser.parse(source);
  return _measureBlocks(
    document.blocks,
    maxWidth: maxWidth,
    bodyStyle: bodyStyle,
    headingSmallStyle: headingSmallStyle ?? bodyStyle.copyWith(fontSize: 24),
    titleMediumStyle: titleMediumStyle ?? bodyStyle.copyWith(fontSize: 16),
    titleLargeStyle: titleLargeStyle ?? bodyStyle.copyWith(fontSize: 22),
  );
}
