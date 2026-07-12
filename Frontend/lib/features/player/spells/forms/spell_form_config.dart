import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:rpg_companion/features/player/spells/forms/spell_form_fields.dart';
import 'package:rpg_companion/features/player/spells/models/spell.dart';

AnvilFormConfig buildSpellFormConfig(
  RecordBloc recordBloc, {
  RecordId? recordId,
  Spell? preloadedSpell,
}) {
  final isEdit = recordId != null;
  return AnvilFormConfig(
    formKey: isEdit ? 'edit_spell' : 'create_spell',
    steps: const ['main'],
    pages: {
      'main': AnvilFormPage(
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const SpellFormFields(),
            ),
          ),
        ),
      ),
    },
    initialValues: isEdit
        ? const {}
        : {
      SpellFormKeys.name: '',
      SpellFormKeys.fileId: '',
      SpellFormKeys.level: SpellLevels.values.first,
      SpellFormKeys.school: SpellSchools.values.first,
      SpellFormKeys.castingTime: 1,
      SpellFormKeys.castingType: CastingTypes.action,
      SpellFormKeys.trigger: '',
      SpellFormKeys.duration: SpellDurations.values.first,
      SpellFormKeys.concentration: false,
      SpellFormKeys.range: SpellRanges.values.first,
      SpellFormKeys.componentVerbal: false,
      SpellFormKeys.componentSomatic: false,
      SpellFormKeys.componentMaterial: false,
      SpellFormKeys.materials: '',
      SpellFormKeys.description: '',
      SpellFormKeys.higherLevels: '',
      SpellFormKeys.classIds: <String>[],
      SpellFormKeys.spellTagIds: <String>[],
    },
    validationRules: [
      AnvilFormValidationRule(
        fieldKey: SpellFormKeys.name,
        validate: (values) {
          final name = (values[SpellFormKeys.name] as String? ?? '').trim();
          if (name.isEmpty) return 'Name is required';
          return null;
        },
      ),
      AnvilFormValidationRule(
        fieldKey: SpellFormKeys.classIds,
        validate: (values) {
          final classIds = values[SpellFormKeys.classIds];
          if (classIds is! List || classIds.isEmpty) {
            return 'Select at least one caster class';
          }
          return null;
        },
      ),
      AnvilFormValidationRule(
        fieldKey: SpellFormKeys.trigger,
        validate: (values) {
          if (values[SpellFormKeys.castingType] != CastingTypes.reaction) {
            return null;
          }
          final trigger =
              (values[SpellFormKeys.trigger] as String? ?? '').trim();
          if (trigger.isEmpty) {
            return 'Trigger is required for reaction spells';
          }
          return null;
        },
      ),
      AnvilFormValidationRule(
        fieldKey: SpellFormKeys.materials,
        validate: (values) {
          final hasMaterial =
              values[SpellFormKeys.componentMaterial] as bool? ?? false;
          if (!hasMaterial) return null;
          final materials =
              (values[SpellFormKeys.materials] as String? ?? '').trim();
          if (materials.isEmpty) {
            return 'Materials are required when M is selected';
          }
          return null;
        },
      ),
    ],
    submitHandler: RecordSubmitHandler(
      recordBloc: recordBloc,
      recordType: 'spells',
      recordId: recordId,
      toRecord: (values) => Spell.fromFormValues(
        values,
        id: recordId,
      ),
      fromRecord: (record) => (record as Spell).toFormValues(),
    ),
  );
}
