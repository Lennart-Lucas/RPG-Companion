import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/records/typed_record_cache.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';
import 'package:rpg_companion/features/dm_tools/resources/services/resource_record_resolver.dart';
import 'package:rpg_companion/features/player/classes/models/character_class.dart';

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

class _ClassDetailPageState extends State<ClassDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RecordBloc>().add(
            GetRecordRequested(recordType: 'classes', recordId: widget.classId),
          );
    });
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
        final sourceFile =
            characterClass == null ? null : _sourceFile(characterClass);

        return Scaffold(
          appBar: AppBar(
            title: Text(characterClass?.name ?? 'Class'),
          ),
          body: characterClass == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      characterClass.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (characterClass.caster) ...[
                      const SizedBox(height: 12),
                      Chip(
                        avatar: const Icon(Icons.auto_fix_high_outlined, size: 18),
                        label: const Text('Caster'),
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
                  ],
                ),
        );
      },
    );
  }
}
