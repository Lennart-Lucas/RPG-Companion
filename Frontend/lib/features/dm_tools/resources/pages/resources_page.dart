import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/models/author.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/widgets/author_list_tile.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/widgets/file_list_tile.dart';
import 'package:rpg_companion/features/dm_tools/resources/widgets/resources_expandable_fab.dart';

class ResourcesPage extends StatefulWidget {
  const ResourcesPage({super.key});

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage> {
  String? _selectedAuthorId;
  int _refreshNonce = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAuthors());
  }

  void _fetchAuthors() {
    context.read<RecordBloc>().add(QueryRecordsRequested(authorsListQuery));
  }

  void _fetchFilesForAuthor(String authorId) {
    context.read<RecordBloc>().add(
          QueryRecordsRequested(filesForAuthorQuery(authorId)),
        );
  }

  void _refreshAll() {
    setState(() => _refreshNonce++);
    _fetchAuthors();
    final selected = _selectedAuthorId;
    if (selected != null) {
      _fetchFilesForAuthor(selected);
    }
  }

  List<Author> _authorsFromState(RecordState state) {
    final cached = state.snapshot.queries[authorsListQuery.queryKey];
    if (cached == null) return const [];
    return cached.recordIds
        .map((id) => state.snapshot.records[id]?.record)
        .whereType<Author>()
        .toList();
  }

  List<ResourceFile> _filesFromState(RecordState state, String authorId) {
    final query = filesForAuthorQuery(authorId);
    final cached = state.snapshot.queries[query.queryKey];
    if (cached == null) return const [];
    return cached.recordIds
        .map((id) => state.snapshot.records[id]?.record)
        .whereType<ResourceFile>()
        .toList();
  }

  void _onAuthorTap(Author author) {
    setState(() {
      if (_selectedAuthorId == author.id) {
        _selectedAuthorId = null;
      } else {
        _selectedAuthorId = author.id;
        _fetchFilesForAuthor(author.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordBloc, RecordState>(
      buildWhen: (previous, current) =>
          previous.snapshot.queries[authorsListQuery.queryKey]?.version !=
              current.snapshot.queries[authorsListQuery.queryKey]?.version ||
          (_selectedAuthorId != null &&
              previous.snapshot.queries[
                      filesForAuthorQuery(_selectedAuthorId!).queryKey]
                  ?.version !=
                  current.snapshot.queries[
                          filesForAuthorQuery(_selectedAuthorId!).queryKey]
                      ?.version) ||
          _refreshNonce > 0,
      builder: (context, state) {
        final authors = _authorsFromState(state);
        final selectedId = _selectedAuthorId;
        final selectedFiles = selectedId == null
            ? const <ResourceFile>[]
            : _filesFromState(state, selectedId);

        return Scaffold(
          body: authors.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No authors yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add an author or file to start building your resource library.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: authors.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final author = authors[index];
                    final selected = author.id == selectedId;
                    final files = selected ? selectedFiles : const <ResourceFile>[];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AuthorListTile(
                          author: author,
                          selected: selected,
                          onTap: () => _onAuthorTap(author),
                          onLongPress: () =>
                              RpgNavigation.openAuthorDetail(context, author),
                        ),
                        if (selected) ...[
                          const SizedBox(height: 8),
                          if (files.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'No files for this author yet.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          else
                            ...files.map(
                              (file) => Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  bottom: 8,
                                ),
                                child: FileListTile(
                                  file: file,
                                  onTap: () => RpgNavigation.openFileDetail(
                                    context,
                                    file,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    );
                  },
                ),
          floatingActionButton: ResourcesExpandableFab(
            selectedAuthorId: _selectedAuthorId,
            onChanged: _refreshAll,
          ),
        );
      },
    );
  }
}
