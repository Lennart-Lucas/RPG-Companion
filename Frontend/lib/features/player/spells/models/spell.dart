import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:rpg_companion/core/records/record_json_utils.dart';
import 'package:rpg_companion/core/records/rpg_record.dart';
import 'package:rpg_companion/features/player/spells/models/spell_enums.dart';

export 'package:rpg_companion/features/player/spells/models/spell_enums.dart';

class Spell extends RpgRecord {
  @override
  final RecordId id;
  @override
  RecordType get recordType => 'spells';
  @override
  final String name;
  final String? fileId;
  final String level;
  final String school;
  final int castingTime;
  final String castingType;
  final String? trigger;
  final String duration;
  final bool concentration;
  final String range;
  final bool componentVerbal;
  final bool componentSomatic;
  final bool componentMaterial;
  final String? materials;
  final String? description;
  final String? higherLevels;
  final List<String> classIds;
  final List<String> spellTagIds;

  Spell({
    required this.id,
    required this.name,
    this.fileId,
    required this.level,
    required this.school,
    required this.castingTime,
    required this.castingType,
    this.trigger,
    required this.duration,
    this.concentration = false,
    required this.range,
    this.componentVerbal = false,
    this.componentSomatic = false,
    this.componentMaterial = false,
    this.materials,
    this.description,
    this.higherLevels,
    this.classIds = const [],
    this.spellTagIds = const [],
  });

  factory Spell.fromJson(Map<String, dynamic> json) {
    final data = RpgRecord.unwrapJson(json);
    return Spell(
      id: RpgRecord.idFromJson(data),
      name: RpgRecord.nameFromJson(data),
      fileId: RecordJsonUtils.parentIdFromJson(data['file_id']),
      level: data['level'] as String? ?? SpellLevels.values.first,
      school: data['school'] as String? ?? SpellSchools.values.first,
      castingTime: data['casting_time'] as int? ?? 1,
      castingType: data['casting_type'] as String? ?? CastingTypes.action,
      trigger: _nullableString(data['trigger']),
      duration: data['duration'] as String? ?? SpellDurations.values.first,
      concentration: data['concentration'] as bool? ?? false,
      range: data['range'] as String? ?? SpellRanges.values.first,
      componentVerbal: data['component_verbal'] as bool? ?? false,
      componentSomatic: data['component_somatic'] as bool? ?? false,
      componentMaterial: data['component_material'] as bool? ?? false,
      materials: _nullableString(data['materials']),
      description: _nullableString(data['description']),
      higherLevels: _nullableString(data['higher_levels']),
      classIds: _idListFromJson(data['class_ids']),
      spellTagIds: _idListFromJson(data['spell_tag_ids']),
    );
  }

  factory Spell.fromFormValues(
    Map<String, dynamic> values, {
    String? id,
  }) {
    return Spell(
      id: id ?? 'temp-${DateTime.now().millisecondsSinceEpoch}',
      name: (values[SpellFormKeys.name] as String? ?? '').trim(),
      fileId: RecordJsonUtils.parentIdFromFormValue(
        values[SpellFormKeys.fileId],
      ),
      level: values[SpellFormKeys.level] as String? ?? SpellLevels.values.first,
      school:
          values[SpellFormKeys.school] as String? ?? SpellSchools.values.first,
      castingTime: _intFromForm(values[SpellFormKeys.castingTime]) ?? 1,
      castingType:
          values[SpellFormKeys.castingType] as String? ?? CastingTypes.action,
      trigger: _nullableString(values[SpellFormKeys.trigger]),
      duration: values[SpellFormKeys.duration] as String? ??
          SpellDurations.values.first,
      concentration: values[SpellFormKeys.concentration] as bool? ?? false,
      range: values[SpellFormKeys.range] as String? ?? SpellRanges.values.first,
      componentVerbal: values[SpellFormKeys.componentVerbal] as bool? ?? false,
      componentSomatic: values[SpellFormKeys.componentSomatic] as bool? ?? false,
      componentMaterial:
          values[SpellFormKeys.componentMaterial] as bool? ?? false,
      materials: _nullableString(values[SpellFormKeys.materials]),
      description: _nullableString(values[SpellFormKeys.description]),
      higherLevels: _nullableString(values[SpellFormKeys.higherLevels]),
      classIds: _idListFromForm(values[SpellFormKeys.classIds]),
      spellTagIds: _idListFromForm(values[SpellFormKeys.spellTagIds]),
    );
  }

  Map<String, dynamic> toFormValues() => {
        SpellFormKeys.name: name,
        SpellFormKeys.fileId: fileId ?? '',
        SpellFormKeys.level: level,
        SpellFormKeys.school: school,
        SpellFormKeys.castingTime: castingTime,
        SpellFormKeys.castingType: castingType,
        SpellFormKeys.trigger: trigger ?? '',
        SpellFormKeys.duration: duration,
        SpellFormKeys.concentration: concentration,
        SpellFormKeys.range: range,
        SpellFormKeys.componentVerbal: componentVerbal,
        SpellFormKeys.componentSomatic: componentSomatic,
        SpellFormKeys.componentMaterial: componentMaterial,
        SpellFormKeys.materials: materials ?? '',
        SpellFormKeys.description: description ?? '',
        SpellFormKeys.higherLevels: higherLevels ?? '',
        SpellFormKeys.classIds: List<String>.from(classIds),
        SpellFormKeys.spellTagIds: List<String>.from(spellTagIds),
      };

  bool get _isTempId => RecordJsonUtils.isTempId(id);

  @override
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'level': level,
      'school': school,
      'casting_time': castingTime,
      'casting_type': castingType,
      'duration': duration,
      'concentration': concentration,
      'range': range,
      'component_verbal': componentVerbal,
      'component_somatic': componentSomatic,
      'component_material': componentMaterial,
      'class_ids': classIds.map((id) => int.tryParse(id) ?? id).toList(),
      'spell_tag_ids':
          spellTagIds.map((id) => int.tryParse(id) ?? id).toList(),
    };

    if (!_isTempId) {
      map['id'] = int.tryParse(id) ?? id;
    }

    if (fileId != null && fileId!.isNotEmpty) {
      map['file_id'] = int.tryParse(fileId!) ?? fileId;
    } else if (!_isTempId) {
      map['file_id'] = null;
    }

    if (castingType == CastingTypes.reaction &&
        trigger != null &&
        trigger!.isNotEmpty) {
      map['trigger'] = trigger;
    } else if (!_isTempId) {
      map['trigger'] = null;
    }

    if (componentMaterial && materials != null && materials!.isNotEmpty) {
      map['materials'] = materials;
    } else if (!_isTempId) {
      map['materials'] = null;
    }

    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    } else if (!_isTempId) {
      map['description'] = null;
    }

    if (higherLevels != null && higherLevels!.isNotEmpty) {
      map['higher_levels'] = higherLevels;
    } else if (!_isTempId) {
      map['higher_levels'] = null;
    }

    return map;
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final trimmed = value.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _intFromForm(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static List<String> _idListFromJson(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  static List<String> _idListFromForm(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  String get castingTimeLabel {
    final unit = CastingTypes.labelFor(castingType);
    if (castingType == CastingTypes.minutes ||
        castingType == CastingTypes.hours) {
      return '$castingTime $unit';
    }
    return unit;
  }

  String get componentsLabel {
    final parts = <String>[];
    if (componentVerbal) parts.add('V');
    if (componentSomatic) parts.add('S');
    if (componentMaterial) parts.add('M');
    return parts.isEmpty ? '—' : parts.join(', ');
  }
}
