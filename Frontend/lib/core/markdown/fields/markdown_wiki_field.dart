import 'dart:async';

import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/markdown/damage_type_auto_link.dart';
import 'package:rpg_companion/core/markdown/linkable_record_registry.dart';
import 'package:rpg_companion/core/markdown/markdown_wiki_preview.dart';
import 'package:rpg_companion/core/markdown/record_link_index.dart';
import 'package:rpg_companion/core/ui/rpg_form_styles.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/features/player/services/player_record_resolver.dart';

/// Markdown editor with formatting toolbar, wiki-link autocomplete, and preview.
class RpgMarkdownWikiField extends StatefulWidget {
  const RpgMarkdownWikiField({
    super.key,
    required this.fieldKey,
    this.label,
    this.isRequired = false,
    this.enabled = true,
    this.minLines = 6,
    this.maxLines,
    this.placeholder = 'Start typing...',
    this.showPreview = true,
    this.autoLinkDamageTypes = false,
    this.decoration,
    this.onChanged,
  });

  final String fieldKey;
  final String? label;
  final bool isRequired;
  final bool enabled;
  final int minLines;
  final int? maxLines;
  final String? placeholder;
  final bool showPreview;
  final bool autoLinkDamageTypes;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;

  @override
  State<RpgMarkdownWikiField> createState() => _RpgMarkdownWikiFieldState();
}

