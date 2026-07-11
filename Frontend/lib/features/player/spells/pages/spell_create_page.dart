import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/features/player/spells/forms/spell_form_config.dart';

class SpellCreatePage extends StatelessWidget {
  const SpellCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final recordBloc = context.read<RecordBloc>();
    final iconData = IconRegistry.instance.getIconData('Wand Magic Sparkles') ??
        Icons.auto_fix_high_outlined;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New spell'),
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(
              alpha: 0.85,
            ),
      ),
      body: AnvilBackgroundIcon(
        icon: iconData,
        opacity: 0.32,
        baseSize: 260,
        child: AnvilForm(
          config: buildSpellFormConfig(recordBloc),
          submitLabel: 'Create spell',
          onCancel: () => context.pop(),
          onSubmitSuccess: (_) async {
            recordBloc.remoteCoordinator?.refreshQueryRecords(spellsListQuery);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Spell created')),
            );
            context.pop();
          },
        ),
      ),
    );
  }
}
