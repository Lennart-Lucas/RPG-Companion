import 'dart:async';

import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/core/ui/rpg_form_styles.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';
import 'package:rpg_companion/features/dm_tools/resources/services/resource_record_resolver.dart';
import 'package:rpg_companion/features/dm_tools/resources/widgets/transparent_form_panel.dart';
import 'package:rpg_companion/features/player/classes/models/character_class.dart';
import 'package:rpg_companion/features/player/services/player_record_resolver.dart';
import 'package:rpg_companion/features/player/spells/models/spell.dart';
import 'package:rpg_companion/features/player/spell_tags/models/spell_tag.dart';
import 'package:rpg_companion/core/markdown/fields/markdown_wiki_field.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_preview.dart';

class SpellFormFields extends StatelessWidget {
  const SpellFormFields({super.key});

  @override
  Widget build(BuildContext context) {
    final fieldDecoration = RpgFormStyles.fieldDecoration(context);

    return TransparentFormPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SpellCardPreview(),
          const SizedBox(height: 24),
          AnvilFormSection(
            title: 'Identity',
            padding: EdgeInsets.zero,
            spacing: RpgFormStyles.fieldSpacing,
            headerMarginTop: 16,
            headerMarginBottom: RpgFormStyles.sectionHeaderMarginBottom,
            children: [
              AnvilTextField(
                fieldKey: SpellFormKeys.name,
                label: 'Name',
                isRequired: true,
                placeholder: 'Spell name',
                decoration: fieldDecoration,
              ),
              _FormFieldRow(
                children: [
                  AnvilDropdownField<String>(
                    fieldKey: SpellFormKeys.level,
                    label: 'Level',
                    isRequired: true,
                    options: SpellLevels.options,
                    decoration: fieldDecoration,
                  ),
                  AnvilDropdownField<String>(
                    fieldKey: SpellFormKeys.school,
                    label: 'School',
                    isRequired: true,
                    options: SpellSchools.options,
                    decoration: fieldDecoration,
                  ),
                ],
              ),
              const SourceFilePickerField(fieldKey: SpellFormKeys.fileId),
            ],
          ),
          AnvilFormSection(
            title: 'Casting',
            padding: EdgeInsets.zero,
            showDivider: true,
            spacing: RpgFormStyles.fieldSpacing,
            headerMarginTop: RpgFormStyles.sectionHeaderMarginTop,
            headerMarginBottom: RpgFormStyles.sectionHeaderMarginBottom,
            children: [
              _FormFieldRow(
                children: [
                  AnvilNumberField(
                    fieldKey: SpellFormKeys.castingTime,
                    label: 'Casting time',
                    isRequired: true,
                    isInteger: true,
                    min: 1,
                    decoration: fieldDecoration,
                  ),
                  AnvilDropdownField<String>(
                    fieldKey: SpellFormKeys.castingType,
                    label: 'Casting type',
                    isRequired: true,
                    options: CastingTypes.options,
                    decoration: fieldDecoration,
                  ),
                ],
              ),
              const _TriggerField(),
              _FormFieldRow(
                children: [
                  AnvilDropdownField<String>(
                    fieldKey: SpellFormKeys.duration,
                    label: 'Duration',
                    isRequired: true,
                    options: SpellDurations.options,
                    decoration: fieldDecoration,
                  ),
                  const AnvilSwitchField(
                    fieldKey: SpellFormKeys.concentration,
                    label: 'Concentration',
                  ),
                  AnvilDropdownField<String>(
                    fieldKey: SpellFormKeys.range,
                    label: 'Range',
                    isRequired: true,
                    options: SpellRanges.options,
                    decoration: fieldDecoration,
                  ),
                ],
              ),
            ],
          ),
          AnvilFormSection(
            title: 'Components',
            padding: EdgeInsets.zero,
            showDivider: true,
            spacing: RpgFormStyles.fieldSpacing,
            headerMarginTop: RpgFormStyles.sectionHeaderMarginTop,
            headerMarginBottom: RpgFormStyles.sectionHeaderMarginBottom,
            children: const [
              _ComponentPickerField(),
              _MaterialsField(),
            ],
          ),
          AnvilFormSection(
            title: 'Classes & tags',
            padding: EdgeInsets.zero,
            showDivider: true,
            spacing: RpgFormStyles.fieldSpacing,
            headerMarginTop: RpgFormStyles.sectionHeaderMarginTop,
            headerMarginBottom: RpgFormStyles.sectionHeaderMarginBottom,
            children: const [
              CasterClassPickerField(),
              SpellTagPickerField(),
            ],
          ),
          AnvilFormSection(
            title: 'Description',
            padding: EdgeInsets.zero,
            showDivider: true,
            spacing: RpgFormStyles.fieldSpacing,
            headerMarginTop: RpgFormStyles.sectionHeaderMarginTop,
            headerMarginBottom: RpgFormStyles.sectionHeaderMarginBottom,
            children: const [
              RpgMarkdownWikiField(
                fieldKey: SpellFormKeys.description,
                label: 'Description',
                minLines: 6,
                showPreview: false,
              ),
              RpgMarkdownWikiField(
                fieldKey: SpellFormKeys.higherLevels,
                label: 'At higher levels',
                minLines: 4,
                showPreview: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormFieldRow extends StatelessWidget {
  const _FormFieldRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: RpgFormStyles.fieldSpacing),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class SourceFilePickerField extends StatefulWidget {
  const SourceFilePickerField({super.key, required this.fieldKey});

  final String fieldKey;

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
          AnvilFormFieldUpdated(widget.fieldKey, fileId ?? ''),
        );
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = context.select<AnvilFormBloc, String?>(
      (bloc) {
        final value = bloc.state.values[widget.fieldKey];
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

class _TriggerField extends StatelessWidget {
  const _TriggerField();

  @override
  Widget build(BuildContext context) {
    final isReaction = context.select<AnvilFormBloc, bool>(
      (bloc) =>
          bloc.state.values[SpellFormKeys.castingType] == CastingTypes.reaction,
    );

    return AnvilTextField(
      fieldKey: SpellFormKeys.trigger,
      label: 'Trigger',
      placeholder: 'When you are hit by an attack...',
      enabled: isReaction,
      decoration: RpgFormStyles.fieldDecoration(context),
    );
  }
}

class _FormMultiSelectDropdown extends StatefulWidget {
  const _FormMultiSelectDropdown({
    required this.selectedIds,
    required this.options,
    required this.onToggle,
    required this.decoration,
    this.placeholder = 'Select...',
  });

  final List<String> selectedIds;
  final List<({String id, String label})> options;
  final ValueChanged<String> onToggle;
  final InputDecoration decoration;
  final String placeholder;

  @override
  State<_FormMultiSelectDropdown> createState() =>
      _FormMultiSelectDropdownState();
}

class _FormMultiSelectDropdownState extends State<_FormMultiSelectDropdown> {
  final GlobalKey _anchorKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _closeMenu();
    super.dispose();
  }

  String get _displayText {
    if (widget.selectedIds.isEmpty) return widget.placeholder;
    final labels = widget.options
        .where((option) => widget.selectedIds.contains(option.id))
        .map((option) => option.label);
    return labels.join(', ');
  }

  void _handleToggle(String optionId) {
    widget.onToggle(optionId);
    _scheduleOverlayRebuild();
  }

  void _scheduleOverlayRebuild() {
    if (_overlayEntry == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _overlayEntry == null) return;
      _overlayEntry!.markNeedsBuild();
    });
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onFieldTap() {
    if (_overlayEntry != null) {
      _closeMenu();
      return;
    }
    _openMenu();
  }

  void _openMenu() {
    final anchorContext = _anchorKey.currentContext;
    final renderBox = anchorContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final topLeft = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final width = renderBox.size.width;
    final menuTop = renderBox.localToGlobal(
      renderBox.size.bottomRight(Offset.zero),
      ancestor: overlay,
    ).dy;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final theme = Theme.of(overlayContext);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeMenu,
              ),
            ),
            Positioned(
              left: topLeft.dx,
              top: menuTop,
              width: width,
              child: Material(
                elevation: 4,
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final option in widget.options)
                      InkWell(
                        onTap: () => _handleToggle(option.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                widget.selectedIds.contains(option.id)
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                size: 20,
                                color: theme.colorScheme.onSurface,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  option.label,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = widget.selectedIds.isNotEmpty;
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: hasSelection
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return InputDecorator(
      key: _anchorKey,
      decoration: widget.decoration,
      child: InkWell(
        onTap: _onFieldTap,
        child: Row(
          children: [
            Expanded(
              child: Text(
                _displayText,
                style: textStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComponentPickerField extends StatelessWidget {
  const _ComponentPickerField();

  static const _options = [
    (id: 'v', label: 'Verbal (V)'),
    (id: 's', label: 'Somatic (S)'),
    (id: 'm', label: 'Material (M)'),
  ];

  void _toggle(BuildContext context, String componentId) {
    final bloc = context.read<AnvilFormBloc>();
    final values = bloc.state.values;
    final key = switch (componentId) {
      'v' => SpellFormKeys.componentVerbal,
      's' => SpellFormKeys.componentSomatic,
      'm' => SpellFormKeys.componentMaterial,
      _ => throw ArgumentError.value(componentId, 'componentId'),
    };
    final isSelected = values[key] as bool? ?? false;
    bloc.add(AnvilFormFieldUpdated(key, !isSelected));
    if (componentId == 'm' && isSelected) {
      bloc.add(const AnvilFormFieldUpdated(SpellFormKeys.materials, ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIds = context.select<AnvilFormBloc, List<String>>((bloc) {
      final values = bloc.state.values;
      final selected = <String>[];
      if (values[SpellFormKeys.componentVerbal] as bool? ?? false) {
        selected.add('v');
      }
      if (values[SpellFormKeys.componentSomatic] as bool? ?? false) {
        selected.add('s');
      }
      if (values[SpellFormKeys.componentMaterial] as bool? ?? false) {
        selected.add('m');
      }
      return selected;
    });

    return AnvilFieldWrapper(
      fieldKey: SpellFormKeys.componentVerbal,
      label: 'Components',
      child: _FormMultiSelectDropdown(
        selectedIds: selectedIds,
        options: _options,
        onToggle: (id) => _toggle(context, id),
        decoration: RpgFormStyles.fieldDecoration(context),
        placeholder: 'Select components',
      ),
    );
  }
}

class _MaterialsField extends StatelessWidget {
  const _MaterialsField();

  @override
  Widget build(BuildContext context) {
    final hasMaterial = context.select<AnvilFormBloc, bool>(
      (bloc) =>
          bloc.state.values[SpellFormKeys.componentMaterial] as bool? ?? false,
    );

    return AnvilTextField(
      fieldKey: SpellFormKeys.materials,
      label: 'Materials',
      placeholder: 'Describe material components',
      enabled: hasMaterial,
      decoration: RpgFormStyles.fieldDecoration(context),
      minLines: 2,
      maxLines: 4,
    );
  }
}

class CasterClassPickerField extends StatefulWidget {
  const CasterClassPickerField({super.key});

  @override
  State<CasterClassPickerField> createState() => _CasterClassPickerFieldState();
}

class _CasterClassPickerFieldState extends State<CasterClassPickerField> {
  RecordBloc? _recordBloc;
  StreamSubscription<RecordState>? _sub;
  List<CharacterClass> _classes = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = context.read<RecordBloc>();
    if (!identical(bloc, _recordBloc)) {
      _recordBloc = bloc;
      _sub?.cancel();
      _sub = bloc.stream.listen((_) => _syncClasses(bloc.state));
      bloc.remoteCoordinator?.refreshQueryRecords(classesListQuery);
      _syncClasses(bloc.state);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _syncClasses(RecordState state) {
    final classes = resolveClasses(state, classesListQuery)
        .where((characterClass) => characterClass.caster)
        .toList();
    if (!mounted) return;
    setState(() => _classes = classes);
  }

  @override
  Widget build(BuildContext context) {
    if (_classes.isEmpty) {
      return Text(
        'No caster classes available. Create a class with Caster enabled first.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return _FormChipSelectionField(
      fieldKey: SpellFormKeys.classIds,
      label: 'Classes',
      isRequired: true,
      options: [
        for (final characterClass in _classes)
          (id: characterClass.id, label: characterClass.name),
      ],
    );
  }
}

class _FormChipSelectionField extends StatelessWidget {
  const _FormChipSelectionField({
    required this.fieldKey,
    required this.label,
    required this.options,
    this.isRequired = false,
  });

  final String fieldKey;
  final String label;
  final List<({String id, String label})> options;
  final bool isRequired;

  void _toggle(BuildContext context, String optionId) {
    final bloc = context.read<AnvilFormBloc>();
    final raw = bloc.state.values[fieldKey];
    final current =
        raw is List ? raw.map((id) => id.toString()).toList() : <String>[];
    final next = List<String>.from(current);
    if (next.contains(optionId)) {
      next.remove(optionId);
    } else {
      next.add(optionId);
    }
    bloc.add(AnvilFormFieldUpdated(fieldKey, next));
  }

  @override
  Widget build(BuildContext context) {
    final selectedIds = context.select<AnvilFormBloc, List<String>>((bloc) {
      final raw = bloc.state.values[fieldKey];
      if (raw is! List) return const [];
      return raw.map((id) => id.toString()).toList();
    });

    return AnvilFieldWrapper(
      fieldKey: fieldKey,
      label: label,
      isRequired: isRequired,
      child: _StyledChipWrap(
        options: options,
        selectedIds: selectedIds,
        onToggle: (id) => _toggle(context, id),
      ),
    );
  }
}

class _StyledChipWrap extends StatelessWidget {
  const _StyledChipWrap({
    required this.options,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<({String id, String label})> options;
  final List<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final fillColor = RpgFormStyles.fieldFillColor(context);
    final selectedColor = RpgFormStyles.submitButtonColor(context);
    final selectedForeground =
        RpgFormStyles.submitButtonForegroundColor(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    const chipShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
    );

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final option in options)
          FilterChip(
            label: Text(option.label),
            selected: selectedIds.contains(option.id),
            showCheckmark: false,
            onSelected: (_) => onToggle(option.id),
            backgroundColor: fillColor,
            selectedColor: selectedColor,
            labelStyle: TextStyle(
              color: selectedIds.contains(option.id)
                  ? selectedForeground
                  : onSurface,
              fontWeight: selectedIds.contains(option.id)
                  ? FontWeight.w600
                  : FontWeight.w500,
            ),
            shape: chipShape,
            side: BorderSide.none,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }
}

class SpellTagPickerField extends StatefulWidget {
  const SpellTagPickerField({super.key});

  @override
  State<SpellTagPickerField> createState() => _SpellTagPickerFieldState();
}

class _SpellTagPickerFieldState extends State<SpellTagPickerField> {
  RecordBloc? _recordBloc;
  StreamSubscription<RecordState>? _sub;
  List<SpellTag> _tags = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = context.read<RecordBloc>();
    if (!identical(bloc, _recordBloc)) {
      _recordBloc = bloc;
      _sub?.cancel();
      _sub = bloc.stream.listen((_) => _syncTags(bloc.state));
      bloc.remoteCoordinator?.refreshQueryRecords(spellTagsListQuery);
      _syncTags(bloc.state);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _syncTags(RecordState state) {
    final tags = resolveSpellTags(state, spellTagsListQuery);
    if (!mounted) return;
    setState(() => _tags = tags);
  }

  @override
  Widget build(BuildContext context) {
    if (_tags.isEmpty) {
      return Text(
        'No spell tags yet. Use the FAB to create tags.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return _FormChipSelectionField(
      fieldKey: SpellFormKeys.spellTagIds,
      label: 'Tags',
      options: [
        for (final tag in _tags) (id: tag.id, label: tag.name),
      ],
    );
  }
}
