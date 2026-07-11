import 'package:anvil_foundry/anvil_foundry.dart';

import 'package:rpg_companion/core/records/record_json_utils.dart';

/// Shared list-display record for RPG Companion entities.
abstract class RpgRecord extends Record {
  String get name;

  static String idFromJson(Map<String, dynamic> json) =>
      RecordJsonUtils.idFromJson(json);

  static String nameFromJson(Map<String, dynamic> json) =>
      RecordJsonUtils.nameFromJson(json);

  static Map<String, dynamic> unwrapJson(Map<String, dynamic> json) =>
      RecordJsonUtils.unwrapJson(json);
}
