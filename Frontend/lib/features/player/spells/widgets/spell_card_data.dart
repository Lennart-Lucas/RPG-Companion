import 'package:rpg_companion/features/player/spells/models/spell.dart';

/// Display data for a spell card, derived from a [Spell] plus resolved names.
class SpellCardData {
  const SpellCardData({
    required this.spell,
    required this.classNames,
    this.tagNames = const [],
  });

  final Spell spell;
  final List<String> classNames;
  final List<String> tagNames;

  String get title {
    final name = spell.name.trim();
    if (name.isEmpty) return 'Spell';
    return name;
  }

  String get levelSchoolLine {
    final level = spell.level == 'cantrip'
        ? 'Cantrip'
        : spell.level[0].toUpperCase() + spell.level.substring(1);
    return '$level · ${SpellSchools.labelFor(spell.school)}';
  }

  String summaryLine({
    int? continuationIndex,
    int? continuationTotal,
  }) {
    final tags = tagNames.isEmpty ? '' : ' · ${tagNames.join(', ')}';
    final part = continuationIndex != null && continuationTotal != null
        ? ' · Part $continuationIndex/$continuationTotal'
        : '';
    return '$levelSchoolLine$tags$part';
  }

  String get castingAndRangeLine {
    var casting = spell.castingTimeLabel;
    if (spell.castingType == CastingTypes.reaction &&
        spell.trigger != null &&
        spell.trigger!.trim().isNotEmpty) {
      casting = '$casting (${spell.trigger!.trim()})';
    }
    return '$casting · ${SpellRanges.labelFor(spell.range)}';
  }

  String get durationLine {
    final d = SpellDurations.labelFor(spell.duration);
    if (!spell.concentration) return d;
    if (spell.duration == 'instantaneous') return '$d (C)';
    return 'Up to $d (C)';
  }

  String get componentsLine {
    final parts = <String>[];
    if (spell.componentVerbal) parts.add('V');
    if (spell.componentSomatic) parts.add('S');
    if (spell.componentMaterial) parts.add('M');
    if (parts.isEmpty) return 'None';

    var line = parts.join(', ');
    if (spell.componentMaterial &&
        spell.materials != null &&
        spell.materials!.trim().isNotEmpty) {
      line = '$line (${spell.materials!.trim()})';
    }
    return line;
  }

  String get classesLine => classNames.join(', ');

  bool get hasFooter => classesLine.trim().isNotEmpty;

  /// Combines description and higher-levels markdown for card body pagination.
  static String combineBodyMarkdown({
    String? description,
    String? higherLevels,
  }) {
    final desc = description?.trim() ?? '';
    final higher = higherLevels?.trim() ?? '';

    if (desc.isEmpty && higher.isEmpty) return '';
    if (desc.isEmpty) return '**At Higher Levels:** $higher';
    if (higher.isEmpty) return desc;
    return '$desc\n\n**At Higher Levels:** $higher';
  }
}
