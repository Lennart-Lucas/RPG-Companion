import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/forms/file_form_fields.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/forms/file_record_submit_handler.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';

AnvilFormConfig buildFileFormConfig(
  RecordBloc recordBloc, {
  RecordId? recordId,
  ResourceFile? preloadedFile,
  Map<String, dynamic> createOverrides = const {},
}) {
  final isEdit = recordId != null;
  return AnvilFormConfig(
    formKey: isEdit ? 'edit_file' : 'create_file',
    steps: const ['main'],
    pages: {
      'main': AnvilFormPage(
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const FileFormFields(),
            ),
          ),
        ),
      ),
    },
    initialValues: isEdit
        ? const {}
        : {
            ResourceFileFormKeys.authorId: '',
            ...createOverrides,
          },
    validationRules: [
      AnvilFormValidationRule(
        fieldKey: ResourceFileFormKeys.name,
        validate: (values) {
          final name =
              (values[ResourceFileFormKeys.name] as String? ?? '').trim();
          if (name.isEmpty) return 'Name is required';
          return null;
        },
      ),
      AnvilFormValidationRule(
        fieldKey: ResourceFileFormKeys.address,
        validate: (values) {
          final address =
              (values[ResourceFileFormKeys.address] as String? ?? '').trim();
          if (address.isEmpty) return 'Address is required';
          return null;
        },
      ),
    ],
    submitHandler: isEdit
        ? FileRecordSubmitHandler(
            recordBloc: recordBloc,
            recordId: recordId,
            preloadedFile: preloadedFile,
          )
        : RecordSubmitHandler(
            recordBloc: recordBloc,
            recordType: 'files',
            toRecord: (values) => ResourceFile.fromFormValues(values),
            fromRecord: (record) => (record as ResourceFile).toFormValues(),
          ),
  );
}
