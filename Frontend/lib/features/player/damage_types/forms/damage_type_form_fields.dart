import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:rpg_companion/core/markdown/fields/markdown_wiki_field.dart';
import 'package:rpg_companion/core/ui/rpg_form_styles.dart';
import 'package:rpg_companion/features/dm_tools/resources/widgets/transparent_form_panel.dart';
import 'package:rpg_companion/features/player/damage_types/models/damage_type.dart';

class DamageTypeFormFields extends StatelessWidget {
  const DamageTypeFormFields({super.key});

  @override
  Widget build(BuildContext context) {
    final fieldDecoration = RpgFormStyles.fieldDecoration(context);

    return TransparentFormPanel(
      child: AnvilFormSection(
        title: 'Details',
        subtitle: 'Icon, name, color, and markdown description',
        padding: EdgeInsets.zero,
        spacing: RpgFormStyles.fieldSpacing,
        headerMarginTop: 16,
        headerMarginBottom: RpgFormStyles.sectionHeaderMarginBottom,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnvilIconColorPickerField(
                iconFieldKey: DamageTypeFormKeys.icon,
                colorFieldKey: DamageTypeFormKeys.color,
                compactSquare: true,
                compactSquareSize: 44,
                compactSquareTopInset: 0,
                decoration: fieldDecoration,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnvilTextField(
                  fieldKey: DamageTypeFormKeys.name,
                  label: 'Name',
                  isRequired: true,
                  placeholder: 'Damage type name',
                  decoration: fieldDecoration,
                ),
              ),
            ],
          ),
          RpgMarkdownWikiField(
            fieldKey: DamageTypeFormKeys.description,
            label: 'Description',
            minLines: 8,
            placeholder: 'Describe this damage type. Type [[ to link records.',
            decoration: fieldDecoration,
          ),
        ],
      ),
    );
  }
}
