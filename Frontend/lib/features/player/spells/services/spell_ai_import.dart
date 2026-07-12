import 'dart:convert';

import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/features/dm_tools/resources/services/resource_record_resolver.dart';
import 'package:rpg_companion/features/player/services/player_record_resolver.dart';
import 'package:rpg_companion/features/player/spells/models/spell.dart';

/// Result of importing spell JSON from the clipboard.
class SpellAiImportResult {
  const SpellAiImportResult({
    required this.values,
    required this.warnings,
  });

  final Map<String, dynamic> values;
  final List<String> warnings;
}

abstract final class SpellAiImport {
  SpellAiImport._();

  static const _aiKey = '_ai';
  static const _classNamesKey = 'class_names';
  static const _spellTagNamesKey = 'spell_tag_names';
  static const _sourceFileNameKey = 'source_file_name';

  static const _instructions =
      'Fill every field from the spell stat block. Use only allowed enum values.';

  /// Builds an AI-friendly JSON map from current form values.
  static Map<String, dynamic> toAiJson(
    Map<String, dynamic> values, {
    RecordState? recordState,
  }) {
    final payload = <String, dynamic>{
      _aiKey: _aiMetadata(),
      SpellFormKeys.name: _stringValue(values[SpellFormKeys.name]),
      SpellFormKeys.level: _stringValue(values[SpellFormKeys.level]),
      SpellFormKeys.school: _stringValue(values[SpellFormKeys.school]),
      SpellFormKeys.castingTime: _intValue(values[SpellFormKeys.castingTime]) ?? 1,
      SpellFormKeys.castingType: _stringValue(values[SpellFormKeys.castingType]),
      SpellFormKeys.trigger: _stringValue(values[SpellFormKeys.trigger]),
      SpellFormKeys.duration: _stringValue(values[SpellFormKeys.duration]),
      SpellFormKeys.concentration:
          values[SpellFormKeys.concentration] as bool? ?? false,
      SpellFormKeys.range: _stringValue(values[SpellFormKeys.range]),
      SpellFormKeys.componentVerbal:
          values[SpellFormKeys.componentVerbal] as bool? ?? false,
      SpellFormKeys.componentSomatic:
          values[SpellFormKeys.componentSomatic] as bool? ?? false,
      SpellFormKeys.componentMaterial:
          values[SpellFormKeys.componentMaterial] as bool? ?? false,
      SpellFormKeys.materials: _stringValue(values[SpellFormKeys.materials]),
      SpellFormKeys.description: _stringValue(values[SpellFormKeys.description]),
      SpellFormKeys.higherLevels:
          _stringValue(values[SpellFormKeys.higherLevels]),
      _classNamesKey: _resolveClassNames(values, recordState),
      _spellTagNamesKey: _resolveSpellTagNames(values, recordState),
      _sourceFileNameKey: _resolveSourceFileName(values, recordState),
    };

    return payload;
  }

  /// Encodes [toAiJson] output as pretty-printed JSON for the clipboard.
  static String toAiJsonString(
    Map<String, dynamic> values, {
    RecordState? recordState,
  }) {
    return const JsonEncoder.withIndent('  ').convert(
      toAiJson(values, recordState: recordState),
    );
  }

  /// Full ChatGPT prompt with the JSON template appended.
  static String toAiPromptString(
    Map<String, dynamic> values, {
    RecordState? recordState,
  }) {
    final json = toAiJsonString(values, recordState: recordState);
    return 'Fill in this spell:\n\nInto this JSON:\n$json';
  }

  /// Parses clipboard text, stripping optional markdown code fences.
  static Map<String, dynamic> parseClipboardJson(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Clipboard is empty');
    }

    final extracted = _extractJson(trimmed);
    final decoded = jsonDecode(extracted);
    if (decoded is! Map) {
      throw const FormatException('Expected a JSON object');
    }

