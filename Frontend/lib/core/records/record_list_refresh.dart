import 'dart:async';

import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/core/records/typed_record_cache.dart';
Future<void> refreshRecordQuery(RecordBloc bloc, RecordQuery query) async {
  final key = query.queryKey;
  final versionBefore = bloc.state.snapshot.queries[key]?.version ?? -1;

  bool isComplete(RecordState state) {
    final cached = state.snapshot.queries[key];
    return cached != null &&
        cached.freshness == RecordFreshness.fresh &&
        cached.version > versionBefore;
  }

  bloc.remoteCoordinator?.refreshQueryRecords(query);

  if (isComplete(bloc.state)) return;

  await bloc.stream
      .where(isComplete)
      .first
      .timeout(
        const Duration(seconds: 30),
        onTimeout: () => bloc.state,
      );
}

/// Forces a network refetch for file list queries after create/update/delete.
void forceRefreshFileQueries(RecordBloc bloc, {String? authorId}) {
  bloc.remoteCoordinator?.refreshQueryRecords(filesListQuery);
  if (authorId != null && authorId.isNotEmpty) {
    bloc.remoteCoordinator?.refreshQueryRecords(filesForAuthorQuery(authorId));
  }
}

Future<Map<String, dynamic>> hydrateRecordValues({
  required RecordBloc recordBloc,
  required RecordType recordType,
  required RecordId recordId,
  required Map<String, dynamic> Function(Record record) fromRecord,
}) async {
  final typed = TypedRecordCache.instance.get<Record>(recordType, recordId);
  if (typed != null) {
    return fromRecord(typed);
  }

  final cached = recordBloc.state.snapshot.records[recordId];
  if (cached != null &&
      !cached.isDeleted &&
      cached.record.recordType == recordType) {
    TypedRecordCache.instance.put(cached.record);
    return fromRecord(cached.record);
  }

  final completer = Completer<Map<String, dynamic>>();
  late final StreamSubscription<RecordState> sub;

  sub = recordBloc.stream.listen((state) {
    final entry = state.snapshot.records[recordId];
    if (entry != null &&
        !entry.isDeleted &&
        entry.record.recordType == recordType) {
      if (!completer.isCompleted) {
        completer.complete(fromRecord(entry.record));
      }
      sub.cancel();
    }

    final error = state.snapshot.errors
        .where((e) => e.key == recordId)
        .firstOrNull;
    if (error != null && !completer.isCompleted) {
      completer.completeError(
        Exception(error.message),
      );
      sub.cancel();
    }
  });

  recordBloc.add(GetRecordRequested(recordType: recordType, recordId: recordId));

  try {
    return await completer.future;
  } finally {
    await sub.cancel();
  }
}
