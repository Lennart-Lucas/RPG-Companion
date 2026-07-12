import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/core/records/typed_record_cache.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';
import 'package:rpg_companion/features/player/classes/models/character_class.dart';
import 'package:rpg_companion/features/player/spells/models/spell.dart';
import 'package:rpg_companion/features/player/spells/services/spell_ai_import.dart';
import 'package:rpg_companion/features/player/spell_tags/models/spell_tag.dart';

RecordCached _cachedRecord(Record record) {
  final now = DateTime.now();
  return RecordCached(
    record: record,
    version: 1,
    origin: RecordOrigin.cache,
    freshness: RecordFreshness.fresh,
    expiresAt: now.add(const Duration(minutes: 5)),
    lastUpdatedAt: now,
    lastFetchedAt: now,
  );
}

CachedQueryResult _cachedQuery(List<RecordId> recordIds) {
  final now = DateTime.now();
  return CachedQueryResult(
    recordIds: recordIds,
    version: 1,
    freshness: RecordFreshness.fresh,
    expiresAt: now.add(const Duration(minutes: 5)),
    lastUpdatedAt: now,
    lastFetchedAt: now,
  );
}

RecordState _recordState() {
  final wizard = CharacterClass(id: '1', name: 'Wizard', caster: true);
  final sorcerer = CharacterClass(id: '2', name: 'Sorcerer', caster: true);
  final damageTag = SpellTag(id: '10', name: 'Damage');
  final phb = ResourceFile(
    id: '20',
    name: 'Player\'s Handbook',
    address: 'phb.pdf',
  );

  TypedRecordCache.instance.put(wizard);
  TypedRecordCache.instance.put(sorcerer);
  TypedRecordCache.instance.put(damageTag);
  TypedRecordCache.instance.put(phb);

  final snapshot = RecordCacheSnapshot(
    offline: false,
    errors: const [],
    records: {
      wizard.id: _cachedRecord(wizard),
      sorcerer.id: _cachedRecord(sorcerer),
      damageTag.id: _cachedRecord(damageTag),
      phb.id: _cachedRecord(phb),
    },
    queries: {
      classesListQuery.queryKey: _cachedQuery([wizard.id, sorcerer.id]),
      spellTagsListQuery.queryKey: _cachedQuery([damageTag.id]),
      filesListQuery.queryKey: _cachedQuery([phb.id]),
    },
  );

  return RecordState(snapshot);
}

