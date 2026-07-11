import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:rpg_companion/core/records/record_list_refresh.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/models/author.dart';

class AuthorRecordSubmitHandler extends FormSubmitHandler {
  AuthorRecordSubmitHandler({
    required this.recordBloc,
    this.recordId,
    this.preloadedAuthor,
  });

  final RecordBloc recordBloc;
  final RecordId? recordId;
  final Author? preloadedAuthor;

  late final RecordSubmitHandler _delegate = RecordSubmitHandler(
    recordBloc: recordBloc,
    recordType: 'authors',
    recordId: recordId,
    toRecord: (values) => Author.fromFormValues(values, id: recordId),
    fromRecord: (record) => (record as Author).toFormValues(),
  );

  @override
  bool get canHydrate => recordId != null;

  @override
  Future<Map<String, dynamic>> hydrate() async {
    if (recordId == null) return {};
    if (preloadedAuthor != null) return preloadedAuthor!.toFormValues();
    return hydrateRecordValues(
      recordBloc: recordBloc,
      recordType: 'authors',
      recordId: recordId!,
      fromRecord: (record) => (record as Author).toFormValues(),
    );
  }

  @override
  Future<FormSubmitResult> submit(Map<String, dynamic> values) async {
    final result = await _delegate.submit(values);
    if (!result.success) return result;
    recordBloc.remoteCoordinator?.refreshQueryRecords(authorsListQuery);
    return result;
  }

  @override
  void dispose() => _delegate.dispose();
}
