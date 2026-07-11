import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:rpg_companion/core/http/rpg_api_errors.dart';

/// REST adapter for RPG Companion FastAPI list endpoints.
class RpgRecordRepository implements RecordRepositoryService {
  RpgRecordRepository(this._api);

  final ApiClientService _api;

  Map<String, dynamic> _normalizeRecord(Map<String, dynamic> json) {
    final out = Map<String, dynamic>.from(json);
    if (out['id'] != null) {
      out['id'] = out['id'].toString();
    }
    return out;
  }

  void _ensureSuccess(ApiResponse response, String action) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        formatRpgApiError(
          statusCode: response.statusCode,
          body: response.body,
          action: action,
        ),
      );
    }
  }

  String _queryPath(RecordQuery query) {
    final limit = query.limit ?? 50;
    final offset = query.offset ?? 0;
    var path = '/${query.recordType}?limit=$limit&offset=$offset';
    final filter = query.filter;
    if (filter is QueryCondition &&
        filter.field == 'author_id' &&
        filter.operator == QueryOperator.eq &&
        filter.value != null) {
      path += '&author_id=${filter.value}';
    }
    return path;
  }

  @override
  Future<RecordMutationResponse> create(
    RecordType type,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.post('/$type', body: data);
    _ensureSuccess(response, 'Create $type');
    final body = response.bodyAsMap;
    final listQueryKey = RecordQuery(recordType: type, limit: 50).queryKey;
    return RecordMutationResponse(
      record: RecordResponse(_normalizeRecord(body)),
      impact: RecordMutation(invalidatedQueries: [listQueryKey]),
    );
  }

  @override
  Future<RecordMutationResponse> delete(RecordType type, RecordId id) async {
    final response = await _api.delete('/$type/$id');
    _ensureSuccess(response, 'Delete $type');
    return const RecordMutationResponse(impact: RecordMutation.empty);
  }

  @override
  Future<RecordResponse> fetchById(RecordType type, RecordId id) async {
    final response = await _api.get('/$type/$id');
    _ensureSuccess(response, 'Fetch $type');
    return RecordResponse(_normalizeRecord(response.bodyAsMap));
  }

  @override
  Future<RecordQueryListResponse> query(RecordQuery query) async {
    final response = await _api.get(_queryPath(query));
    _ensureSuccess(response, 'Query ${query.recordType}');
    final body = response.bodyAsMap;
    final items = body['items'];
    final records = <RecordResponse>[];
    if (items is List) {
      for (final item in items) {
        if (item is Map) {
          records.add(
            RecordResponse(
              _normalizeRecord(Map<String, dynamic>.from(item)),
            ),
          );
        }
      }
    }
    return RecordQueryListResponse(
      records: records,
      impact: RecordMutation.empty,
    );
  }

  @override
  Future<RecordMutationResponse> update(
    RecordType type,
    RecordId id,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.patch('/$type/$id', body: data);
    _ensureSuccess(response, 'Update $type');
    final body = response.bodyAsMap;
    final listQueryKey = RecordQuery(recordType: type, limit: 50).queryKey;
    return RecordMutationResponse(
      record: RecordResponse(_normalizeRecord(body)),
      impact: RecordMutation(invalidatedQueries: [listQueryKey]),
    );
  }
}

const authorsListQuery = RecordQuery(recordType: 'authors', limit: 100);
const filesListQuery = RecordQuery(recordType: 'files', limit: 200);

RecordQuery filesForAuthorQuery(String authorId) {
  return RecordQuery(
    recordType: 'files',
    limit: 200,
    filter: QueryCondition(
      field: 'author_id',
      operator: QueryOperator.eq,
      value: int.tryParse(authorId) ?? authorId,
    ),
  );
}
