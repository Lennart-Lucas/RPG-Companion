import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:rpg_companion/core/ui/rpg_form_styles.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/forms/author_links_field.dart';
import 'package:rpg_companion/features/dm_tools/resources/widgets/transparent_form_panel.dart';

class AuthorFormFields extends StatelessWidget {
  const AuthorFormFields({super.key});

  @override
  Widget build(BuildContext context) {
    final fieldDecoration = RpgFormStyles.fieldDecoration(context);

    return TransparentFormPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnvilFormSection(
            title: 'Details',
            subtitle: 'Author name',
            padding: EdgeInsets.zero,
            spacing: RpgFormStyles.fieldSpacing,
            headerMarginTop: 16,
            headerMarginBottom: RpgFormStyles.sectionHeaderMarginBottom,
            children: [
              AnvilTextField(
                fieldKey: 'name',
                label: 'Name',
                isRequired: true,
                placeholder: 'Author or creator name',
                decoration: fieldDecoration,
              ),
            ],
          ),
          const AuthorLinksField(),
        ],
      ),
    );
  }
}
