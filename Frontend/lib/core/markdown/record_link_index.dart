import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:rpg_companion/core/markdown/linkable_record_registry.dart';
import 'package:rpg_companion/core/records/typed_record_cache.dart';
import 'package:rpg_companion/core/records/rpg_record.dart';
import 'package:rpg_companion/features/dm_tools/resources/services/resource_record_resolver.dart';
import 'package:rpg_companion/features/player/services/player_record_resolver.dart';

/// Builds and searches a flat index of linkable records from [RecordBloc] state.
abstract final class RecordLinkIndex {
  static List<IndexedLinkableRecord> buildFromState(RecordState state) {
    final entries = <IndexedLinkableRecord>[];

    for (final config in LinkableRecordRegistry.linkableConfigs) {
      final records = _resolveRecords(state, config.type, config.listQuery);
      for (final record in records) {
        entries.add(
          IndexedLinkableRecord(
            type: config.type,
            id: record.id,
            name: (record as RpgRecord).name,
            typeLabel: config.typeLabel,
          ),
        );
      }
    }

    entries.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return entries;
  }

  static List<IndexedLinkableRecord> search(
    List<IndexedLinkableRecord> entries,
    String query,
  ) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return entries;

    return entries
        .where(
          (entry) =>
              entry.name.toLowerCase().contains(trimmed) ||
              entry.typeLabel.toLowerCase().contains(trimmed),
        )
        .toList();
  }

  static Record? resolveRecord(RecordType type, RecordId id) {
    if (!LinkableRecordRegistry.isLinkable(type)) return null;

    final typed = TypedRecordCache.instance.get<Record>(type, id);
    if (typed != null) return typed;
    return null;
  }

  static List<Record> _resolveRecords(
    RecordState state,
    RecordType type,
    RecordQuery query,
  ) {
    switch (type) {
      case 'authors':
        return resolveAuthors(state, query);
      case 'files':
        return resolveResourceFiles(state, query);
      case 'classes':
        return resolveClasses(state, query);
      default:
        return resolveQueryRecords<Record>(
          state: state,
          query: query,
          recordType: type,
        );
    }
  }
}

/// Result of detecting an unfinished wiki-link token at the cursor.
class WikiLinkAutocompleteContext {
  const WikiLinkAutocompleteContext({
    required this.tokenStart,
    required this.query,
  });

  final int tokenStart;
  final String query;
}

/// Detects whether the cursor is inside an unfinished `[[...` wiki-link token.
WikiLinkAutocompleteContext? detectWikiLinkAutocomplete(
  String text,
  int cursorOffset,
) {
  if (cursorOffset < 0 || cursorOffset > text.length) return null;

  final beforeCursor = text.substring(0, cursorOffset);
  final match = RegExp(r'\[\[[^\]]*$').firstMatch(beforeCursor);
  if (match == null) return null;

  final tokenStart = match.start;
  final query = beforeCursor.substring(tokenStart + 2);
  return WikiLinkAutocompleteContext(tokenStart: tokenStart, query: query);
}

/// Inserts a canonical wiki link, replacing the partial token at [tokenStart].
String insertWikiLink({
  required String text,
  required int tokenStart,
  required int cursorOffset,
  required IndexedLinkableRecord record,
}) {
  final link = record.canonicalLink;
  final suffix = text.substring(cursorOffset);
  return text.replaceRange(tokenStart, cursorOffset, link) + suffix;
}

int cursorAfterWikiLinkInsert(int tokenStart, IndexedLinkableRecord record) {
  return tokenStart + record.canonicalLink.length;
}
