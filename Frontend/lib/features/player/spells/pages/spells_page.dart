import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/markdown/fields/markdown_wiki_field.dart';
import 'package:rpg_companion/core/markdown/markdown_wiki_display.dart';
import 'package:rpg_companion/features/player/spells/widgets/spells_expandable_fab.dart';

abstract final class _SpellNotesSandboxKeys {
  static const notes = 'spell_notes';
}

class SpellsPage extends StatefulWidget {
  const SpellsPage({super.key});

  @override
  State<SpellsPage> createState() => _SpellsPageState();
}

class _SpellsPageState extends State<SpellsPage> {
  String _displaySource = '';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AnvilFormBloc(
        config: AnvilFormConfig(
          formKey: 'spell_notes_sandbox',
          steps: const ['main'],
          pages: {
            'main': AnvilFormPage(
              builder: (context, state) => const SizedBox.shrink(),
            ),
          },
          initialValues: const {
            _SpellNotesSandboxKeys.notes: '',
          },
          submitHandler: CallbackSubmitHandler(
            onSubmit: (_) async => const FormSubmitResult.success(),
          ),
        ),
      )..add(const AnvilFormInitialized()),
      child: Scaffold(
        floatingActionButton: const SpellsExpandableFab(),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text(
              'Spells',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Markdown + wiki-link sandbox. Type [[ to link authors, files, or classes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const RpgMarkdownWikiField(
              fieldKey: _SpellNotesSandboxKeys.notes,
              label: 'Spell notes (demo)',
              minLines: 8,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                final values =
                    context.read<AnvilFormBloc>().state.values;
                setState(() {
                  _displaySource =
                      values[_SpellNotesSandboxKeys.notes] as String? ?? '';
                });
              },
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Update display preview'),
            ),
            if (_displaySource.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Display component',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              MarkdownWikiDisplay(source: _displaySource),
            ],
          ],
        ),
      ),
    );
  }
}
