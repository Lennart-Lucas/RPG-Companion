import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:rpg_companion/core/records/record_json_utils.dart';
import 'package:rpg_companion/core/records/rpg_record.dart';

abstract final class CharacterClassFormKeys {
  static const name = 'name';
  static const fileId = 'file_id';
  static const caster = 'caster';
}

class CharacterClass extends RpgRecord {
  @override
  final RecordId id;
  @override
  RecordType get recordType => 'classes';
  @override
  final String name;
  final String? fileId;
  final bool caster;

  CharacterClass({
    required this.id,
    required this.name,
    this.fileId,
    this.caster = false,
  });

  factory CharacterClass.fromJson(Map<String, dynamic> json) {
    final data = RpgRecord.unwrapJson(json);
    return CharacterClass(
      id: RpgRecord.idFromJson(data),
      name: RpgRecord.nameFromJson(data),
      fileId: RecordJsonUtils.parentIdFromJson(data['file_id']),
      caster: data['caster'] as bool? ?? false,
    );
  }

  factory CharacterClass.fromFormValues(
    Map<String, dynamic> values, {
    String? id,
  }) {
    return CharacterClass(
      id: id ?? 'temp-${DateTime.now().millisecondsSinceEpoch}',
      name: (values[CharacterClassFormKeys.name] as String? ?? '').trim(),
      fileId: RecordJsonUtils.parentIdFromFormValue(
        values[CharacterClassFormKeys.fileId],
      ),
      caster: values[CharacterClassFormKeys.caster] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFormValues() => {
        CharacterClassFormKeys.name: name,
        CharacterClassFormKeys.fileId: fileId ?? '',
        CharacterClassFormKeys.caster: caster,
      };

  bool get _isTempId => RecordJsonUtils.isTempId(id);

  @override
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'caster': caster,
    };
    if (!_isTempId) {
      map['id'] = int.tryParse(id) ?? id;
    }
    if (fileId != null && fileId!.isNotEmpty) {
      map['file_id'] = int.tryParse(fileId!) ?? fileId;
    } else if (!_isTempId) {
      map['file_id'] = null;
    }
    return map;
  }
}
