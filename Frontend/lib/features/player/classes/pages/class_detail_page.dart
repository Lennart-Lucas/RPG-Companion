import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';
import 'package:rpg_companion/core/records/typed_record_cache.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';
import 'package:rpg_companion/features/dm_tools/resources/services/resource_record_resolver.dart';
import 'package:rpg_companion/features/player/classes/models/character_class.dart';
import 'package:rpg_companion/shell/rpg_shell_app_bar.dart';

class ClassDetailPage extends StatefulWidget {
  const ClassDetailPage({
    super.key,
    required this.classId,
    this.characterClass,
  });

  final RecordId classId;
  final CharacterClass? characterClass;

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage>
    with RpgShellRecordDetailPage {
  bool _deleting = false;

  static final _classIcon =
      IconRegistry.instance.getIconData('Graduation Cap') ??
          Icons.school_outlined;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      syncShellDetailAppBar(
        title: widget.characterClass?.name ?? 'Class',
        actions: widget.characterClass == null
            ? null
            : _actionsFor(widget.characterClass!),
      );
      context.read<RecordBloc>().add(
            GetRecordRequested(recordType: 'classes', recordId: widget.classId),
          );
    });
  }

  @override
  void dispose() {
    disposeShellDetailAppBar();
    super.dispose();
  }

  List<Widget> _actionsFor(CharacterClass characterClass) {
    return RpgShellAppBar.editDeleteActions(
      onEdit: () => RpgNavigation.openClassEdit(context, characterClass),
      onDelete: () => _deleteClass(characterClass),
      deleting: _deleting,
    );
  }

  Future<void> _deleteClass(CharacterClass characterClass) async {
    final confirmed = await RpgShellAppBar.confirmDelete(
      context,
      title: 'Delete class?',
      message: 'This will permanently delete "${characterClass.name}".',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    context.read<RecordBloc>().add(
          DeleteRecordRequested(
            recordType: 'classes',
            recordId: widget.classId,
          ),
        );
    if (!mounted) return;
    RpgShellAppBar.popDetail(context);
  }

  CharacterClass? _classFromState(RecordState state) {
    if (widget.characterClass != null) return widget.characterClass;
    return resolveTypedRecord<CharacterClass>(
      state: state,
      recordType: 'classes',
      id: widget.classId,
    );
  }

  ResourceFile? _sourceFile(CharacterClass characterClass) {
    final fileId = characterClass.fileId;
    if (fileId == null || fileId.isEmpty) return null;
    return TypedRecordCache.instance.get<ResourceFile>('files', fileId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordBloc, RecordState>(
      builder: (context, state) {
        final characterClass = _classFromState(state);
        if (characterClass != null) {
          syncShellDetailAppBar(
            title: characterClass.name,
            actions: _actionsFor(characterClass),
          );
        }

        final sourceFile =
            characterClass == null ? null : _sourceFile(characterClass);

        return RpgDetailPageBody(
          icon: _classIcon,
          loading: characterClass == null,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (characterClass!.caster) ...[
                Chip(
                  avatar:
                      const Icon(Icons.auto_fix_high_outlined, size: 18),
                  label: const Text('Caster'),
                ),
                const SizedBox(height: 16),
              ],
              if (sourceFile != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: const Text('Source'),
                  subtitle: Text(sourceFile.name),
                  onTap: () =>
                      RpgNavigation.openFileDetail(context, sourceFile),
                ),
            ],
          ),
        );
      },
    );
  }
}
