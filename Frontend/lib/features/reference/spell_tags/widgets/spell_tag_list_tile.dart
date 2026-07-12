import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:rpg_companion/features/player/spell_tags/models/spell_tag.dart';

class SpellTagListTile extends StatelessWidget {
  const SpellTagListTile({
    super.key,
    required this.spellTag,
    this.onTap,
  });

  final SpellTag spellTag;
  final VoidCallback? onTap;

  String? _subtitle() {
    final description = spellTag.description?.trim();
    if (description == null || description.isEmpty) return null;
    final oneLine = description.replaceAll(RegExp(r'\s+'), ' ');
    if (oneLine.length <= 80) return oneLine;
    return '${oneLine.substring(0, 77)}…';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = _subtitle();

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
                IconRegistry.instance.getIconData('Tag') ?? Icons.sell_outlined,
                color: scheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spellTag.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
