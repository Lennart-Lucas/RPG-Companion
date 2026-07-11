/// Parsed wiki-link target from canonical `[[type:id]]` or `[[type:id|alias]]` syntax.
class WikiLink {
  const WikiLink({
    required this.type,
    required this.id,
    this.alias,
  });

  final String type;
  final String id;
  final String? alias;

  static final RegExp pattern = RegExp(
    r'\[\[([^:\]|]+):([^\]|]+)(?:\|([^\]]+))?\]\]',
  );

  static WikiLink? tryParse(String token) {
    final match = pattern.firstMatch(token);
    if (match == null) return null;
    final alias = match.group(3)?.trim();
    return WikiLink(
      type: match.group(1)!.trim(),
      id: match.group(2)!.trim(),
      alias: alias == null || alias.isEmpty ? null : alias,
    );
  }

  String serialize({String? fallbackLabel}) {
    final label = alias ?? fallbackLabel;
    if (label == null || label.isEmpty) {
      return '[[$type:$id]]';
    }
    return '[[$type:$id|$label]]';
  }

  @override
  String toString() => serialize();
}

/// Finds all wiki-link matches in [text], in document order.
List<RegExpMatch> findWikiLinkMatches(String text) {
  return WikiLink.pattern.allMatches(text).toList();
}
