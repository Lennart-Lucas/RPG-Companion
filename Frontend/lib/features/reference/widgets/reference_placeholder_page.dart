import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';

/// Placeholder list page for reference data types not yet backed by an API.
class ReferencePlaceholderPage extends StatelessWidget {
  const ReferencePlaceholderPage({
    super.key,
    required this.title,
    required this.iconName,
    required this.message,
  });

  final String title;
  final String iconName;
  final String message;

  @override
  Widget build(BuildContext context) {
    final icon =
        IconRegistry.instance.getIconData(iconName) ?? Icons.list_outlined;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
