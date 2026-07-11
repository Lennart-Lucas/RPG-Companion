import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_data.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_layout.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_paginator.dart';

void main() {
  const bodyStyle = TextStyle(fontSize: 12, height: 1.4);
  const headingSmallStyle = TextStyle(fontSize: 20, height: 1.2);
  const titleLargeStyle = TextStyle(fontSize: 18, height: 1.2);
  const titleMediumStyle = TextStyle(fontSize: 14, height: 1.2);
  const maxWidth = SpellCardLayout.bodyContentWidth;

  List<SpellCardPage> paginate(String source) {
    return paginateSpellBody(
      source,
      maxWidth: maxWidth,
      bodyStyle: bodyStyle,
      headingSmallStyle: headingSmallStyle,
      titleMediumStyle: titleMediumStyle,
      titleLargeStyle: titleLargeStyle,
    );
  }

  group('SpellCardLayout', () {
    test('uses MTG playing card aspect ratio', () {
      expect(
        SpellCardLayout.width / SpellCardLayout.height,
        closeTo(2.5 / 3.5, 0.001),
      );
    });
  });

  group('SpellCardData.combineBodyMarkdown', () {
    test('returns empty when both fields empty', () {
      expect(
        SpellCardData.combineBodyMarkdown(description: '', higherLevels: ''),
        '',
      );
    });

    test('returns description only when higher levels empty', () {
      expect(
        SpellCardData.combineBodyMarkdown(
          description: 'Main text',
          higherLevels: '',
        ),
        'Main text',
      );
    });

    test('includes higher levels heading when both present', () {
      final combined = SpellCardData.combineBodyMarkdown(
        description: 'Main text',
        higherLevels: 'Scaled damage',
      );
      expect(combined, contains('Main text'));
      expect(combined, contains('## At Higher Levels'));
      expect(combined, contains('Scaled damage'));
    });
  });

  group('paginateSpellBody', () {
    test('empty source yields single page with info block', () {
      final pages = paginate('');
      expect(pages, hasLength(1));
      expect(pages.first.showInfoBlock, isTrue);
      expect(pages.first.markdownChunk, isEmpty);
    });

    test('short text yields single page with info block', () {
      final pages = paginate('A brief spell effect.');
      expect(pages, hasLength(1));
      expect(pages.first.showInfoBlock, isTrue);
      expect(pages.first.markdownChunk, contains('brief spell effect'));
    });

    test('long text yields multiple pages without info block on continuation', () {
      final paragraph = List.filled(80, 'word').join(' ');
      final pages = paginate('$paragraph\n\n$paragraph\n\n$paragraph');

      expect(pages.length, greaterThan(1));
      expect(pages.first.showInfoBlock, isTrue);
      expect(pages.skip(1).every((page) => !page.showInfoBlock), isTrue);
    });

    test('combined description and higher levels can paginate with heading', () {
      final combined = SpellCardData.combineBodyMarkdown(
        description: List.filled(120, 'damage').join(' '),
        higherLevels: 'When cast using a slot of 9th level or higher.',
      );
      final pages = paginate(combined);

      expect(pages.length, greaterThan(1));
      final allText = pages.map((page) => page.markdownChunk).join('\n');
      expect(allText, contains('At Higher Levels'));
    });
  });
}
