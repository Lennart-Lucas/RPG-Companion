import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:rpg_companion/core/records/rpg_record.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/models/author.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';
import 'package:rpg_companion/features/player/classes/models/character_class.dart';

const _listTtl = Duration(minutes: 5);

RecordRegistry buildRpgRecordRegistry() {
  final registry = RecordRegistry();

  void register<T extends RpgRecord>(
    RecordType type,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    registry.register(
      RecordTypeConfig(
        type: type,
        cachePolicy: const CachePolicy(ttl: _listTtl),
        fromJson: fromJson,
        merge: (existing, patch) => patch,
      ),
    );
  }

  register('authors', Author.fromJson);
  register('files', ResourceFile.fromJson);
  register('classes', CharacterClass.fromJson);

  return registry;
}
