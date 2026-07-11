import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/ui/rpg_form_styles.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/models/author.dart';

class AuthorLinksField extends StatelessWidget {
  const AuthorLinksField({super.key});

  void _appendLink(BuildContext context) {
    final bloc = context.read<AnvilFormBloc>();
    final raw = bloc.state.values[AuthorFormKeys.links];
    final entries = <Map<String, dynamic>>[
      if (raw is List)
        for (final entry in raw)
          if (entry is Map) Map<String, dynamic>.from(entry),
    ];
    var nextKey = 0;
    for (final entry in entries) {
      final key = entry['_key'];
      if (key is int && key >= nextKey) nextKey = key + 1;
    }
    entries.add({'source': 'website', 'url': '', '_key': nextKey});
    bloc.add(AnvilFormFieldUpdated(AuthorFormKeys.links, entries));
  }

  @override
  Widget build(BuildContext context) {
    final fieldDecoration = RpgFormStyles.fieldDecoration(context);

    return AnvilFormSection(
      title: 'Links',
      subtitle: 'Source profiles and URLs',
      titleTrailing: FilledButton.tonalIcon(
        onPressed: () => _appendLink(context),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add link'),
      ),
      padding: EdgeInsets.zero,
      showDivider: true,
      spacing: RpgFormStyles.fieldSpacing,
      headerMarginTop: RpgFormStyles.sectionHeaderMarginTop,
      headerMarginBottom: RpgFormStyles.sectionHeaderMarginBottom,
      children: [
        AnvilFormList(
          fieldKey: AuthorFormKeys.links,
          showAddButton: false,
          allowReorder: true,
          wrapListContainer: false,
          itemSpacing: RpgFormStyles.fieldSpacing,
          emptyEntryFactory: () => {'source': 'website', 'url': ''},
          rowBuilder: (context, index, entry, callbacks) {
            return _AuthorLinkRow(
              index: index,
              entry: entry,
              callbacks: callbacks,
              urlDecoration: fieldDecoration.copyWith(
                hintText: 'https://...',
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AuthorLinkRow extends StatefulWidget {
  const _AuthorLinkRow({
    required this.index,
    required this.entry,
    required this.callbacks,
    required this.urlDecoration,
  });

  final int index;
  final Map<String, dynamic> entry;
  final AnvilFormListRowCallbacks callbacks;
  final InputDecoration urlDecoration;

  @override
  State<_AuthorLinkRow> createState() => _AuthorLinkRowState();
}

class _AuthorLinkRowState extends State<_AuthorLinkRow> {
  late final TextEditingController _urlController;
  late final FocusNode _urlFocusNode;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: widget.entry['url'] as String? ?? '',
    );
    _urlFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _AuthorLinkRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final externalUrl = widget.entry['url'] as String? ?? '';
    if (!_urlFocusNode.hasFocus && _urlController.text != externalUrl) {
      _urlController.text = externalUrl;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.entry['source'] as String? ?? 'website';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
          initialValue: AuthorSourceOptions.values.contains(source)
              ? source
              : 'website',
            decoration: widget.urlDecoration.copyWith(labelText: 'Source'),
            items: [
              for (final option in AuthorSourceOptions.values)
                DropdownMenuItem(
                  value: option,
                  child: Text(AuthorSourceOptions.labelFor(option)),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                widget.callbacks.onFieldChanged('source', value);
              }
            },
          ),
        ),
        const SizedBox(width: RpgFormStyles.fieldSpacing),
        Expanded(
          flex: 3,
          child: TextField(
            controller: _urlController,
            focusNode: _urlFocusNode,
            keyboardType: TextInputType.url,
            decoration: widget.urlDecoration.copyWith(labelText: 'URL'),
            onChanged: (value) => widget.callbacks.onFieldChanged('url', value),
          ),
        ),
        if (widget.callbacks.onRemove != null)
          IconButton(
            tooltip: 'Remove link',
            onPressed: widget.callbacks.onRemove,
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }
}
