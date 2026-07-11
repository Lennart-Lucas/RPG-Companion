import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/models/author.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';
import 'package:url_launcher/url_launcher.dart';

class FileDetailPage extends StatefulWidget {
  const FileDetailPage({
    super.key,
    required this.fileId,
    this.file,
  });

  final RecordId fileId;
  final ResourceFile? file;

  @override
  State<FileDetailPage> createState() => _FileDetailPageState();
}

class _FileDetailPageState extends State<FileDetailPage> {
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RecordBloc>().add(
            GetRecordRequested(recordType: 'files', recordId: widget.fileId),
          );
    });
  }

  ResourceFile? _fileFromState(RecordState state) {
    if (widget.file != null) return widget.file;
    final entry = state.snapshot.records[widget.fileId];
    if (entry != null &&
        !entry.isDeleted &&
        entry.record is ResourceFile) {
      return entry.record as ResourceFile;
    }
    return null;
  }

  Author? _authorFromState(RecordState state, String? authorId) {
    if (authorId == null) return null;
    final entry = state.snapshot.records[authorId];
    if (entry != null && entry.record is Author) {
      return entry.record as Author;
    }
    return null;
  }

  Future<void> _launchAddress(String address) async {
    final uri = Uri.tryParse(address);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _deleteFile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete file?'),
        content: const Text('This will remove the file from your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    context.read<RecordBloc>().add(
          DeleteRecordRequested(
            recordType: 'files',
            recordId: widget.fileId,
          ),
        );
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordBloc, RecordState>(
      builder: (context, state) {
        final file = _fileFromState(state);
        final author = _authorFromState(state, file?.authorId);

        if (file?.authorId != null && author == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.read<RecordBloc>().add(
                  GetRecordRequested(
                    recordType: 'authors',
                    recordId: file!.authorId!,
                  ),
                );
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(file?.name ?? 'File'),
            actions: [
              if (file != null)
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => RpgNavigation.openFileEdit(context, file),
                  icon: const Icon(Icons.edit_outlined),
                ),
              IconButton(
                tooltip: 'Delete',
                onPressed: _deleting ? null : _deleteFile,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: file == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      file.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.link),
                      title: const Text('Address'),
                      subtitle: Text(file.address),
                      onTap: () => _launchAddress(file.address),
                    ),
                    if (author != null) ...[
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Author'),
                        subtitle: Text(author.name),
                        onTap: () =>
                            RpgNavigation.openAuthorDetail(context, author),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}
