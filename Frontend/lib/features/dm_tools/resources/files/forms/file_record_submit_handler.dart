import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:rpg_companion/core/records/record_list_refresh.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';

class FileRecordSubmitHandler extends FormSubmitHandler {
  FileRecordSubmitHandler({
    required this.recordBloc,
    this.recordId,
    this.preloadedFile,
  });

  final RecordBloc recordBloc;
  final RecordId? recordId;
  final ResourceFile? preloadedFile;

  late final RecordSubmitHandler _delegate = RecordSubmitHandler(
    recordBloc: recordBloc,
    recordType: 'files',
    recordId: recordId,
    toRecord: (values) => ResourceFile.fromFormValues(values, id: recordId),
    fromRecord: (record) => (record as ResourceFile).toFormValues(),
  );

  @override
  bool get canHydrate => recordId != null;

  @override
  Future<Map<String, dynamic>> hydrate() async {
    if (recordId == null) return {};
    if (preloadedFile != null) return preloadedFile!.toFormValues();
    return hydrateRecordValues(
      recordBloc: recordBloc,
      recordType: 'files',
      recordId: recordId!,
      fromRecord: (record) => (record as ResourceFile).toFormValues(),
    );
  }

  @override
  Future<FormSubmitResult> submit(Map<String, dynamic> values) async {
    final result = await _delegate.submit(values);
    if (!result.success) return result;
    recordBloc.remoteCoordinator?.refreshQueryRecords(filesListQuery);
    final authorId = ResourceFile.fromFormValues(values).authorId;
    if (authorId != null && authorId.isNotEmpty) {
      recordBloc.remoteCoordinator?.refreshQueryRecords(
        filesForAuthorQuery(authorId),
      );
    }
    return result;
  }

  @override
  void dispose() => _delegate.dispose();
}
