import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:rpg_companion/features/dm_tools/resources/services/resource_record_resolver.dart';
import 'package:rpg_companion/features/player/classes/models/character_class.dart';

List<CharacterClass> resolveClasses(RecordState state, RecordQuery query) {
  return resolveQueryRecords<CharacterClass>(
    state: state,
    query: query,
    recordType: 'classes',
  );
}
