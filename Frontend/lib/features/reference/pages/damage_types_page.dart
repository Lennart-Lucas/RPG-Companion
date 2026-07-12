import 'package:flutter/material.dart';
import 'package:rpg_companion/features/reference/widgets/reference_placeholder_page.dart';

class DamageTypesPage extends StatelessWidget {
  const DamageTypesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReferencePlaceholderPage(
      title: 'Damage types',
      iconName: 'Fire Flame',
      message: 'Damage type definitions will be listed here.',
    );
  }
}
