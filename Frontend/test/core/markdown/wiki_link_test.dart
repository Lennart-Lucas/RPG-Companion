import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_companion/core/markdown/wiki_link.dart';

void main() {
  group('WikiLink', () {
    test('parses link with alias', () {
      final link = WikiLink.tryParse('[[authors:12|My Author]]');
      expect(link, isNotNull);
      expect(link!.type, 'authors');
      expect(link.id, '12');
      expect(link.alias, 'My Author');
    });

    test('parses link without alias', () {
      final link = WikiLink.tryParse('[[files:3]]');
      expect(link, isNotNull);
      expect(link!.type, 'files');
      expect(link.id, '3');
      expect(link.alias, isNull);
    });

    test('returns null for malformed tokens', () {
      expect(WikiLink.tryParse('[[authors]]'), isNull);
      expect(WikiLink.tryParse('[[authors:1|]]'), isNull);
      expect(WikiLink.tryParse('authors:1'), isNull);
    });

    test('serializes with alias', () {
      const link = WikiLink(type: 'classes', id: '1', alias: 'Arcane Knight');
      expect(link.serialize(), '[[classes:1|Arcane Knight]]');
    });

    test('serializes without alias using fallback label', () {
      const link = WikiLink(type: 'authors', id: '5');
      expect(link.serialize(fallbackLabel: 'Jane Doe'), '[[authors:5|Jane Doe]]');
      expect(link.serialize(), '[[authors:5]]');
    });

    test('findWikiLinkMatches returns all links in order', () {
      const text =
          'See [[authors:1|A]] and [[files:2]] in [[classes:3|Knight]].';
      final matches = findWikiLinkMatches(text);
      expect(matches, hasLength(3));
      expect(matches[0].group(0), '[[authors:1|A]]');
      expect(matches[1].group(0), '[[files:2]]');
      expect(matches[2].group(0), '[[classes:3|Knight]]');
    });
  });
}
