import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/records/record_list_refresh.dart';
import 'package:rpg_companion/core/records/typed_record_cache.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/models/author.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';
import 'package:rpg_companion/features/dm_tools/resources/services/resource_record_resolver.dart';
import 'package:rpg_companion/shell/rpg_shell_app_bar.dart';
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

class _FileDetailPageState extends State<FileDetailPage>
    with RpgShellRecordDetailPage {
  bool _deleting = false;

  static final _fileIcon =
      IconRegistry.instance.getIconData('Book') ?? Icons.insert_drive_file_outlined;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      syncShellDetailAppBar(
        title: widget.file?.name ?? 'File',
        actions: widget.file == null ? null : _actionsFor(widget.file!),
      );
      context.read<RecordBloc>().add(
            GetRecordRequested(recordType: 'files', recordId: widget.fileId),
          );
    });
  }

  @override
  void dispose() {
    disposeShellDetailAppBar();
    super.dispose();
  }

  List<Widget> _actionsFor(ResourceFile file) {
    return RpgShellAppBar.editDeleteActions(
      onEdit: () => RpgNavigation.openFileEdit(context, file),
      onDelete: () => _deleteFile(file),
      deleting: _deleting,
    );
  }

  Future<void> _deleteFile(ResourceFile file) async {
    final confirmed = await RpgShellAppBar.confirmDelete(
      context,
      title: 'Delete file?',
      message: 'This will permanently delete "${file.name}".',
    );
    if (!confirmed || !mounted) return;

    final bloc = context.read<RecordBloc>();
    final authorId = file.authorId;

    setState(() => _deleting = true);
    TypedRecordCache.instance.remove('files', widget.fileId);
    bloc.add(
      DeleteRecordRequested(
        recordType: 'files',
        recordId: widget.fileId,
      ),
    );
    forceRefreshFileQueries(bloc, authorId: authorId);
    if (!mounted) return;
    RpgShellAppBar.popDetail(context);
  }

  ResourceFile? _fileFromState(RecordState state) {
    if (widget.file != null) return widget.file;
    return resolveTypedRecord<ResourceFile>(
      state: state,
      recordType: 'files',
      id: widget.fileId,
    );
  }

  Author? _authorFromState(RecordState state, String? authorId) {
    if (authorId == null) return null;
    return resolveTypedRecord<Author>(
      state: state,
      recordType: 'authors',
      id: authorId,
    );
  }

  Future<void> _launchAddress(String address) async {
    final uri = Uri.tryParse(address);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordBloc, RecordState>(
      builder: (context, state) {
        final file = _fileFromState(state);
        if (file != null) {
          syncShellDetailAppBar(
            title: file.name,
            actions: _actionsFor(file),
          );
        }

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

        return RpgDetailPageBody(
          icon: _fileIcon,
          loading: file == null,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link),
                title: const Text('Address'),
                subtitle: Text(file!.address),
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