    return Map<String, dynamic>.from(decoded);
  }

  /// Converts parsed AI JSON into form values, resolving names to IDs.
  static SpellAiImportResult toFormValues(
    Map<String, dynamic> json,
    RecordState recordState,
  ) {
    final warnings = <String>[];
    final values = <String, dynamic>{};

    _importString(json, SpellFormKeys.name, values, warnings);
    _importEnum(
      json,
      SpellFormKeys.level,
      SpellLevels.values,
      values,
      warnings,
      aliases: _levelAliases,
    );
    _importEnum(
      json,
      SpellFormKeys.school,
      SpellSchools.values,
      values,
      warnings,
    );
    _importInt(json, SpellFormKeys.castingTime, values, warnings);
    _importEnum(
      json,
      SpellFormKeys.castingType,
      CastingTypes.values,
      values,
      warnings,
      aliases: _castingTypeAliases,
    );
    _importString(json, SpellFormKeys.trigger, values, warnings);
    _importEnum(
      json,
      SpellFormKeys.duration,
      SpellDurations.values,
      values,
      warnings,
    );
    _importBool(json, SpellFormKeys.concentration, values, warnings);
    _importEnum(
      json,
      SpellFormKeys.range,
      SpellRanges.values,
      values,
      warnings,
    );
    _importBool(json, SpellFormKeys.componentVerbal, values, warnings);
    _importBool(json, SpellFormKeys.componentSomatic, values, warnings);
    _importBool(json, SpellFormKeys.componentMaterial, values, warnings);
    _importString(json, SpellFormKeys.materials, values, warnings);
    _importString(json, SpellFormKeys.description, values, warnings);
    _importString(json, SpellFormKeys.higherLevels, values, warnings);

    _importClassNames(json, recordState, values, warnings);
    _importSpellTagNames(json, recordState, values, warnings);
    _importSourceFileName(json, recordState, values, warnings);

    return SpellAiImportResult(values: values, warnings: warnings);
  }

  static Map<String, dynamic> _aiMetadata() {
    return {
      'version': 1,
      'instructions': _instructions,
      'allowed_values': {
        SpellFormKeys.level: SpellLevels.values,
        SpellFormKeys.school: SpellSchools.values,
        SpellFormKeys.castingType: CastingTypes.values,
        SpellFormKeys.duration: SpellDurations.values,
        SpellFormKeys.range: SpellRanges.values,
      },
    };
  }

  static String _extractJson(String raw) {
    final fenceMatch = RegExp(
      r'```(?:json)?\s*\n([\s\S]*?)\n```',
      multiLine: true,
    ).firstMatch(raw);
    if (fenceMatch != null) {
      return fenceMatch.group(1)!.trim();
    }

    const marker = 'Into this JSON:';
    final markerIndex = raw.indexOf(marker);
    if (markerIndex != -1) {
      final afterMarker = raw.substring(markerIndex + marker.length).trim();
      if (afterMarker.isNotEmpty) {
        return afterMarker;
      }
    }

    final object = _extractJsonObject(raw);
    if (object != null) {
      return object;
    }

    return raw;
  }

  static String? _extractJsonObject(String raw) {
    final start = raw.indexOf('{');
    if (start == -1) return null;

    var depth = 0;
    for (var i = start; i < raw.length; i++) {
      final char = raw[i];
      if (char == '{') {
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0) {
          return raw.substring(start, i + 1);
        }
      }
    }
    return null;
  }

  static String _stringValue(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static int? _intValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static List<String> _resolveClassNames(
    Map<String, dynamic> values,
    RecordState? recordState,
  ) {
    if (recordState == null) return const [];
    final ids = _idList(values[SpellFormKeys.classIds]);
    if (ids.isEmpty) return const [];

    final classes = resolveClasses(recordState, classesListQuery);
    final names = <String>[];
    for (final id in ids) {
      for (final characterClass in classes) {
        if (characterClass.id == id) {
          names.add(characterClass.name);
          break;
        }
      }
    }
    return names;
  }

  static List<String> _resolveSpellTagNames(
    Map<String, dynamic> values,
    RecordState? recordState,
  ) {
    if (recordState == null) return const [];
    final ids = _idList(values[SpellFormKeys.spellTagIds]);
    if (ids.isEmpty) return const [];

    final tags = resolveSpellTags(recordState, spellTagsListQuery);
    final names = <String>[];
    for (final id in ids) {
      for (final tag in tags) {
        if (tag.id == id) {
          names.add(tag.name);
          break;
        }
      }
    }
    return names;
  }

  static String? _resolveSourceFileName(
    Map<String, dynamic> values,
    RecordState? recordState,
  ) {
    if (recordState == null) return null;
    final fileId = _stringValue(values[SpellFormKeys.fileId]).trim();
    if (fileId.isEmpty) return null;

    final files = resolveResourceFiles(recordState, filesListQuery);
    for (final file in files) {
      if (file.id == fileId) return file.name;
    }
    return null;
  }

  static List<String> _idList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  static void _importString(
    Map<String, dynamic> json,
    String key,
    Map<String, dynamic> values,
    List<String> warnings,
  ) {
    if (!json.containsKey(key)) return;
    final raw = json[key];
    if (raw == null) {
      values[key] = '';
      return;
    }
    if (raw is! String && raw is! num && raw is! bool) {
      warnings.add('Skipped $key: expected a string');
      return;
    }
    values[key] = raw.toString();
  }

  static void _importInt(
    Map<String, dynamic> json,
    String key,
    Map<String, dynamic> values,
    List<String> warnings,
  ) {
    if (!json.containsKey(key)) return;
    final parsed = _intValue(json[key]);
    if (parsed == null) {
      warnings.add('Skipped $key: expected a number');
      return;
    }
    values[key] = parsed;
  }

  static void _importBool(
    Map<String, dynamic> json,
    String key,
    Map<String, dynamic> values,
    List<String> warnings,
  ) {
    if (!json.containsKey(key)) return;
    final raw = json[key];
    if (raw is bool) {
      values[key] = raw;
      return;
    }
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      if (normalized == 'true') {
        values[key] = true;
        return;
      }
      if (normalized == 'false') {
        values[key] = false;
        return;
      }
    }
    warnings.add('Skipped $key: expected a boolean');
  }

  static void _importEnum(
    Map<String, dynamic> json,
    String key,
    List<String> allowed,
    Map<String, dynamic> values,
    List<String> warnings, {
    Map<String, String> aliases = const {},
  }) {
    if (!json.containsKey(key)) return;
    final raw = json[key];
    if (raw == null) return;

    final normalized = _normalizeEnum(raw.toString(), allowed, aliases);
    if (normalized == null) {
      warnings.add('Skipped $key: invalid value "$raw"');
      return;
    }
    values[key] = normalized;
  }

  static String? _normalizeEnum(
    String raw,
    List<String> allowed,
    Map<String, String> aliases,
  ) {
    final trimmed = raw.trim();
    if (allowed.contains(trimmed)) return trimmed;

    final lower = trimmed.toLowerCase();
    for (final value in allowed) {
      if (value.toLowerCase() == lower) return value;
    }

    final aliasKey = lower.replaceAll(RegExp(r'[\s-]+'), '_');
    if (aliases.containsKey(aliasKey)) {
      return aliases[aliasKey];
    }

    return null;
  }

  static void _importClassNames(
    Map<String, dynamic> json,
    RecordState recordState,
    Map<String, dynamic> values,
    List<String> warnings,
  ) {
    if (!json.containsKey(_classNamesKey)) return;
    final raw = json[_classNamesKey];
    if (raw == null) {
      values[SpellFormKeys.classIds] = <String>[];
      return;
    }
    if (raw is! List) {
      warnings.add('Skipped $_classNamesKey: expected an array');
      return;
    }

    final classes = resolveClasses(recordState, classesListQuery);
    final byName = {
      for (final characterClass in classes)
        characterClass.name.toLowerCase(): characterClass.id,
    };

    final resolved = <String>[];
    for (final item in raw) {
      final name = item?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      final id = byName[name.toLowerCase()];
      if (id == null) {
        warnings.add('Unknown class: "$name"');
        continue;
      }
      if (!resolved.contains(id)) resolved.add(id);
    }
    values[SpellFormKeys.classIds] = resolved;
  }

  static void _importSpellTagNames(
    Map<String, dynamic> json,
    RecordState recordState,
    Map<String, dynamic> values,
    List<String> warnings,
  ) {
    if (!json.containsKey(_spellTagNamesKey)) return;
    final raw = json[_spellTagNamesKey];
    if (raw == null) {
      values[SpellFormKeys.spellTagIds] = <String>[];
      return;
    }
    if (raw is! List) {
      warnings.add('Skipped $_spellTagNamesKey: expected an array');
      return;
    }

    final tags = resolveSpellTags(recordState, spellTagsListQuery);
    final byName = {
      for (final tag in tags) tag.name.toLowerCase(): tag.id,
    };

    final resolved = <String>[];
    for (final item in raw) {
      final name = item?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      final id = byName[name.toLowerCase()];
      if (id == null) {
        warnings.add('Unknown spell tag: "$name"');
        continue;
      }
      if (!resolved.contains(id)) resolved.add(id);
    }
    values[SpellFormKeys.spellTagIds] = resolved;
  }

  static void _importSourceFileName(
    Map<String, dynamic> json,
    RecordState recordState,
    Map<String, dynamic> values,
    List<String> warnings,
  ) {
    if (!json.containsKey(_sourceFileNameKey)) return;
    final raw = json[_sourceFileNameKey];
    if (raw == null) {
      values[SpellFormKeys.fileId] = '';
      return;
    }

    final name = raw.toString().trim();
    if (name.isEmpty) {
      values[SpellFormKeys.fileId] = '';
      return;
    }

    final files = resolveResourceFiles(recordState, filesListQuery);
    for (final file in files) {
      if (file.name.toLowerCase() == name.toLowerCase()) {
        values[SpellFormKeys.fileId] = file.id;
        return;
      }
    }
    warnings.add('Unknown source file: "$name"');
  }

  static const _levelAliases = {
    '0': 'cantrip',
    'cantrip': 'cantrip',
    '0th': 'cantrip',
    '1': '1st',
    '1st_level': '1st',
    '2': '2nd',
    '2nd_level': '2nd',
    '3': '3rd',
    '3rd_level': '3rd',
    '4': '4th',
    '4th_level': '4th',
    '5': '5th',
    '5th_level': '5th',
    '6': '6th',
    '6th_level': '6th',
    '7': '7th',
    '7th_level': '7th',
    '8': '8th',
    '8th_level': '8th',
    '9': '9th',
    '9th_level': '9th',
  };

  static const _castingTypeAliases = {
    'bonus_action': CastingTypes.bonusAction,
    'bonus': CastingTypes.bonusAction,
    'action': CastingTypes.action,
    'reaction': CastingTypes.reaction,
    'minute(s)': CastingTypes.minutes,
    'minutes': CastingTypes.minutes,
    'hour(s)': CastingTypes.hours,
    'hours': CastingTypes.hours,
  };
}
