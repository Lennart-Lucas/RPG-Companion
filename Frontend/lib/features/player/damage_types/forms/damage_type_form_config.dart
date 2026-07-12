import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:rpg_companion/features/player/damage_types/forms/damage_type_form_fields.dart';
import 'package:rpg_companion/features/player/damage_types/models/damage_type.dart';

AnvilFormConfig buildDamageTypeFormConfig(RecordBloc recordBloc) {
  return AnvilFormConfig(
    formKey: 'create_damage_type',
    steps: const ['main'],
    pages: {
      'main': AnvilFormPage(
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const DamageTypeFormFields(),
            ),
          ),
        ),
      ),
    },
    initialValues: const {
      DamageTypeFormKeys.name: '',
      DamageTypeFormKeys.description: '',
      DamageTypeFormKeys.icon: 'Fire Flame',
      DamageTypeFormKeys.color: null,
    },
    validationRules: [
      AnvilFormValidationRule(
        fieldKey: DamageTypeFormKeys.name,
        validate: (values) {
          final name =
              (values[DamageTypeFormKeys.name] as String? ?? '').trim();
          if (name.isEmpty) return 'Name is required';
          return null;
        },
      ),
    ],
    submitHandler: RecordSubmitHandler(
      recordBloc: recordBloc,
      recordType: 'damage_types',
      toRecord: (values) => DamageType.fromFormValues(values),
      fromRecord: (record) => (record as DamageType).toFormValues(),
    ),
  );
}
