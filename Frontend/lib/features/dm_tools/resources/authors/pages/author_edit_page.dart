import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rpg_companion/core/records/record_list_refresh.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/forms/author_form_config.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/models/author.dart';

class AuthorEditPage extends StatelessWidget {
  const AuthorEditPage({
    super.key,
    required this.authorId,
    this.author,
  });

  final RecordId authorId;
  final Author? author;

  Future<void> _refreshAuthors(BuildContext context) {
    return refreshRecordQuery(context.read<RecordBloc>(), authorsListQuery);
  }

  @override
  Widget build(BuildContext context) {
    final recordBloc = context.read<RecordBloc>();
    final iconData =
        IconRegistry.instance.getIconData('Book') ?? Icons.menu_book_outlined;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit author'),
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(
              alpha: 0.85,
            ),
      ),
      body: AnvilBackgroundIcon(
        icon: iconData,
        opacity: 0.32,
        baseSize: 260,
        child: AnvilForm(
          config: buildAuthorFormConfig(
            recordBloc,
            recordId: authorId,
            preloadedAuthor: author,
          ),
          submitLabel: 'Save author',
          onCancel: () => context.pop(),
          onSubmitSuccess: (_) async {
            await _refreshAuthors(context);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Author saved')),
            );
            context.pop();
          },
        ),
      ),
    );
  }
}
