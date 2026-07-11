import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:rpg_companion/features/player/classes/forms/class_form_fields.dart';
import 'package:rpg_companion/features/player/classes/models/character_class.dart';

AnvilFormConfig buildClassFormConfig(RecordBloc recordBloc) {
  return AnvilFormConfig(
    formKey: 'create_class',
    steps: const ['main'],
    pages: {
      'main': AnvilFormPage(
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const ClassFormFields(),
            ),
          ),
        ),
      ),
    },
    initialValues: const {
      CharacterClassFormKeys.name: '',
      CharacterClassFormKeys.fileId: '',
      CharacterClassFormKeys.caster: false,
    },
    validationRules: [
      AnvilFormValidationRule(
        fieldKey: CharacterClassFormKeys.name,
        validate: (values) {
          final name =
              (values[CharacterClassFormKeys.name] as String? ?? '').trim();
          if (name.isEmpty) return 'Name is required';
          return null;
        },
      ),
    ],
    submitHandler: RecordSubmitHandler(
      recordBloc: recordBloc,
      recordType: 'classes',
      toRecord: (values) => CharacterClass.fromFormValues(values),
      fromRecord: (record) => (record as CharacterClass).toFormValues(),
    ),
  );
}
