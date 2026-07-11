/// Shared JSON parsing helpers for RPG Companion records.
abstract final class RecordJsonUtils {
  static Map<String, dynamic> unwrapJson(Map<String, dynamic> json) {
    final nested = json['data'];
    if (nested is Map<String, dynamic>) {
      return {
        ...nested,
        if (json['id'] != null) 'id': json['id'],
      };
    }
    if (nested is Map) {
      return {
        ...Map<String, dynamic>.from(nested),
        if (json['id'] != null) 'id': json['id'],
      };
    }
    return json;
  }

  static String idFromJson(Map<String, dynamic> json) =>
      json['id']?.toString() ?? '';

  static String nameFromJson(Map<String, dynamic> json) =>
      json['name'] as String? ?? '';

  static String? parentIdFromJson(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static String? parentIdFromFormValue(dynamic value) {
    if (value == null) return null;
    final trimmed = value.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool isTempId(String id) => id.startsWith('temp-');
}
