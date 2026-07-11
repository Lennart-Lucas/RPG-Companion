import 'package:anvil_foundry/anvil_foundry.dart';

/// In-memory store keyed by record type + id so authors and files can share
/// numeric ids without overwriting each other in [RecordBloc]'s flat cache.
class TypedRecordCache {
  TypedRecordCache._();

  static final TypedRecordCache instance = TypedRecordCache._();

  final Map<String, Record> _records = {};
  final Set<String> _removedKeys = {};

  String _key(RecordType type, RecordId id) => '$type:$id';

  void put(Record record) {
    final key = _key(record.recordType, record.id);
    _removedKeys.remove(key);
    _records[key] = record;
  }

  void putAll(Iterable<Record> records) {
    for (final record in records) {
      put(record);
    }
  }

  bool isRemoved(RecordType type, RecordId id) {
    return _removedKeys.contains(_key(type, id));
  }

  T? get<T extends Record>(RecordType type, RecordId id) {
    if (isRemoved(type, id)) return null;
    return _records[_key(type, id)] as T?;
  }

  void remove(RecordType type, RecordId id) {
    final key = _key(type, id);
    _records.remove(key);
    _removedKeys.add(key);
  }

  void clear() {
    _records.clear();
    _removedKeys.clear();
  }
}
