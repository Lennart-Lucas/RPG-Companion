import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/markdown/markdown_wiki_display.dart';
import 'package:rpg_companion/core/records/typed_record_cache.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';
import 'package:rpg_companion/features/dm_tools/resources/services/resource_record_resolver.dart';
import 'package:rpg_companion/features/player/classes/models/character_class.dart';
import 'package:rpg_companion/features/player/spells/models/spell.dart';
import 'package:rpg_companion/features/player/spell_tags/models/spell_tag.dart';

class SpellDetailPage extends StatefulWidget {
  const SpellDetailPage({
    super.key,
    required this.spellId,
    this.spell,
  });

  final RecordId spellId;
  final Spell? spell;

  @override
  State<SpellDetailPage> createState() => _SpellDetailPageState();
}

class _SpellDetailPageState extends State<SpellDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RecordBloc>().add(
            GetRecordRequested(recordType: 'spells', recordId: widget.spellId),
          );
    });
  }

  Spell? _spellFromState(RecordState state) {
    if (widget.spell != null) return widget.spell;
    return resolveTypedRecord<Spell>(
      state: state,
      recordType: 'spells',
      id: widget.spellId,
    );
  }

  ResourceFile? _sourceFile(Spell spell) {
    final fileId = spell.fileId;
    if (fileId == null || fileId.isEmpty) return null;
    return TypedRecordCache.instance.get<ResourceFile>('files', fileId);
  }

  List<CharacterClass> _classes(Spell spell) {
    return spell.classIds
        .map(
          (id) => TypedRecordCache.instance.get<CharacterClass>('classes', id),
        )
        .whereType<CharacterClass>()
        .toList();
  }

  List<SpellTag> _tags(Spell spell) {
    return spell.spellTagIds
        .map(
          (id) => TypedRecordCache.instance.get<SpellTag>('spell_tags', id),
        )
        .whereType<SpellTag>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordBloc, RecordState>(
      builder: (context, state) {
        final spell = _spellFromState(state);
        if (spell == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final sourceFile = _sourceFile(spell);
        final classes = _classes(spell);
        final tags = _tags(spell);

        return Scaffold(
          appBar: AppBar(title: Text(spell.name)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                spell.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${SpellLevels.labelFor(spell.level)} · ${SpellSchools.labelFor(spell.school)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Casting time',
                value: spell.castingTimeLabel,
              ),
              if (spell.castingType == CastingTypes.reaction &&
                  spell.trigger != null)
                _DetailRow(label: 'Trigger', value: spell.trigger!),
              _DetailRow(
                label: 'Duration',
                value: SpellDurations.labelFor(spell.duration),
              ),
              _DetailRow(
                label: 'Range',
                value: SpellRanges.labelFor(spell.range),
              ),
              _DetailRow(label: 'Components', value: spell.componentsLabel),
              if (spell.componentMaterial &&
                  spell.materials != null &&
                  spell.materials!.isNotEmpty)
                _DetailRow(label: 'Materials', value: spell.materials!),
              if (spell.concentration)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Chip(label: Text('Concentration')),
                ),
              if (classes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Classes',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final characterClass in classes)
                      Chip(label: Text(characterClass.name)),
                  ],
                ),
              ],
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Tags',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in tags) Chip(label: Text(tag.name)),
                  ],
                ),
              ],
              if (sourceFile != null) ...[
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: const Text('Source'),
                  subtitle: Text(sourceFile.name),
                  onTap: () =>
                      RpgNavigation.openFileDetail(context, sourceFile),
                ),
              ],
              if (spell.description != null &&
                  spell.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                MarkdownWikiDisplay(source: spell.description!),
              ],
              if (spell.higherLevels != null &&
                  spell.higherLevels!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'At higher levels',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                MarkdownWikiDisplay(source: spell.higherLevels!),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
