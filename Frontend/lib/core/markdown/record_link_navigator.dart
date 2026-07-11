import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:rpg_companion/core/markdown/linkable_record_registry.dart';
import 'package:rpg_companion/core/markdown/record_link_index.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/models/author.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';
import 'package:rpg_companion/features/player/classes/models/character_class.dart';

/// Opens detail pages for wiki-link targets.
abstract final class RecordLinkNavigator {
  static Future<void> open(
    BuildContext context, {
    required RecordType type,
    required RecordId id,
    Record? record,
  }) async {
    if (!LinkableRecordRegistry.isLinkable(type)) return;

    final resolved = record ?? RecordLinkIndex.resolveRecord(type, id);
    if (resolved == null) return;

    switch (type) {
      case 'authors':
        await RpgNavigation.openAuthorDetail(context, resolved as Author);
      case 'files':
        await RpgNavigation.openFileDetail(context, resolved as ResourceFile);
      case 'classes':
        await RpgNavigation.openClassDetail(
          context,
          resolved as CharacterClass,
        );
      default:
        break;
    }
  }
}
