import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/models/author.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/widgets/file_list_tile.dart';
import 'package:rpg_companion/features/dm_tools/resources/services/resource_record_resolver.dart';
import 'package:rpg_companion/shell/rpg_shell_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthorDetailPage extends StatefulWidget {
  const AuthorDetailPage({
    super.key,
    required this.authorId,
    this.author,
  });

  final RecordId authorId;
  final Author? author;

  @override
  State<AuthorDetailPage> createState() => _AuthorDetailPageState();
}

class _AuthorDetailPageState extends State<AuthorDetailPage>
    with RpgShellRecordDetailPage {
  bool _deleting = false;

  static final _authorIcon =
      IconRegistry.instance.getIconData('Book') ?? Icons.menu_book_outlined;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      syncShellDetailAppBar(
        title: widget.author?.name ?? 'Author',
        actions:
            widget.author == null ? null : _actionsFor(widget.author!),
      );
      final bloc = context.read<RecordBloc>();
      bloc.add(
        GetRecordRequested(recordType: 'authors', recordId: widget.authorId),
      );
      bloc.remoteCoordinator?.refreshQueryRecords(
        filesForAuthorQuery(widget.authorId),
      );
    });
  }

  @override
  void dispose() {
    disposeShellDetailAppBar();
    super.dispose();
  }

  List<Widget> _actionsFor(Author author) {
    return RpgShellAppBar.editDeleteActions(
      onEdit: () => RpgNavigation.openAuthorEdit(context, author),
      onDelete: () => _deleteAuthor(author),
      deleting: _deleting,
    );
  }

  Future<void> _deleteAuthor(Author author) async {
    final confirmed = await RpgShellAppBar.confirmDelete(
      context,
      title: 'Delete author?',
      message: 'This will permanently delete "${author.name}".',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    context.read<RecordBloc>().add(
          DeleteRecordRequested(
            recordType: 'authors',
            recordId: widget.authorId,
          ),
        );
    if (!mounted) return;
    RpgShellAppBar.popDetail(context);
  }

  Author? _authorFromState(RecordState state) {
    if (widget.author != null) return widget.author;
    return resolveTypedRecord<Author>(
      state: state,
      recordType: 'authors',
      id: widget.authorId,
    );
  }

  List<ResourceFile> _filesFromState(RecordState state) {
    return resolveResourceFiles(state, filesForAuthorQuery(widget.authorId));
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordBloc, RecordState>(
      buildWhen: (previous, current) =>
          queryRecordsDisplayChanged(
            previous: previous,
            current: current,
            query: filesForAuthorQuery(widget.authorId),
            recordType: 'files',
          ) ||
          previous.snapshot.records[widget.authorId]?.version !=
              current.snapshot.records[widget.authorId]?.version,
      builder: (context, state) {
        final author = _authorFromState(state);
        if (author != null) {
          syncShellDetailAppBar(
            title: author.name,
            actions: _actionsFor(author),
          );
        }

        final files = _filesFromState(state);

        return RpgDetailPageBody(
          icon: _authorIcon,
          loading: author == null,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (author!.links.isNotEmpty) ...[
                Text(
                  'Links',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...author.links.map(
                  (link) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.link),
                    title: Text(AuthorSourceOptions.labelFor(link.source)),
                    subtitle: Text(link.url),
                    onTap: () => _launchUrl(link.url),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                'Files',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (files.isEmpty)
                Text(
                  'No files linked to this author yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...files.map(
                  (file) => FileListTile(
                    file: file,
                    onTap: () => RpgNavigation.openFileDetail(context, file),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
