import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_companion/features/player/spells/models/spell.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_builder.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_data.dart';

Spell _sampleSpell({String? description, String? higherLevels}) {
  return Spell(
    id: 'spell-1',
    name: 'Fireball',
    level: '3rd',
    school: 'evocation',
    castingTime: 1,
    castingType: CastingTypes.action,
    duration: 'instantaneous',
    range: '150 feet',
    componentVerbal: true,
    componentSomatic: true,
    componentMaterial: true,
    materials: 'a tiny ball of bat guano and sulfur',
    description: description,
    higherLevels: higherLevels,
    classIds: const ['wizard-id'],
  );
}

SpellCardData _sampleData({Spell? spell, List<String> tagNames = const []}) {
  return SpellCardData(
    spell: spell ?? _sampleSpell(),
    classNames: const ['Wizard'],
    tagNames: tagNames,
  );
}

void main() {
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
      expect(combined, contains('**At Higher Levels:**'));
      expect(combined, contains('Scaled damage'));
    });
  });

  group('SpellCardData mechanics lines', () {
    test('durationLine includes concentration suffix', () {
      final spell = Spell(
        id: 'spell-1',
        name: 'Hold Person',
        level: '2nd',
        school: 'enchantment',
        castingTime: 1,
        castingType: CastingTypes.action,
        duration: '1 minute',
        concentration: true,
        range: '60 feet',
      );
      final data = _sampleData(spell: spell);
      expect(data.durationLine, 'Up to 1 minute (C)');
    });

    test('summaryLine includes tags and part indicator', () {
      final data = _sampleData(tagNames: const ['Damage']);
      expect(
        data.summaryLine(continuationIndex: 2, continuationTotal: 3),
        contains('Damage'),
      );
      expect(
        data.summaryLine(continuationIndex: 2, continuationTotal: 3),
        contains('Part 2/3'),
      );
    });
  });

  group('buildSpellCards', () {
    test('empty body yields single card with mechanics', () {
      final cards = buildSpellCards(
        data: _sampleData(),
        bodyMarkdown: '',
      );

      expect(cards, hasLength(1));
      expect(cards.first.showMechanics, isTrue);
      expect(cards.first.continuationIndex, isNull);
      expect(cards.first.continuationTotal, isNull);
    });

    test('short text yields single card with mechanics', () {
      final cards = buildSpellCards(
        data: _sampleData(),
        bodyMarkdown: 'A brief spell effect.',
      );

      expect(cards, hasLength(1));
      expect(cards.first.showMechanics, isTrue);
      expect(cards.first.bodyMarkdown, contains('brief spell effect'));
    });

    test('long text yields multiple cards without mechanics on continuation', () {
      final paragraph = List.filled(200, 'word').join(' ');
      final body = '$paragraph\n\n$paragraph\n\n$paragraph';
      final cards = buildSpellCards(
        data: _sampleData(),
        bodyMarkdown: body,
      );

      expect(cards.length, greaterThan(1));
      expect(cards.first.showMechanics, isTrue);
      expect(cards.skip(1).every((card) => !card.showMechanics), isTrue);
    });

    test('multi-page cards include part indicator', () {
      final paragraph = List.filled(200, 'word').join(' ');
      final body = '$paragraph\n\n$paragraph\n\n$paragraph';
      final cards = buildSpellCards(
        data: _sampleData(),
        bodyMarkdown: body,
      );

      expect(cards.first.continuationIndex, 1);
      expect(cards.first.continuationTotal, cards.length);
      expect(cards.last.continuationIndex, cards.length);
    });

    test('combined description and higher levels can paginate', () {
      final combined = SpellCardData.combineBodyMarkdown(
        description: List.filled(300, 'damage').join(' '),
        higherLevels: 'When cast using a slot of 9th level or higher.',
      );
      final cards = buildSpellCards(
        data: _sampleData(),
        bodyMarkdown: combined,
      );

      expect(cards.length, greaterThan(1));
      final allText = cards.map((card) => card.bodyMarkdown).join('\n');
      expect(allText, contains('At Higher Levels'));
    });
  });
}
