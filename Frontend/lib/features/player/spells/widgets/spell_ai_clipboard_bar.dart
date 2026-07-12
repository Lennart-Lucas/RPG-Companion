import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/features/player/spells/services/spell_ai_import.dart';

/// Copy/paste bar for the spell AI import workflow.
class SpellAiClipboardBar extends StatelessWidget {
  const SpellAiClipboardBar({super.key});

  Future<void> _copyJson(BuildContext context) async {
    final formBloc = context.read<AnvilFormBloc>();
    final recordState = context.read<RecordBloc>().state;
    final prompt = SpellAiImport.toAiPromptString(
      formBloc.state.values,
      recordState: recordState,
    );

    await Clipboard.setData(ClipboardData(text: prompt));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Spell prompt copied to clipboard')),
    );
  }

  Future<void> _pasteJson(BuildContext context) async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = clipboard?.text;
    if (raw == null || raw.trim().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard is empty')),
      );
      return;
    }

    try {
      final parsed = SpellAiImport.parseClipboardJson(raw);
      final recordState = context.read<RecordBloc>().state;
      final result = SpellAiImport.toFormValues(parsed, recordState);

      if (result.values.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No spell fields found in clipboard')),
        );
        return;
      }

      context.read<AnvilFormBloc>().add(
            AnvilFormValuesImported(result.values),
          );

      if (!context.mounted) return;
      final message = result.warnings.isEmpty
          ? 'Spell fields imported from clipboard'
          : 'Imported with ${result.warnings.length} warning(s)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: result.warnings.isEmpty
              ? null
              : SnackBarAction(
                  label: 'Details',
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Import warnings'),
                        content: SingleChildScrollView(
                          child: Text(result.warnings.join('\n')),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      );
    } on FormatException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid JSON: ${error.message}')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import JSON: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AnvilFormBloc, bool>(
      (bloc) => bloc.state.isHydrating || bloc.state.isSubmitting,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: isLoading ? null : () => _copyJson(context),
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy JSON'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: isLoading ? null : () => _pasteJson(context),
          icon: const Icon(Icons.content_paste, size: 18),
          label: const Text('Paste JSON'),
        ),
      ],
    );
  }
}
