import 'package:flutter/material.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';

class SpellsExpandableFab extends StatelessWidget {
  const SpellsExpandableFab({super.key, this.onChanged});

  final VoidCallback? onChanged;

  Future<void> _addSpell(BuildContext context) async {
    await RpgNavigation.openSpellCreate(context);
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'add_spell',
      onPressed: () => _addSpell(context),
      child: const Icon(Icons.add),
    );
  }
}
