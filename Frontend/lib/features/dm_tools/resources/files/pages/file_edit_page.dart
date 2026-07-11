import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rpg_companion/core/records/record_list_refresh.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/forms/file_form_config.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';

class FileEditPage extends StatelessWidget {
  const FileEditPage({
    super.key,
    required this.fileId,
    this.file,
  });

  final RecordId fileId;
  final ResourceFile? file;

  Future<void> _refreshFiles(BuildContext context, ResourceFile? updated) {
    final bloc = context.read<RecordBloc>();
    final futures = <Future<void>>[
      refreshRecordQuery(bloc, filesListQuery),
    ];
    final authorId = updated?.authorId ?? file?.authorId;
    if (authorId != null && authorId.isNotEmpty) {
      futures.add(refreshRecordQuery(bloc, filesForAuthorQuery(authorId)));
    }
    return Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    final recordBloc = context.read<RecordBloc>();
    final iconData =
        IconRegistry.instance.getIconData('Book') ?? Icons.insert_drive_file_outlined;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit file'),
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(
              alpha: 0.85,
            ),
      ),
      body: AnvilBackgroundIcon(
        icon: iconData,
        opacity: 0.32,
        baseSize: 260,
        child: AnvilForm(
          config: buildFileFormConfig(
            recordBloc,
            recordId: fileId,
            preloadedFile: file,
          ),
          submitLabel: 'Save file',
          onCancel: () => context.pop(),
          onSubmitSuccess: (_) async {
            await _refreshFiles(context, file);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File saved')),
            );
            context.pop();
          },
        ),
      ),
    );
  }
}
