import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:rpg_companion/core/records/record_json_utils.dart';
import 'package:rpg_companion/core/records/rpg_record.dart';

class AuthorLink {
  const AuthorLink({required this.source, required this.url});

  final String source;
  final String url;

  factory AuthorLink.fromJson(Map<String, dynamic> json) {
    return AuthorLink(
      source: json['source'] as String? ?? 'website',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'source': source,
        'url': url,
      };

  static AuthorLink fromFormEntry(Map<String, dynamic> entry) {
    return AuthorLink(
      source: (entry['source'] as String? ?? 'website').trim(),
      url: (entry['url'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toFormEntry() => {
        'source': source,
        'url': url,
      };
}

abstract final class AuthorSourceOptions {
  static const values = [
    'website',
    'patreon',
    'drive',
    'dropbox',
    'mega',
    'reddit',
    'homebrewery',
    'gmbinder',
  ];

  static String labelFor(String value) {
    switch (value) {
      case 'patreon':
        return 'Patreon';
      case 'drive':
        return 'Drive';
      case 'dropbox':
        return 'Dropbox';
      case 'mega':
        return 'Mega';
      case 'reddit':
        return 'Reddit';
      case 'homebrewery':
        return 'Homebrewery';
      case 'gmbinder':
        return 'GMbinder';
      case 'website':
      default:
        return 'Website';
    }
  }
}

abstract final class AuthorFormKeys {
  static const name = 'name';
  static const links = 'links';
}

class Author extends RpgRecord {
  @override
  final RecordId id;
  @override
  RecordType get recordType => 'authors';
  @override
  final String name;
  final List<AuthorLink> links;

  Author({
    required this.id,
    required this.name,
    this.links = const [],
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    final data = RpgRecord.unwrapJson(json);
    final rawLinks = data['links'];
    final links = <AuthorLink>[];
    if (rawLinks is List) {
      for (final item in rawLinks) {
        if (item is Map) {
          links.add(
            AuthorLink.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return Author(
      id: RpgRecord.idFromJson(data),
      name: RpgRecord.nameFromJson(data),
      links: links,
    );
  }

  factory Author.fromFormValues(
    Map<String, dynamic> values, {
    String? id,
  }) {
    final rawLinks = values[AuthorFormKeys.links];
    final links = <AuthorLink>[];
    if (rawLinks is List) {
      for (final entry in rawLinks) {
        if (entry is Map) {
          final link = AuthorLink.fromFormEntry(
            Map<String, dynamic>.from(entry),
          );
          if (link.url.isNotEmpty) {
            links.add(link);
          }
        }
      }
    }
    return Author(
      id: id ?? 'temp-${DateTime.now().millisecondsSinceEpoch}',
      name: (values[AuthorFormKeys.name] as String? ?? '').trim(),
      links: links,
    );
  }

  Map<String, dynamic> toFormValues() {
    return {
      AuthorFormKeys.name: name,
      AuthorFormKeys.links: links
          .map((link) => {...link.toFormEntry(), '_key': link.url})
          .toList(),
    };
  }

  bool get _isTempId => RecordJsonUtils.isTempId(id);

  @override
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'links': links.map((link) => link.toJson()).toList(),
    };
    if (!_isTempId) {
      map['id'] = int.tryParse(id) ?? id;
    }
    return map;
  }
}
