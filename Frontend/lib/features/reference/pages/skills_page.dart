import 'package:flutter/material.dart';
import 'package:rpg_companion/features/reference/widgets/reference_placeholder_page.dart';

class SkillsPage extends StatelessWidget {
  const SkillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReferencePlaceholderPage(
      title: 'Skills',
      iconName: 'Brain',
      message: 'Skill definitions will be listed here.',
    );
  }
}
