import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_companion/features/player/spells/widgets/mtg/card_text_pagination.dart';

void main() {
  group('paginateCardBodyText', () {
    test('empty input yields single empty page', () {
      expect(paginateCardBodyText(''), ['']);
      expect(paginateCardBodyText('   '), ['']);
    });

    test('short text yields single page', () {
      expect(paginateCardBodyText('A brief spell effect.'), [
        'A brief spell effect.',
      ]);
    });

    test('splits long text into multiple pages under maxCharsPerCard', () {
      final paragraph = List.filled(200, 'word').join(' ');
      final pages = paginateCardBodyText('$paragraph\n\n$paragraph\n\n$paragraph');

      expect(pages.length, greaterThan(1));
      for (final page in pages) {
        expect(page.length, lessThanOrEqualTo(1300));
      }
      expect(pages.join(' '), contains('word'));
    });

    test('prefers breaking at newlines when possible', () {
      final first = List.filled(1400, 'a').join('');
      final second = 'Second paragraph starts here.';
      final pages = paginateCardBodyText('$first\n\n$second');

      expect(pages.length, greaterThan(1));
      expect(pages.first, isNot(contains('Second paragraph')));
      expect(pages.last, contains('Second paragraph'));
    });

    test('prefers breaking at sentence boundaries when available', () {
      final sentences = List.generate(120, (i) => 'Sentence number $i.').join(' ');
      final pages = paginateCardBodyText(sentences);

      expect(pages.length, greaterThan(1));
      expect(pages.first.trimRight(), endsWith('.'));
      expect(pages.last, contains('Sentence number'));
    });
  });
}
