import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:rpg_companion/core/records/record_json_utils.dart';
import 'package:rpg_companion/core/records/rpg_record.dart';

abstract final class ResourceFileFormKeys {
  static const name = 'name';
  static const address = 'address';
  static const authorId = 'author_id';
}

class ResourceFile extends RpgRecord {
  @override
  final RecordId id;
  @override
  RecordType get recordType => 'files';
  @override
  final String name;
  final String address;
  final String? authorId;

  ResourceFile({
    required this.id,
    required this.name,
    required this.address,
    this.authorId,
  });

  factory ResourceFile.fromJson(Map<String, dynamic> json) {
    final data = RpgRecord.unwrapJson(json);
    return ResourceFile(
      id: RpgRecord.idFromJson(data),
      name: RpgRecord.nameFromJson(data),
      address: data['address'] as String? ?? '',
      authorId: RecordJsonUtils.parentIdFromJson(data['author_id']),
    );
  }

  factory ResourceFile.fromFormValues(
    Map<String, dynamic> values, {
    String? id,
  }) {
    return ResourceFile(
      id: id ?? 'temp-${DateTime.now().millisecondsSinceEpoch}',
      name: (values[ResourceFileFormKeys.name] as String? ?? '').trim(),
      address: (values[ResourceFileFormKeys.address] as String? ?? '').trim(),
      authorId: RecordJsonUtils.parentIdFromFormValue(
        values[ResourceFileFormKeys.authorId],
      ),
    );
  }

  Map<String, dynamic> toFormValues() => {
        ResourceFileFormKeys.name: name,
        ResourceFileFormKeys.address: address,
        ResourceFileFormKeys.authorId: authorId ?? '',
      };

  bool get _isTempId => RecordJsonUtils.isTempId(id);

  @override
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'address': address,
    };
    if (!_isTempId) {
      map['id'] = int.tryParse(id) ?? id;
    }
    if (authorId != null && authorId!.isNotEmpty) {
      map['author_id'] = int.tryParse(authorId!) ?? authorId;
    } else if (!_isTempId) {
      map['author_id'] = null;
    }
    return map;
  }
}
