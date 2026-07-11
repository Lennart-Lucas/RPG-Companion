import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_companion/core/markdown/linkable_record_registry.dart';
import 'package:rpg_companion/core/markdown/markdown_document.dart';
import 'package:rpg_companion/core/markdown/markdown_parser.dart';
import 'package:rpg_companion/core/markdown/record_link_index.dart';

void main() {
  group('MarkdownParser.parseInline', () {
    List<InlineNode> parse(String text) => MarkdownParser.parseInline(text);

    test('parses bold text', () {
      final nodes = parse('**bold**');
      expect(nodes, hasLength(1));
      expect(nodes.first, isA<TextInlineNode>());
      final textNode = nodes.first as TextInlineNode;
      expect(textNode.text, 'bold');
      expect(textNode.styles, contains(InlineStyle.bold));
    });

    test('parses italic text', () {
      final nodes = parse('_italic_');
      expect(nodes, hasLength(1));
      final textNode = nodes.first as TextInlineNode;
      expect(textNode.text, 'italic');
      expect(textNode.styles, contains(InlineStyle.italic));
    });

    test('parses underline via ++ delimiter', () {
      final nodes = parse('++underlined++');
      expect(nodes, hasLength(1));
      final textNode = nodes.first as TextInlineNode;
      expect(textNode.text, 'underlined');
      expect(textNode.styles, contains(InlineStyle.underline));
    });

    test('parses wiki links in text', () {
      final nodes = parse('See [[authors:1|Author]] here');
      expect(nodes, hasLength(3));
      expect(nodes[0], isA<TextInlineNode>());
      expect((nodes[0] as TextInlineNode).text, 'See ');
      expect(nodes[1], isA<WikiLinkInlineNode>());
      expect((nodes[1] as WikiLinkInlineNode).link.type, 'authors');
      expect(nodes[2], isA<TextInlineNode>());
      expect((nodes[2] as TextInlineNode).text, ' here');
    });
  });

  group('RecordLinkIndex.search', () {
    final entries = <IndexedLinkableRecord>[
      IndexedLinkableRecord(
        type: 'authors',
        id: '1',
        name: 'Jane Doe',
        typeLabel: 'Author',
      ),
      IndexedLinkableRecord(
        type: 'files',
        id: '2',
        name: 'Player Handbook',
        typeLabel: 'File',
      ),
      IndexedLinkableRecord(
        type: 'classes',
        id: '3',
        name: 'Fighter',
        typeLabel: 'Class',
      ),
    ];

    test('returns all entries for empty query', () {
      expect(RecordLinkIndex.search(entries, ''), entries);
      expect(RecordLinkIndex.search(entries, '   '), entries);
    });

    test('filters by record name', () {
      final results = RecordLinkIndex.search(entries, 'hand');
      expect(results, hasLength(1));
      expect(results.single.name, 'Player Handbook');
    });

    test('filters by type label', () {
      final results = RecordLinkIndex.search(entries, 'class');
      expect(results, hasLength(1));
      expect(results.single.name, 'Fighter');
    });
  });

  group('wiki-link autocomplete helpers', () {
    test('detectWikiLinkAutocomplete finds unfinished token', () {
      const text = 'Notes [[auth';
      final context = detectWikiLinkAutocomplete(text, text.length);
      expect(context, isNotNull);
      expect(context!.tokenStart, 6);
      expect(context.query, 'auth');
    });

    test('detectWikiLinkAutocomplete ignores completed links', () {
      const text = 'See [[authors:1|Jane]]';
      expect(detectWikiLinkAutocomplete(text, text.length), isNull);
    });

    test('insertWikiLink replaces partial token with canonical link', () {
      const text = 'See [[auth';
      const cursor = text.length;
      const context = WikiLinkAutocompleteContext(tokenStart: 4, query: 'auth');
      const record = IndexedLinkableRecord(
        type: 'authors',
        id: '7',
        name: 'Jane Doe',
        typeLabel: 'Author',
      );

      final updated = insertWikiLink(
        text: text,
        tokenStart: context.tokenStart,
        cursorOffset: cursor,
        record: record,
      );

      expect(updated, 'See [[authors:7|Jane Doe]]');
      expect(
        cursorAfterWikiLinkInsert(context.tokenStart, record),
        'See [[authors:7|Jane Doe]]'.length,
      );
    });
  });
}
