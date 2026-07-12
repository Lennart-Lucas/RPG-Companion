import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/features/player/classes/forms/class_form_config.dart';
import 'package:rpg_companion/features/player/classes/models/character_class.dart';

class ClassEditPage extends StatelessWidget {
  const ClassEditPage({
    super.key,
    required this.classId,
    this.characterClass,
  });

  final RecordId classId;
  final CharacterClass? characterClass;

  @override
  Widget build(BuildContext context) {
    final recordBloc = context.read<RecordBloc>();
    final iconData = IconRegistry.instance.getIconData('Graduation Cap') ??
        Icons.school_outlined;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit class'),
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(
              alpha: 0.85,
            ),
      ),
      body: AnvilBackgroundIcon(
        icon: iconData,
        opacity: 0.32,
        baseSize: 260,
        child: AnvilForm(
          config: buildClassFormConfig(
            recordBloc,
            recordId: classId,
            preloadedClass: characterClass,
          ),
          submitLabel: 'Save class',
          onCancel: () => context.pop(),
          onSubmitSuccess: (_) async {
            recordBloc.remoteCoordinator?.refreshQueryRecords(classesListQuery);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Class saved')),
            );
            context.pop();
          },
        ),
      ),
    );
  }
}
