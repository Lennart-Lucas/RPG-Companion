import 'package:flutter/material.dart';
import 'package:rpg_companion/features/player/spells/models/spell.dart';

class SpellListTile extends StatelessWidget {
  const SpellListTile({
    super.key,
    required this.spell,
    this.onTap,
  });

  final Spell spell;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                spell.concentration
                    ? Icons.auto_fix_high_outlined
                    : Icons.bolt_outlined,
                color: scheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spell.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${SpellLevels.labelFor(spell.level)} · ${SpellSchools.labelFor(spell.school)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (spell.concentration)
                Tooltip(
                  message: 'Concentration',
                  child: Chip(
                    label: const Text('C'),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
