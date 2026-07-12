import 'package:rpg_companion/core/markdown/wiki_link.dart';
import 'package:rpg_companion/features/player/damage_types/models/damage_type.dart';

/// Replaces whole-word damage type names in [text] with wiki links.
///
/// Skips text inside existing `[[type:id|alias]]` tokens. Names are matched
/// case-sensitively as whole words. Longer names are linked before shorter ones.
String linkDamageTypeMentions(String text, List<DamageType> damageTypes) {
  if (text.isEmpty || damageTypes.isEmpty) return text;

  final sortedTypes = [...damageTypes]
    ..sort((a, b) => b.name.length.compareTo(a.name.length));

  final wikiMatches = findWikiLinkMatches(text);
  final buffer = StringBuffer();
  var cursor = 0;

  for (final match in wikiMatches) {
    if (match.start > cursor) {
      buffer.write(
        _linkDamageTypesInSegment(
          text.substring(cursor, match.start),
          sortedTypes,
        ),
      );
    }
    buffer.write(match.group(0));
    cursor = match.end;
  }

  if (cursor < text.length) {
    buffer.write(
      _linkDamageTypesInSegment(text.substring(cursor), sortedTypes),
    );
  }

  return buffer.toString();
}

String _linkDamageTypesInSegment(
  String segment,
  List<DamageType> damageTypes,
) {
  var output = segment;
  for (final damageType in damageTypes) {
    final name = damageType.name.trim();
    if (name.isEmpty) continue;

    final pattern = RegExp(
      '(?<![A-Za-z0-9])(${RegExp.escape(name)})(?![A-Za-z0-9])',
    );
    output = output.replaceAllMapped(pattern, (match) {
      return WikiLink(
        type: damageType.recordType,
        id: damageType.id,
      ).serialize();
    });
  }
  return output;
}
