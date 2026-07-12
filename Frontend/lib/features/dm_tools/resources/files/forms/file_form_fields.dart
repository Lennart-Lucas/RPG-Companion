import 'dart:async';

import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/ui/rpg_form_styles.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/models/author.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';
import 'package:rpg_companion/features/dm_tools/resources/services/resource_record_resolver.dart';
import 'package:rpg_companion/features/dm_tools/resources/widgets/transparent_form_panel.dart';

class FileFormFields extends StatelessWidget {
  const FileFormFields({super.key});

  @override
  Widget build(BuildContext context) {
    final fieldDecoration = RpgFormStyles.fieldDecoration(context);

    return TransparentFormPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnvilFormSection(
            title: 'Details',
            subtitle: 'File name and source address',
            padding: EdgeInsets.zero,
            spacing: RpgFormStyles.fieldSpacing,
            headerMarginTop: 16,
            headerMarginBottom: RpgFormStyles.sectionHeaderMarginBottom,
            children: [
              AnvilTextField(
                fieldKey: ResourceFileFormKeys.name,
                label: 'Name',
                isRequired: true,
                placeholder: 'File or resource name',
                decoration: fieldDecoration,
              ),
              AnvilTextField(
                fieldKey: ResourceFileFormKeys.address,
                label: 'Address',
                isRequired: true,
                placeholder: 'https://...',
                keyboardType: TextInputType.url,
                decoration: fieldDecoration,
              ),
            ],
          ),
          AnvilFormSection(
            title: 'Author',
            subtitle: 'Link this file to an author',
            padding: EdgeInsets.zero,
            showDivider: true,
            spacing: RpgFormStyles.fieldSpacing,
            headerMarginTop: RpgFormStyles.sectionHeaderMarginTop,
            headerMarginBottom: RpgFormStyles.sectionHeaderMarginBottom,
            children: const [
              AuthorPickerField(),
            ],
          ),
        ],
      ),
    );
  }
}

class AuthorPickerField extends StatefulWidget {
  const AuthorPickerField({super.key});

  @override
  State<AuthorPickerField> createState() => _AuthorPickerFieldState();
}

class _AuthorPickerFieldState extends State<AuthorPickerField> {
  RecordBloc? _recordBloc;
  StreamSubscription<RecordState>? _sub;
  List<Author> _authors = [];
  bool _isLoading = false;
  String? _queryKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = context.read<RecordBloc>();
    if (!identical(bloc, _recordBloc)) {
      _recordBloc = bloc;
      _sub?.cancel();
      _sub = bloc.stream.listen((_) => _syncAuthors(bloc.state));
      _loadAuthors();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _loadAuthors() {
    _queryKey = authorsListQuery.queryKey;
    setState(() => _isLoading = true);
    _recordBloc!.remoteCoordinator?.refreshQueryRecords(authorsListQuery);
    _syncAuthors(_recordBloc!.state);
  }

  void _syncAuthors(RecordState state) {
    final key = _queryKey;
    if (key == null) return;
    final cached = state.snapshot.queries[key];
    if (cached == null) return;
    final authors = resolveAuthors(state, authorsListQuery);
    if (!mounted) return;
    setState(() {
      _authors = authors;
      _isLoading = false;
    });
  }

  void _updateAuthor(String? authorId) {
    context.read<AnvilFormBloc>().add(
          AnvilFormFieldUpdated(
            ResourceFileFormKeys.authorId,
            authorId ?? '',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = context.select<AnvilFormBloc, String?>(
      (bloc) {
        final value = bloc.state.values[ResourceFileFormKeys.authorId];
        if (value == null) return null;
        final trimmed = value.toString().trim();
        return trimmed.isEmpty ? null : trimmed;
      },
    );
    final decoration = RpgFormStyles.fieldDecoration(context);

    return AnvilHoverableFieldShell(
      enabled: !_isLoading,
      decoration: decoration.copyWith(labelText: 'Author'),
      builder: (hoverDecoration) => InputDecorator(
        decoration: hoverDecoration,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            isExpanded: true,
            value: _authors.any((a) => a.id == selectedId) ? selectedId : null,
            hint: Text(_isLoading ? 'Loading authors...' : 'Select author'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('None'),
              ),
              for (final author in _authors)
                DropdownMenuItem<String?>(
                  value: author.id,
                  child: Text(author.name),
                ),
            ],
            onChanged: _isLoading ? null : _updateAuthor,
          ),
        ),
      ),
    );
  }
}
