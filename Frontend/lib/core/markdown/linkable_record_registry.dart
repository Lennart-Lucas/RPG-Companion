import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';

/// Configuration for record types that can appear in `[[type:id|alias]]` links.
class LinkableRecordTypeConfig {
  const LinkableRecordTypeConfig({
    required this.type,
    required this.listQuery,
    required this.typeLabel,
    this.linkable = true,
  });

  final RecordType type;
  final RecordQuery listQuery;
  final String typeLabel;
  final bool linkable;
}

/// Registry of record types eligible for wiki-link autocomplete and navigation.
abstract final class LinkableRecordRegistry {
  static const List<LinkableRecordTypeConfig> configs = [
    LinkableRecordTypeConfig(
      type: 'authors',
      listQuery: authorsListQuery,
      typeLabel: 'Author',
      linkable: true,
    ),
    LinkableRecordTypeConfig(
      type: 'files',
      listQuery: filesListQuery,
      typeLabel: 'File',
      linkable: true,
    ),
    LinkableRecordTypeConfig(
      type: 'classes',
      listQuery: classesListQuery,
      typeLabel: 'Class',
      linkable: true,
    ),
  ];

  static Iterable<LinkableRecordTypeConfig> get linkableConfigs =>
      configs.where((config) => config.linkable);

  static LinkableRecordTypeConfig? configFor(RecordType type) {
    for (final config in configs) {
      if (config.type == type) return config;
    }
    return null;
  }

  static bool isLinkable(RecordType type) =>
      configFor(type)?.linkable ?? false;
}

/// A searchable record entry for wiki-link autocomplete.
class IndexedLinkableRecord {
  const IndexedLinkableRecord({
    required this.type,
    required this.id,
    required this.name,
    required this.typeLabel,
  });

  final RecordType type;
  final RecordId id;
  final String name;
  final String typeLabel;

  /// Canonical storage form inserted by autocomplete (name resolved at display time).
  String get canonicalLink => '[[$type:$id]]';
}
