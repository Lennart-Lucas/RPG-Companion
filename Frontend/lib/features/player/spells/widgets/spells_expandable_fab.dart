import 'package:flutter/material.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';

class SpellsExpandableFab extends StatefulWidget {
  const SpellsExpandableFab({super.key, this.onChanged});

  final VoidCallback? onChanged;

  @override
  State<SpellsExpandableFab> createState() => _SpellsExpandableFabState();
}

class _SpellsExpandableFabState extends State<SpellsExpandableFab> {
  bool _open = false;

  void _toggle() => setState(() => _open = !_open);

  Future<void> _addSpell() async {
    _toggle();
    await RpgNavigation.openSpellCreate(context);
    widget.onChanged?.call();
  }

  Future<void> _addSpellTag() async {
    _toggle();
    await RpgNavigation.openSpellTagCreate(context);
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open) ...[
          FloatingActionButton.extended(
            heroTag: 'add_spell',
            onPressed: _addSpell,
            icon: const Icon(Icons.auto_fix_high_outlined),
            label: const Text('Spell'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add_spell_tag',
            onPressed: _addSpellTag,
            icon: const Icon(Icons.sell_outlined),
            label: const Text('Spell Tag'),
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          heroTag: 'spells_main_fab',
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(_open ? Icons.close : Icons.add),
          ),
        ),
      ],
    );
  }
}
