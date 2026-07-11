import 'package:flutter/material.dart';
import 'package:rpg_companion/core/records/typed_record_cache.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';
import 'package:rpg_companion/features/player/classes/models/character_class.dart';

class ClassListTile extends StatelessWidget {
  const ClassListTile({
    super.key,
    required this.characterClass,
    this.onTap,
  });

  final CharacterClass characterClass;
  final VoidCallback? onTap;

  String? _sourceLabel() {
    final fileId = characterClass.fileId;
    if (fileId == null || fileId.isEmpty) return null;
    final file = TypedRecordCache.instance.get<ResourceFile>('files', fileId);
    return file?.name ?? 'File #$fileId';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sourceLabel = _sourceLabel();

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                characterClass.caster
                    ? Icons.auto_fix_high_outlined
                    : Icons.shield_outlined,
                color: scheme.primary,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    characterClass.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (sourceLabel != null)
                    Text(
                      'Source: $sourceLabel',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
            if (characterClass.caster)
              Chip(
                label: const Text('Caster'),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
