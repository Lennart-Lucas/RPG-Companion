import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/features/player/services/player_record_resolver.dart';
import 'package:rpg_companion/features/player/spells/models/spell.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_data.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_layout.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_paginator.dart';

class SpellCardPreview extends StatelessWidget {
  const SpellCardPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final formValues = context.select<AnvilFormBloc, Map<String, dynamic>>(
      (bloc) => Map<String, dynamic>.from(bloc.state.values),
    );
    final recordState = context.select<RecordBloc, RecordState>(
      (bloc) => bloc.state,
    );

    final spell = Spell.fromFormValues(formValues);
    final classNames = _resolveClassNames(recordState, spell.classIds);
    final data = SpellCardData(spell: spell, classNames: classNames);

    final bodyMarkdown = SpellCardData.combineBodyMarkdown(
      description: spell.description,
      higherLevels: spell.higherLevels,
    );

    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodySmall?.copyWith(height: 1.4) ??
        const TextStyle(fontSize: 12, height: 1.4);
    final headingSmallStyle =
        theme.textTheme.headlineSmall?.copyWith(height: 1.2) ??
            const TextStyle(fontSize: 20, height: 1.2);
    final titleLargeStyle = theme.textTheme.titleLarge?.copyWith(height: 1.2) ??
        const TextStyle(fontSize: 18, height: 1.2);
    final titleMediumStyle =
        theme.textTheme.titleMedium?.copyWith(height: 1.2) ??
            const TextStyle(fontSize: 14, height: 1.2);

    final pages = paginateSpellBody(
      bodyMarkdown,
      maxWidth: SpellCardLayout.bodyContentWidth,
      bodyStyle: bodyStyle,
      headingSmallStyle: headingSmallStyle,
      titleMediumStyle: titleMediumStyle,
      titleLargeStyle: titleLargeStyle,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < pages.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          SpellCard(
            data: data,
            bodyMarkdown: pages[i].markdownChunk,
            showInfoBlock: pages[i].showInfoBlock,
          ),
        ],
      ],
    );
  }

  List<String> _resolveClassNames(RecordState state, List<String> classIds) {
    if (classIds.isEmpty) return const [];

    final classes = resolveClasses(state, classesListQuery)
        .where((characterClass) => characterClass.caster)
        .toList();

    final names = <String>[];
    for (final id in classIds) {
      final match = classes.where((characterClass) => characterClass.id == id);
      if (match.isNotEmpty) {
        names.add(match.first.name);
      }
    }
    return names;
  }
}
