import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:rpg_companion/core/http/rpg_api_errors.dart';
import 'package:rpg_companion/core/records/rpg_record_registry.dart';
import 'package:rpg_companion/core/records/typed_record_cache.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';

/// REST adapter for RPG Companion FastAPI list endpoints.
class RpgRecordRepository implements RecordRepositoryService {
  RpgRecordRepository(this._api) : _registry = buildRpgRecordRegistry();

  final ApiClientService _api;
  final RecordRegistry _registry;

  Map<String, dynamic> _normalizeRecord(Map<String, dynamic> json) {
    final out = Map<String, dynamic>.from(json);
    if (out['id'] != null) {
      out['id'] = out['id'].toString();
    }
    return out;
  }

  void _cacheTypedRecord(RecordType type, Map<String, dynamic> json) {
    TypedRecordCache.instance.put(_registry.getConfig(type).fromJson(json));
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
    final body = _normalizeRecord(response.bodyAsMap);
    _cacheTypedRecord(type, body);
    return RecordMutationResponse(
      record: RecordResponse(body),
      impact: RecordMutation(
        invalidatedQueries: _invalidatedQueriesForType(type, data),
      ),
    );
  }

  @override
  Future<RecordMutationResponse> delete(RecordType type, RecordId id) async {
    String? authorId;
    if (type == 'files') {
      authorId =
          TypedRecordCache.instance.get<ResourceFile>('files', id)?.authorId;
    }

    final response = await _api.delete('/$type/$id');
    _ensureSuccess(response, 'Delete $type');
    TypedRecordCache.instance.remove(type, id);
    return RecordMutationResponse(
      impact: RecordMutation(
        deleted: [id],
        invalidatedQueries: _invalidatedQueriesForDelete(type, authorId),
      ),
    );
  }

  @override
  Future<RecordResponse> fetchById(RecordType type, RecordId id) async {
    final response = await _api.get('/$type/$id');
    _ensureSuccess(response, 'Fetch $type');
    final body = _normalizeRecord(response.bodyAsMap);
    _cacheTypedRecord(type, body);
    return RecordResponse(body);
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
          final normalized = _normalizeRecord(Map<String, dynamic>.from(item));
          _cacheTypedRecord(query.recordType, normalized);
          records.add(RecordResponse(normalized));
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
    final body = _normalizeRecord(response.bodyAsMap);
    _cacheTypedRecord(type, body);
    return RecordMutationResponse(
      record: RecordResponse(body),
      impact: RecordMutation(
        invalidatedQueries: _invalidatedQueriesForType(type, data, body),
      ),
    );
  }

  List<String> _invalidatedQueriesForType(
    RecordType type,
    Map<String, dynamic> data, [
    Map<String, dynamic>? responseBody,
  ]) {
    if (type == 'authors') {
      return [authorsListQuery.queryKey];
    }
    if (type == 'files') {
      final keys = <String>[filesListQuery.queryKey];
      final authorId = data['author_id'] ?? responseBody?['author_id'];
      if (authorId != null) {
        keys.add(filesForAuthorQuery(authorId.toString()).queryKey);
      }
      return keys;
    }
    if (type == 'classes') {
      return [classesListQuery.queryKey];
    }
    return [RecordQuery(recordType: type, limit: 50).queryKey];
  }

  List<String> _invalidatedQueriesForDelete(RecordType type, String? authorId) {
    if (type == 'authors') {
      return [authorsListQuery.queryKey];
    }
    if (type == 'files') {
      final keys = <String>[filesListQuery.queryKey];
      if (authorId != null && authorId.isNotEmpty) {
        keys.add(filesForAuthorQuery(authorId).queryKey);
      }
      return keys;
    }
    if (type == 'classes') {
      return [classesListQuery.queryKey];
    }
    return const [];
  }
}

const authorsListQuery = RecordQuery(recordType: 'authors', limit: 100);
const filesListQuery = RecordQuery(recordType: 'files', limit: 100);
const classesListQuery = RecordQuery(recordType: 'classes', limit: 100);

RecordQuery filesForAuthorQuery(String authorId) {
  return RecordQuery(
    recordType: 'files',
    limit: 100,
    filter: QueryCondition(
      field: 'author_id',
      operator: QueryOperator.eq,
      value: int.tryParse(authorId) ?? authorId,
    ),
  );
}
