import 'package:flutter/material.dart';
import 'package:rpg_companion/features/reference/widgets/reference_placeholder_page.dart';

class ItemPropertiesPage extends StatelessWidget {
  const ItemPropertiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReferencePlaceholderPage(
      title: 'Item properties',
      iconName: 'Sliders',
      message: 'Item property definitions will be listed here.',
    );
  }
}
