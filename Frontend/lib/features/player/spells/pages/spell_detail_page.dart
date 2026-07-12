import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/records/typed_record_cache.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';
import 'package:rpg_companion/features/dm_tools/resources/services/resource_record_resolver.dart';
import 'package:rpg_companion/features/player/classes/models/character_class.dart';
import 'package:rpg_companion/features/player/spells/models/spell.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_builder.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_data.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_pages_wrap.dart';
import 'package:rpg_companion/features/player/spell_tags/models/spell_tag.dart';
import 'package:rpg_companion/shell/rpg_shell_app_bar.dart';

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

class _SpellDetailPageState extends State<SpellDetailPage>
    with RpgShellRecordDetailPage {
  bool _deleting = false;

  static final _spellIcon =
      IconRegistry.instance.getIconData('Wand Magic Sparkles') ??
          Icons.auto_fix_high_outlined;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      syncShellDetailAppBar(
        title: widget.spell?.name ?? 'Spell',
        actions: widget.spell == null ? null : _actionsFor(widget.spell!),
      );
      context.read<RecordBloc>().add(
            GetRecordRequested(recordType: 'spells', recordId: widget.spellId),
          );
    });
  }

  @override
  void dispose() {
    disposeShellDetailAppBar();
    super.dispose();
  }

  List<Widget> _actionsFor(Spell spell) {
    return RpgShellAppBar.editDeleteActions(
      onEdit: () => RpgNavigation.openSpellEdit(context, spell),
      onDelete: () => _deleteSpell(spell),
      deleting: _deleting,
    );
  }

  Future<void> _deleteSpell(Spell spell) async {
    final confirmed = await RpgShellAppBar.confirmDelete(
      context,
      title: 'Delete spell?',
      message: 'This will permanently delete "${spell.name}".',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    context.read<RecordBloc>().add(
          DeleteRecordRequested(
            recordType: 'spells',
            recordId: widget.spellId,
          ),
        );
    if (!mounted) return;
    RpgShellAppBar.popDetail(context);
  }

  bool _isDesktopPlatform() {
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
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
        if (spell != null) {
          syncShellDetailAppBar(
            title: spell.name,
            actions: _actionsFor(spell),
          );
        }

        if (spell == null) {
          return RpgDetailPageBody(
            icon: _spellIcon,
            loading: true,
            child: const SizedBox.shrink(),
          );
        }

        final sourceFile = _sourceFile(spell);
        final classes = _classes(spell);
        final tags = _tags(spell);
        final desktopScale = _isDesktopPlatform() ? 1.25 : 1.0;

        final data = SpellCardData(
          spell: spell,
          classNames: classes.map((c) => c.name).toList(),
          tagNames: tags.map((t) => t.name).toList(),
        );
        final bodyMarkdown = SpellCardData.combineBodyMarkdown(
          description: spell.description,
          higherLevels: spell.higherLevels,
        );
        final cards = buildSpellCards(
          data: data,
          bodyMarkdown: bodyMarkdown,
          cardScale: desktopScale,
        );

        return RpgDetailPageBody(
          icon: _spellIcon,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SpellCardPagesWrap(
                cards: cards,
                scaleFactor: desktopScale,
              ),
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
            ],
          ),
        );
      },
    );
  }
}
