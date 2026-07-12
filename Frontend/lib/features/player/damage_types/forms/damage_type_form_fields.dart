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
    final iconExtent = AnvilIconColorPickerField.singleLineInputExtent(
      context,
      fieldDecoration,
    );

    return TransparentFormPanel(
      child: AnvilFormSection(
        title: 'Details',
        subtitle: 'Name, icon, color, and markdown description',
        padding: EdgeInsets.zero,
        spacing: RpgFormStyles.fieldSpacing,
        headerMarginTop: 16,
        headerMarginBottom: RpgFormStyles.sectionHeaderMarginBottom,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AnvilTextField(
                  fieldKey: DamageTypeFormKeys.name,
                  label: 'Name',
                  isRequired: true,
                  placeholder: 'Damage type name',
                  decoration: fieldDecoration,
                ),
              ),
              const SizedBox(width: 12),
              AnvilIconColorPickerField(
                iconFieldKey: DamageTypeFormKeys.icon,
                colorFieldKey: DamageTypeFormKeys.color,
                compactSquare: true,
                decoration: fieldDecoration,
                buttonSize: iconExtent - 16,
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
