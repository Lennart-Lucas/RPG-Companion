import 'dart:async';

import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/core/ui/rpg_form_styles.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';
import 'package:rpg_companion/features/dm_tools/resources/services/resource_record_resolver.dart';
import 'package:rpg_companion/features/player/classes/models/character_class.dart';
import 'package:rpg_companion/features/dm_tools/resources/widgets/transparent_form_panel.dart';

class ClassFormFields extends StatelessWidget {
  const ClassFormFields({super.key});

  @override
  Widget build(BuildContext context) {
    final fieldDecoration = RpgFormStyles.fieldDecoration(context);

    return TransparentFormPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnvilFormSection(
            title: 'Details',
            subtitle: 'Class name and source material',
            padding: EdgeInsets.zero,
            spacing: RpgFormStyles.fieldSpacing,
            headerMarginTop: 16,
            headerMarginBottom: RpgFormStyles.sectionHeaderMarginBottom,
            children: [
              AnvilTextField(
                fieldKey: CharacterClassFormKeys.name,
                label: 'Name',
                isRequired: true,
                placeholder: 'Class name',
                decoration: fieldDecoration,
              ),
              const SourceFilePickerField(),
            ],
          ),
          AnvilFormSection(
            title: 'Type',
            padding: EdgeInsets.zero,
            showDivider: true,
            spacing: RpgFormStyles.fieldSpacing,
            headerMarginTop: RpgFormStyles.sectionHeaderMarginTop,
            headerMarginBottom: RpgFormStyles.sectionHeaderMarginBottom,
            children: const [
              AnvilCheckboxField(
                fieldKey: CharacterClassFormKeys.caster,
                label: 'Caster',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SourceFilePickerField extends StatefulWidget {
  const SourceFilePickerField({super.key});

  @override
  State<SourceFilePickerField> createState() => _SourceFilePickerFieldState();
}

class _SourceFilePickerFieldState extends State<SourceFilePickerField> {
  RecordBloc? _recordBloc;
  StreamSubscription<RecordState>? _sub;
  List<ResourceFile> _files = [];
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = context.read<RecordBloc>();
    if (!identical(bloc, _recordBloc)) {
      _recordBloc = bloc;
      _sub?.cancel();
      _sub = bloc.stream.listen((_) => _syncFiles(bloc.state));
      _loadFiles();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _loadFiles() {
    setState(() => _isLoading = true);
    _recordBloc!.remoteCoordinator?.refreshQueryRecords(filesListQuery);
    _syncFiles(_recordBloc!.state);
  }

  void _syncFiles(RecordState state) {
    final files = resolveResourceFiles(state, filesListQuery);
    if (!mounted) return;
    setState(() {
      _files = files;
      _isLoading = false;
    });
  }

  void _updateFile(String? fileId) {
    context.read<AnvilFormBloc>().add(
          AnvilFormFieldUpdated(
            CharacterClassFormKeys.fileId,
            fileId ?? '',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = context.select<AnvilFormBloc, String?>(
      (bloc) {
        final value = bloc.state.values[CharacterClassFormKeys.fileId];
        if (value == null) return null;
        final trimmed = value.toString().trim();
        return trimmed.isEmpty ? null : trimmed;
      },
    );
    final decoration = RpgFormStyles.fieldDecoration(context);

    return InputDecorator(
      decoration: decoration.copyWith(labelText: 'Source'),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: _files.any((file) => file.id == selectedId) ? selectedId : null,
          hint: Text(_isLoading ? 'Loading files...' : 'Select file'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('None'),
            ),
            for (final file in _files)
              DropdownMenuItem<String?>(
                value: file.id,
                child: Text(file.name),
              ),
          ],
          onChanged: _isLoading ? null : _updateFile,
        ),
      ),
    );
  }
}
