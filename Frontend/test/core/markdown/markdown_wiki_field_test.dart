import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_companion/core/markdown/fields/markdown_wiki_field.dart';
import 'package:rpg_companion/core/records/rpg_record_registry.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/core/records/typed_record_cache.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/models/author.dart';

class _NoopRecordRepository extends RecordRepositoryService {
  @override
  Future<RecordMutationResponse> create(
    RecordType type,
    Map<String, dynamic> data,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<RecordMutationResponse> delete(RecordType type, RecordId id) async {
    throw UnimplementedError();
  }

  @override
  Future<RecordResponse> fetchById(RecordType type, RecordId id) async {
    throw UnimplementedError();
  }

  @override
  Future<RecordQueryListResponse> query(RecordQuery query) async {
    throw UnimplementedError();
  }

  @override
  Future<RecordMutationResponse> update(
    RecordType type,
    RecordId id,
    Map<String, dynamic> data,
  ) async {
    throw UnimplementedError();
  }
}

RecordCached _cachedRecord(Record record) {
  final now = DateTime.now();
  return RecordCached(
    record: record,
    version: 1,
    origin: RecordOrigin.cache,
    freshness: RecordFreshness.fresh,
    expiresAt: now.add(const Duration(minutes: 5)),
    lastUpdatedAt: now,
    lastFetchedAt: now,
  );
}

CachedQueryResult _cachedQuery(List<RecordId> recordIds) {
  final now = DateTime.now();
  return CachedQueryResult(
    recordIds: recordIds,
    version: 1,
    freshness: RecordFreshness.fresh,
    expiresAt: now.add(const Duration(minutes: 5)),
    lastUpdatedAt: now,
    lastFetchedAt: now,
  );
}

void main() {
  group('RpgMarkdownWikiField', () {
    late RecordBloc recordBloc;

    setUp(() {
      TypedRecordCache.instance.clear();

      final author = Author(id: '42', name: 'Test Author');
      TypedRecordCache.instance.put(author);

      final snapshot = RecordCacheSnapshot(
        offline: false,
        errors: const [],
        records: {
          author.id: _cachedRecord(author),
        },
        queries: {
          authorsListQuery.queryKey: _cachedQuery([author.id]),
        },
      );

      final coordinator = RecordCoordinatorService(
        buildRpgRecordRegistry(),
        _NoopRecordRepository(),
        initialSnapshot: snapshot,
      );
      recordBloc = RecordBloc(coordinator);
    });

    tearDown(() async {
      await recordBloc.close();
      TypedRecordCache.instance.clear();
    });

    testWidgets('typing [[ opens overlay and inserts canonical link on select',
        (tester) async {
      const fieldKey = 'notes';

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<RecordBloc>.value(value: recordBloc),
              BlocProvider(
                create: (_) => AnvilFormBloc(
                  config: AnvilFormConfig(
                    formKey: 'wiki_field_test',
                    steps: const ['main'],
                    pages: {
                      'main': AnvilFormPage(
                        builder: (context, state) => const SizedBox.shrink(),
                      ),
                    },
                    initialValues: const {fieldKey: ''},
                    submitHandler: CallbackSubmitHandler(
                      onSubmit: (_) async => const FormSubmitResult.success(),
                    ),
                  ),
                )..add(const AnvilFormInitialized()),
              ),
            ],
            child: const Scaffold(
              body: RpgMarkdownWikiField(fieldKey: fieldKey, showPreview: false),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'See [[');
      await tester.pumpAndSettle();

      expect(find.text('Test Author'), findsOneWidget);

      await tester.tap(find.text('Test Author'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('[[authors:42]]'),
        findsOneWidget,
      );
    });
  });
}
