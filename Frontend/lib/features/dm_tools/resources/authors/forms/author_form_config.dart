import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/forms/author_form_fields.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/forms/author_record_submit_handler.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/models/author.dart';

AnvilFormConfig buildAuthorFormConfig(
  RecordBloc recordBloc, {
  RecordId? recordId,
  Author? preloadedAuthor,
}) {
  final isEdit = recordId != null;
  return AnvilFormConfig(
    formKey: isEdit ? 'edit_author' : 'create_author',
    steps: const ['main'],
    pages: {
      'main': AnvilFormPage(
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const AuthorFormFields(),
            ),
          ),
        ),
      ),
    },
    initialValues: isEdit
        ? const {}
        : {
            AuthorFormKeys.links: <Map<String, dynamic>>[],
          },
    validationRules: [
      AnvilFormValidationRule(
        fieldKey: AuthorFormKeys.name,
        validate: (values) {
          final name = (values[AuthorFormKeys.name] as String? ?? '').trim();
          if (name.isEmpty) return 'Name is required';
          return null;
        },
      ),
    ],
    submitHandler: isEdit
        ? AuthorRecordSubmitHandler(
            recordBloc: recordBloc,
            recordId: recordId,
            preloadedAuthor: preloadedAuthor,
          )
        : RecordSubmitHandler(
            recordBloc: recordBloc,
            recordType: 'authors',
            toRecord: (values) => Author.fromFormValues(values),
            fromRecord: (record) => (record as Author).toFormValues(),
          ),
  );
}
