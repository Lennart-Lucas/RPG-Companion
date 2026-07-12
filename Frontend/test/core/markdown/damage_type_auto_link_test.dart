import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_companion/core/markdown/damage_type_auto_link.dart';
import 'package:rpg_companion/features/player/damage_types/models/damage_type.dart';

void main() {
  group('linkDamageTypeMentions', () {
    final fire = DamageType(id: '1', name: 'Fire');
    final cold = DamageType(id: '2', name: 'Cold');

    test('links exact whole-word damage type names', () {
      final output = linkDamageTypeMentions(
        'The target takes Fire damage.',
        [fire],
      );

      expect(output, 'The target takes [[damage_types:1]] damage.');
    });

    test('does not link partial or differently cased names', () {
      final output = linkDamageTypeMentions(
        'fire Fireball and FIRE',
        [fire],
      );

      expect(output, 'fire Fireball and FIRE');
    });

    test('skips mentions inside existing wiki links', () {
      final output = linkDamageTypeMentions(
        'Already linked [[damage_types:1|Fire]] and fresh Fire.',
        [fire],
      );

      expect(
        output,
        'Already linked [[damage_types:1|Fire]] and fresh [[damage_types:1]].',
      );
    });

    test('links multiple damage types in one pass', () {
      final output = linkDamageTypeMentions(
        'Deals Fire and Cold damage.',
        [fire, cold],
      );

      expect(
        output,
        'Deals [[damage_types:1]] and [[damage_types:2]] damage.',
      );
    });

    test('returns original text when no damage types are provided', () {
      const text = 'Deals Fire damage.';
      expect(linkDamageTypeMentions(text, const []), text);
    });
  });
}
