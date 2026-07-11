import 'package:flutter/material.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/models/author.dart';

class AuthorListTile extends StatelessWidget {
  const AuthorListTile({
    super.key,
    required this.author,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final Author author;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                color: selected
                    ? scheme.onPrimaryContainer
                    : scheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: selected
                                ? scheme.onPrimaryContainer
                                : null,
                          ),
                    ),
                    if (author.links.isNotEmpty)
                      Text(
                        '${author.links.length} link${author.links.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: selected
                                  ? scheme.onPrimaryContainer
                                      .withValues(alpha: 0.8)
                                  : scheme.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.expand_less : Icons.chevron_right,
                color: selected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