void main() {
  tearDown(() {
    TypedRecordCache.instance.clear();
  });

  group('SpellAiImport.toAiJson', () {
    test('includes schema metadata and current values', () {
      final values = {
        SpellFormKeys.name: 'Fireball',
        SpellFormKeys.level: '3rd',
        SpellFormKeys.school: 'evocation',
        SpellFormKeys.castingTime: 1,
        SpellFormKeys.castingType: CastingTypes.action,
        SpellFormKeys.trigger: '',
        SpellFormKeys.duration: 'instantaneous',
        SpellFormKeys.concentration: false,
        SpellFormKeys.range: '120_feet',
        SpellFormKeys.componentVerbal: true,
        SpellFormKeys.componentSomatic: true,
        SpellFormKeys.componentMaterial: true,
        SpellFormKeys.materials: 'A tiny ball of bat guano and sulfur',
        SpellFormKeys.description: 'A bright streak flashes...',
        SpellFormKeys.higherLevels: 'The damage increases by 1d6...',
        SpellFormKeys.classIds: ['1', '2'],
        SpellFormKeys.spellTagIds: ['10'],
        SpellFormKeys.fileId: '20',
      };

      final json = SpellAiImport.toAiJson(values, recordState: _recordState());

      expect(json['_ai'], isNotNull);
      expect(json['_ai']['allowed_values'], isNotNull);
      expect(json['_ai']['allowed_values'][SpellFormKeys.level], SpellLevels.values);
      expect(json['name'], 'Fireball');
      expect(json['class_names'], ['Wizard', 'Sorcerer']);
      expect(json['spell_tag_names'], ['Damage']);
      expect(json['source_file_name'], 'Player\'s Handbook');
    });
  });

  group('SpellAiImport.toAiPromptString', () {
    test('wraps JSON in a ChatGPT prompt', () {
      final prompt = SpellAiImport.toAiPromptString(const {
        SpellFormKeys.name: 'Fireball',
      });

      expect(prompt, startsWith('Fill in this spell:\n\nInto this JSON:\n'));
      expect(prompt, contains('"name": "Fireball"'));
    });
  });

  group('SpellAiImport.parseClipboardJson', () {
    test('parses plain JSON', () {
      const raw = '{"name": "Fireball"}';
      final parsed = SpellAiImport.parseClipboardJson(raw);
      expect(parsed['name'], 'Fireball');
    });

    test('parses fenced JSON from ChatGPT-style output', () {
      const raw = '''
Here is the spell:

```json
{
  "name": "Fireball"
}
```
''';
      final parsed = SpellAiImport.parseClipboardJson(raw);
      expect(parsed['name'], 'Fireball');
    });

    test('parses JSON from full copy prompt', () {
      const raw = '''
Fill in this spell:

Into this JSON:
{
  "name": "Fireball"
}
''';
      final parsed = SpellAiImport.parseClipboardJson(raw);
      expect(parsed['name'], 'Fireball');
    });

    test('throws on empty clipboard', () {
      expect(
        () => SpellAiImport.parseClipboardJson('   '),
        throwsFormatException,
      );
    });
  });

  group('SpellAiImport.toFormValues', () {
    test('imports enums with alias normalization', () {
      final result = SpellAiImport.toFormValues(
        {
          'name': 'Shield',
          'level': 'Cantrip',
          'school': 'Abjuration',
          'casting_type': 'Bonus Action',
          'duration': 'instantaneous',
          'range': 'self',
        },
        _recordState(),
      );

      expect(result.warnings, isEmpty);
      expect(result.values[SpellFormKeys.name], 'Shield');
      expect(result.values[SpellFormKeys.level], 'cantrip');
      expect(result.values[SpellFormKeys.school], 'abjuration');
      expect(result.values[SpellFormKeys.castingType], CastingTypes.bonusAction);
    });

    test('resolves class and tag names to ids', () {
      final result = SpellAiImport.toFormValues(
        {
          'class_names': ['Wizard', 'Sorcerer'],
          'spell_tag_names': ['Damage'],
          'source_file_name': 'Player\'s Handbook',
        },
        _recordState(),
      );

      expect(result.warnings, isEmpty);
      expect(result.values[SpellFormKeys.classIds], ['1', '2']);
      expect(result.values[SpellFormKeys.spellTagIds], ['10']);
      expect(result.values[SpellFormKeys.fileId], '20');
    });

    test('warns on unknown names and invalid enums', () {
      final result = SpellAiImport.toFormValues(
        {
          'school': 'invalid_school',
          'class_names': ['Wizard', 'Druid'],
          'source_file_name': 'Missing Book',
        },
        _recordState(),
      );

      expect(result.warnings, contains('Skipped school: invalid value "invalid_school"'));
      expect(result.warnings, contains('Unknown class: "Druid"'));
      expect(result.warnings, contains('Unknown source file: "Missing Book"'));
      expect(result.values[SpellFormKeys.classIds], ['1']);
      expect(result.values.containsKey(SpellFormKeys.school), isFalse);
    });

    test('partial import only includes recognized keys', () {
      final result = SpellAiImport.toFormValues(
        {
          'name': 'Mage Hand',
          'unknown_field': 'ignored',
        },
        _recordState(),
      );

      expect(result.values.keys, ['name']);
      expect(result.values[SpellFormKeys.name], 'Mage Hand');
    });
  });
}
