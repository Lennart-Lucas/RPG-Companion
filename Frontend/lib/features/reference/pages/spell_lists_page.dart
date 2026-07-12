import 'package:flutter/material.dart';
import 'package:rpg_companion/features/reference/widgets/reference_placeholder_page.dart';

class SpellListsPage extends StatelessWidget {
  const SpellListsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReferencePlaceholderPage(
      title: 'Spell lists',
      iconName: 'List Ol',
      message: 'Spell lists will be listed here.',
    );
  }
}
