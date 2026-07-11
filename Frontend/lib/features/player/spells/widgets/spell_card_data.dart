import 'package:rpg_companion/features/player/spells/models/spell.dart';

/// Display data for a spell card, derived from a [Spell] plus resolved class names.
class SpellCardData {
  const SpellCardData({
    required this.spell,
    required this.classNames,
  });

  final Spell spell;
  final List<String> classNames;

  String get title {
    final name = spell.name.trim();
    if (name.isEmpty) return 'UNNAMED SPELL';
    return name.toUpperCase();
  }

  String get levelSchoolLine {
    final level = spell.level == 'cantrip'
        ? 'Cantrip'
        : spell.level[0].toUpperCase() + spell.level.substring(1);
    return '$level · ${SpellSchools.labelFor(spell.school)}';
  }

  String get castingLine {
    final unit = CastingTypes.labelFor(spell.castingType);
    final time = spell.castingType == CastingTypes.minutes ||
            spell.castingType == CastingTypes.hours
        ? spell.castingTimeLabel
        : '${spell.castingTime} $unit';
    final range = SpellRanges.labelFor(spell.range);
    return '$time · $range';
  }

  String get durationLine => SpellDurations.labelFor(spell.duration);

  String get componentsLine {
    final parts = <String>[];
    if (spell.componentVerbal) parts.add('V');
    if (spell.componentSomatic) parts.add('S');
    if (spell.componentMaterial) parts.add('M');
    if (parts.isEmpty) return '—';

    var line = parts.join(', ');
    if (spell.componentMaterial &&
        spell.materials != null &&
        spell.materials!.trim().isNotEmpty) {
      line = '$line (${spell.materials!.trim()})';
    }
    return line;
  }

  String get classesLine =>
      classNames.isEmpty ? '—' : classNames.join(', ');

  /// Combines description and higher-levels markdown for card body pagination.
  static String combineBodyMarkdown({
    String? description,
    String? higherLevels,
  }) {
    final desc = description?.trim() ?? '';
    final higher = higherLevels?.trim() ?? '';

    if (desc.isEmpty && higher.isEmpty) return '';
    if (desc.isEmpty) return higher;
    if (higher.isEmpty) return desc;
    return '$desc\n\n## At Higher Levels\n\n$higher';
  }
}
