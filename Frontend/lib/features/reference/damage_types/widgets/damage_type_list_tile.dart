import 'package:flutter/material.dart';
import 'package:rpg_companion/features/player/damage_types/models/damage_type.dart';

class DamageTypeListTile extends StatelessWidget {
  const DamageTypeListTile({
    super.key,
    required this.damageType,
    this.onTap,
  });

  final DamageType damageType;
  final VoidCallback? onTap;

  String? _subtitle() {
    final description = damageType.description?.trim();
    if (description == null || description.isEmpty) return null;
    final oneLine = description.replaceAll(RegExp(r'\s+'), ' ');
    if (oneLine.length <= 80) return oneLine;
    return '${oneLine.substring(0, 77)}…';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = _subtitle();
    final iconColor = damageType.displayColor ?? scheme.primary;

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
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  damageType.displayIconData(),
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      damageType.name,
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
