import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:rpg_companion/core/records/typed_record_cache.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/models/author.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';

/// Resolves query rows using [TypedRecordCache] so authors and files with the
/// same numeric id do not overwrite each other.
List<T> resolveQueryRecords<T extends Record>({
  required RecordState state,
  required RecordQuery query,
  required RecordType recordType,
}) {
  final cached = state.snapshot.queries[query.queryKey];
  if (cached == null) return const [];

  final typedCache = TypedRecordCache.instance;
  final resolved = <T>[];

  for (final id in cached.recordIds) {
    if (typedCache.isRemoved(recordType, id)) continue;

    final typed = typedCache.get<T>(recordType, id);
    if (typed != null) {
      resolved.add(typed);
      continue;
    }

    final entry = state.snapshot.records[id];
    if (entry?.isDeleted == true) continue;

    final record = entry?.record;
    if (record != null && record.recordType == recordType) {
      typedCache.put(record);
      resolved.add(record as T);
    }
  }

  return resolved;
}

T? resolveTypedRecord<T extends Record>({
  required RecordState state,
  required RecordType recordType,
  required RecordId id,
}) {
  if (TypedRecordCache.instance.isRemoved(recordType, id)) return null;

  final typed = TypedRecordCache.instance.get<T>(recordType, id);
  if (typed != null) return typed;

  final entry = state.snapshot.records[id];
  final record = entry?.record;
  if (entry != null &&
      !entry.isDeleted &&
      record != null &&
      record.recordType == recordType) {
    TypedRecordCache.instance.put(record);
    return record as T;
  }

  return null;
}

/// True when a query's cached ids or any resolved record versions changed.
bool queryRecordsDisplayChanged({
  required RecordState previous,
  required RecordState current,
  required RecordQuery query,
  required RecordType recordType,
}) {
  final prevCached = previous.snapshot.queries[query.queryKey];
  final currCached = current.snapshot.queries[query.queryKey];
  if (prevCached?.version != currCached?.version) return true;
  if (prevCached?.freshness != currCached?.freshness) return true;
  if (prevCached == null || currCached == null) {
    return prevCached != currCached;
  }
  if (prevCached.recordIds.length != currCached.recordIds.length) return true;

  final typedCache = TypedRecordCache.instance;
  for (var i = 0; i < currCached.recordIds.length; i++) {
    final id = currCached.recordIds[i];
    if (i >= prevCached.recordIds.length || prevCached.recordIds[i] != id) {
      return true;
    }

    final prevTyped = typedCache.get<Record>(recordType, id);
    final currTyped = typedCache.get<Record>(recordType, id);
    if (prevTyped != currTyped) return true;

    final prevEntry = previous.snapshot.records[id];
    final currEntry = current.snapshot.records[id];
    if (prevEntry?.isDeleted != currEntry?.isDeleted) return true;
    if (prevEntry?.version != currEntry?.version &&
        currEntry?.record.recordType == recordType) {
      return true;
    }
  }
  return false;
}

List<Author> resolveAuthors(RecordState state, RecordQuery query) {
  return resolveQueryRecords<Author>(
    state: state,
    query: query,
    recordType: 'authors',
  );
}

List<ResourceFile> resolveResourceFiles(RecordState state, RecordQuery query) {
  return resolveQueryRecords<ResourceFile>(
    state: state,
    query: query,
    recordType: 'files',
  );
}
