import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:rpg_companion/core/markdown/fields/markdown_wiki_field.dart';
import 'package:rpg_companion/core/ui/rpg_form_styles.dart';
import 'package:rpg_companion/features/dm_tools/resources/widgets/transparent_form_panel.dart';
import 'package:rpg_companion/features/player/spell_tags/models/spell_tag.dart';

class SpellTagFormFields extends StatelessWidget {
  const SpellTagFormFields({super.key});

  @override
  Widget build(BuildContext context) {
    final fieldDecoration = RpgFormStyles.fieldDecoration(context);

    return TransparentFormPanel(
      child: AnvilFormSection(
        title: 'Details',
        subtitle: 'Tag name and markdown description',
        padding: EdgeInsets.zero,
        spacing: RpgFormStyles.fieldSpacing,
        headerMarginTop: 16,
        headerMarginBottom: RpgFormStyles.sectionHeaderMarginBottom,
        children: [
          AnvilTextField(
            fieldKey: SpellTagFormKeys.name,
            label: 'Name',
            isRequired: true,
            placeholder: 'Spell tag name',
            decoration: fieldDecoration,
          ),
          const RpgMarkdownWikiField(
            fieldKey: SpellTagFormKeys.description,
            label: 'Description',
            minLines: 8,
            placeholder: 'Describe this tag. Type [[ to link records.',
          ),
        ],
      ),
    );
  }
}
