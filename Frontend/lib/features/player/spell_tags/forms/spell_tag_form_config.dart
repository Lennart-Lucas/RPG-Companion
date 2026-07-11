import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:rpg_companion/features/player/spell_tags/forms/spell_tag_form_fields.dart';
import 'package:rpg_companion/features/player/spell_tags/models/spell_tag.dart';

AnvilFormConfig buildSpellTagFormConfig(RecordBloc recordBloc) {
  return AnvilFormConfig(
    formKey: 'create_spell_tag',
    steps: const ['main'],
    pages: {
      'main': AnvilFormPage(
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const SpellTagFormFields(),
            ),
          ),
        ),
      ),
    },
    initialValues: const {
      SpellTagFormKeys.name: '',
      SpellTagFormKeys.description: '',
    },
    validationRules: [
      AnvilFormValidationRule(
        fieldKey: SpellTagFormKeys.name,
        validate: (values) {
          final name =
              (values[SpellTagFormKeys.name] as String? ?? '').trim();
          if (name.isEmpty) return 'Name is required';
          return null;
        },
      ),
    ],
    submitHandler: RecordSubmitHandler(
      recordBloc: recordBloc,
      recordType: 'spell_tags',
      toRecord: (values) => SpellTag.fromFormValues(values),
      fromRecord: (record) => (record as SpellTag).toFormValues(),
    ),
  );
}
