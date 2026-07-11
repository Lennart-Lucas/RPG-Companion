import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:rpg_companion/core/records/record_json_utils.dart';
import 'package:rpg_companion/core/records/rpg_record.dart';

abstract final class SpellTagFormKeys {
  static const name = 'name';
  static const description = 'description';
}

class SpellTag extends RpgRecord {
  @override
  final RecordId id;
  @override
  RecordType get recordType => 'spell_tags';
  @override
  final String name;
  final String? description;

  SpellTag({
    required this.id,
    required this.name,
    this.description,
  });

  factory SpellTag.fromJson(Map<String, dynamic> json) {
    final data = RpgRecord.unwrapJson(json);
    final rawDescription = data['description'];
    return SpellTag(
      id: RpgRecord.idFromJson(data),
      name: RpgRecord.nameFromJson(data),
      description: rawDescription is String ? rawDescription : null,
    );
  }

  factory SpellTag.fromFormValues(
    Map<String, dynamic> values, {
    String? id,
  }) {
    final rawDescription = values[SpellTagFormKeys.description] as String?;
    final trimmedDescription = rawDescription?.trim();
    return SpellTag(
      id: id ?? 'temp-${DateTime.now().millisecondsSinceEpoch}',
      name: (values[SpellTagFormKeys.name] as String? ?? '').trim(),
      description:
          trimmedDescription == null || trimmedDescription.isEmpty
              ? null
              : trimmedDescription,
    );
  }

  Map<String, dynamic> toFormValues() => {
        SpellTagFormKeys.name: name,
        SpellTagFormKeys.description: description ?? '',
      };

  bool get _isTempId => RecordJsonUtils.isTempId(id);

  @override
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
    };
    if (!_isTempId) {
      map['id'] = int.tryParse(id) ?? id;
    }
    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    } else if (!_isTempId) {
      map['description'] = null;
    }
    return map;
  }
}