class _RpgMarkdownWikiFieldState extends State<RpgMarkdownWikiField>
    with AnvilFieldAccess<RpgMarkdownWikiField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldAnchorKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  StreamSubscription<RecordState>? _recordSub;
  List<IndexedLinkableRecord> _linkableRecords = const [];
  WikiLinkAutocompleteContext? _autocompleteContext;
  int? _autocompleteCursor;
  Timer? _overlayDismissTimer;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prefetchLinkableRecords();
      _syncFromBlocIfNeeded();
    });
  }

  @override
  void dispose() {
    _overlayDismissTimer?.cancel();
    _removeOverlay();
    _recordSub?.cancel();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _prefetchLinkableRecords() {
    final bloc = context.read<RecordBloc>();
    for (final config in LinkableRecordRegistry.linkableConfigs) {
      bloc.remoteCoordinator?.refreshQueryRecords(config.listQuery);
    }
    _recordSub?.cancel();
    _recordSub = bloc.stream.listen((state) {
      final entries = RecordLinkIndex.buildFromState(state);
      if (!mounted) return;
      setState(() => _linkableRecords = entries);
      _updateOverlay();
    });
    setState(() {
      _linkableRecords = RecordLinkIndex.buildFromState(bloc.state);
    });
  }

  void _syncFromBlocIfNeeded() {
    final value = context.read<AnvilFormBloc>().state.values[widget.fieldKey];
    if (value is String && value != _controller.text) {
      _controller.text = value;
    }
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _overlayDismissTimer?.cancel();
      return;
    }

    // Defer dismissal so overlay row taps can complete before the entry is removed.
    _overlayDismissTimer?.cancel();
    _overlayDismissTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted || _focusNode.hasFocus) return;
      _removeOverlay();
      _autocompleteContext = null;
      _autocompleteCursor = null;
    });
  }

  void _onChanged(String value) {
    updateField(widget.fieldKey, value);
    widget.onChanged?.call(value);
    _updateAutocomplete(value);
    if (mounted) setState(() {});
  }

  void _updateAutocomplete(String value) {
    final selection = _controller.selection;
    if (!selection.isValid || !selection.isCollapsed) {
      _autocompleteContext = null;
      _removeOverlay();
      return;
    }

    final contextMatch = detectWikiLinkAutocomplete(value, selection.baseOffset);
    _autocompleteContext = contextMatch;
    _autocompleteCursor = contextMatch == null ? null : selection.baseOffset;
    if (contextMatch == null || !_focusNode.hasFocus) {
      _removeOverlay();
      return;
    }
    _showOverlay();
  }

  void _showOverlay() {
    _removeOverlay();
    final contextMatch = _autocompleteContext;
    if (contextMatch == null) return;

    final overlay = Overlay.of(context);
    final matches = RecordLinkIndex.search(_linkableRecords, contextMatch.query);

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final anchor =
            _fieldAnchorKey.currentContext?.findRenderObject() as RenderBox?;
        if (anchor == null || !anchor.hasSize) {
          return const SizedBox.shrink();
        }

        final layout = computeOverlayDropdownLayout(
          context: overlayContext,
          anchor: anchor,
          preferredMaxHeight: 220,
        );
        final panelWidth = anchor.size.width;

        return Positioned(
          width: panelWidth,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: layout.offset,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: layout.maxHeight),
                child: matches.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _linkableRecords.isEmpty
                              ? 'Loading records...'
                              : 'No matching records',
                          style: Theme.of(overlayContext).textTheme.bodySmall,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final record = matches[index];
                          return Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (_) => _selectRecord(record),
                            child: ListTile(
                              dense: true,
                              title: Text(record.name),
                              subtitle: Text(record.typeLabel),
                              onTap: () => _selectRecord(record),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectRecord(IndexedLinkableRecord record) {
    final contextMatch = _autocompleteContext;
    if (contextMatch == null) return;

    _overlayDismissTimer?.cancel();

    final cursor = _autocompleteCursor ?? _controller.selection.baseOffset;
    if (cursor < 0 || cursor > _controller.text.length) return;

    final newText = insertWikiLink(
      text: _controller.text,
      tokenStart: contextMatch.tokenStart,
      cursorOffset: cursor,
      record: record,
    );
    final newCursor = cursorAfterWikiLinkInsert(contextMatch.tokenStart, record);

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    _autocompleteContext = null;
    _autocompleteCursor = null;
    _removeOverlay();
    _onChanged(newText);
    _focusNode.requestFocus();
  }

  void _wrapSelection(String before, String after) {
    final sel = _controller.selection;
    final text = _controller.text;
    if (!sel.isValid) return;

    final selected = sel.textInside(text);
    final newText = text.replaceRange(sel.start, sel.end, '$before$selected$after');
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: sel.start + before.length + selected.length + after.length,
      ),
    );
    _onChanged(newText);
  }

  void _insertPrefix(String prefix) {
    final sel = _controller.selection;
    final text = _controller.text;
    final lineStart =
        text.lastIndexOf('\n', sel.start > 0 ? sel.start - 1 : 0) + 1;
    final newText = text.replaceRange(lineStart, lineStart, prefix);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + prefix.length),
    );
    _onChanged(newText);
  }

  void _autoLinkDamageTypes() {
    final bloc = context.read<RecordBloc>();
    bloc.remoteCoordinator?.refreshQueryRecords(damageTypesListQuery);

    final damageTypes = resolveDamageTypes(bloc.state, damageTypesListQuery);
    if (damageTypes.isEmpty) return;

    final linkedText = linkDamageTypeMentions(_controller.text, damageTypes);
    if (linkedText == _controller.text) return;

    _controller.value = TextEditingValue(
      text: linkedText,
      selection: TextSelection.collapsed(offset: linkedText.length),
    );
    _onChanged(linkedText);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    selectFieldError(widget.fieldKey);

    return BlocListener<AnvilFormBloc, AnvilFormState>(
      listenWhen: (previous, current) {
        if (previous.isHydrating && !current.isHydrating) return true;
        if (_focusNode.hasFocus) return false;
        return previous.values[widget.fieldKey] !=
            current.values[widget.fieldKey];
      },
      listener: (context, state) {
        final value = state.values[widget.fieldKey];
        if (value is String && value != _controller.text) {
          _controller.text = value;
          if (mounted) setState(() {});
        }
      },
      child: AnvilFieldWrapper(
        fieldKey: widget.fieldKey,
        label: widget.label,
        isRequired: widget.isRequired,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListenableBuilder(
              listenable: _focusNode,
              builder: (context, _) {
                final baseDecoration =
                    widget.decoration ?? RpgFormStyles.fieldDecoration(context);
                final showHover =
                    widget.enabled && _hovered && !_focusNode.hasFocus;
                final decoration = AnvilFieldDecoration.withHoverState(
                  context,
                  baseDecoration,
                  hovered: showHover,
                );
                final hasToolbar = widget.enabled;

                return MouseRegion(
                  onEnter: widget.enabled
                      ? (_) => setState(() => _hovered = true)
                      : null,
                  onExit: widget.enabled
                      ? (_) => setState(() => _hovered = false)
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasToolbar)
                        _buildToolbar(
                          context,
                          decoration,
                          isFocused: _focusNode.hasFocus,
                        ),
                      CompositedTransformTarget(
                        key: _fieldAnchorKey,
                        link: _layerLink,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          enabled: widget.enabled,
                          minLines: widget.minLines,
                          maxLines: widget.maxLines,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: _textFieldDecoration(
                            context,
                            decoration,
                            hasToolbar: hasToolbar,
                          ),
                          onChanged: _onChanged,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (widget.showPreview) ...[
              const SizedBox(height: RpgFormStyles.fieldSpacing),
              MarkdownWikiPreview(
                source: _controller.text,
                decoration: widget.decoration,
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _textFieldDecoration(
    BuildContext context,
    InputDecoration base, {
    required bool hasToolbar,
  }) {
    final resolved = base.copyWith(hintText: widget.placeholder);
    if (!hasToolbar) return resolved;

    final enabledBorder = _asOutline(base.enabledBorder ?? base.border);
    final focusedBorder =
        _asOutline(base.focusedBorder ?? base.enabledBorder ?? base.border);
    final errorBorder =
        _asOutline(base.errorBorder ?? base.enabledBorder ?? base.border);
    final focusedErrorBorder = _asOutline(
      base.focusedErrorBorder ?? base.errorBorder ?? base.enabledBorder,
    );

    if (enabledBorder == null) return resolved;

    final radius = enabledBorder.borderRadius.resolve(Directionality.of(context));
    final bottomRadius = BorderRadius.only(
      bottomLeft: radius.bottomLeft,
      bottomRight: radius.bottomRight,
    );

    return resolved.copyWith(
      border: _flattenBorder(enabledBorder, bottomRadius),
      enabledBorder: _flattenBorder(enabledBorder, bottomRadius),
      focusedBorder: _flattenBorder(focusedBorder ?? enabledBorder, bottomRadius),
      errorBorder: _flattenBorder(errorBorder ?? enabledBorder, bottomRadius),
      focusedErrorBorder:
          _flattenBorder(focusedErrorBorder ?? errorBorder ?? enabledBorder, bottomRadius),
    );
  }

  OutlineInputBorder? _asOutline(InputBorder? border) {
    return border is OutlineInputBorder ? border : null;
  }

  OutlineInputBorder _flattenBorder(
    OutlineInputBorder border,
    BorderRadius borderRadius,
  ) {
    return OutlineInputBorder(
      borderSide: border.borderSide,
      borderRadius: borderRadius,
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    InputDecoration decoration, {
    required bool isFocused,
  }) {
    final fillColor =
        decoration.fillColor ?? RpgFormStyles.fieldFillColor(context);
    final enabledBorder = _asOutline(decoration.enabledBorder ?? decoration.border);
    final focusedBorder =
        _asOutline(decoration.focusedBorder ?? decoration.enabledBorder);

    var borderSide = enabledBorder?.borderSide ??
        BorderSide(color: Theme.of(context).colorScheme.outline);
    var topRadius = const BorderRadius.vertical(top: Radius.circular(4));

    if (enabledBorder != null) {
      final radius =
          enabledBorder.borderRadius.resolve(Directionality.of(context));
      topRadius = BorderRadius.only(topLeft: radius.topLeft, topRight: radius.topRight);
      if (isFocused && focusedBorder != null) {
        borderSide = focusedBorder.borderSide;
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: topRadius,
        border: Border(
          top: borderSide,
          left: borderSide,
          right: borderSide,
        ),
      ),
      child: Wrap(
        children: [
          _ToolbarButton(
            icon: Icons.title,
            tooltip: 'Heading 1',
            onPressed: () => _insertPrefix('# '),
          ),
          _ToolbarButton(
            icon: Icons.text_fields,
            tooltip: 'Heading 2',
            onPressed: () => _insertPrefix('## '),
          ),
          _ToolbarButton(
            icon: Icons.short_text,
            tooltip: 'Heading 3',
            onPressed: () => _insertPrefix('### '),
          ),
          _ToolbarButton(
            icon: Icons.format_bold,
            tooltip: 'Bold',
            onPressed: () => _wrapSelection('**', '**'),
          ),
          _ToolbarButton(
            icon: Icons.format_italic,
            tooltip: 'Italic',
            onPressed: () => _wrapSelection('_', '_'),
          ),
          _ToolbarButton(
            icon: Icons.format_underlined,
            tooltip: 'Underline',
            onPressed: () => _wrapSelection('++', '++'),
          ),
          _ToolbarButton(
            icon: Icons.format_list_bulleted,
            tooltip: 'Bullet list',
            onPressed: () => _insertPrefix('- '),
          ),
          _ToolbarButton(
            icon: Icons.format_list_numbered,
            tooltip: 'Numbered list',
            onPressed: () => _insertPrefix('1. '),
          ),
          if (widget.autoLinkDamageTypes)
            _ToolbarButton(
              icon: Icons.link,
              tooltip: 'Auto link',
              onPressed: _autoLinkDamageTypes,
            ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
      splashRadius: 18,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}
