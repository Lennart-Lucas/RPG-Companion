import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rpg_companion/core/records/record_list_refresh.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/forms/file_form_config.dart';

class FileCreatePage extends StatelessWidget {
  const FileCreatePage({super.key, this.authorId});

  final RecordId? authorId;

  String? _authorIdFromResult(dynamic data) {
    if (data is! Map) return null;
    final raw = data['author_id'];
    if (raw == null) return null;
    final id = raw.toString().trim();
    return id.isEmpty ? null : id;
  }

  @override
  Widget build(BuildContext context) {
    final recordBloc = context.read<RecordBloc>();
    final iconData =
        IconRegistry.instance.getIconData('Book') ?? Icons.insert_drive_file_outlined;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New file'),
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
            createOverrides: {
              if (authorId != null) 'author_id': authorId,
            },
          ),
          submitLabel: 'Create file',
          onCancel: () => context.pop(),
          onSubmitSuccess: (result) {
            final linkedAuthorId =
                _authorIdFromResult(result.data) ?? authorId?.toString();
            forceRefreshFileQueries(recordBloc, authorId: linkedAuthorId);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File created')),
            );
            context.pop(linkedAuthorId);
          },
        ),
      ),
    );
  }
}
