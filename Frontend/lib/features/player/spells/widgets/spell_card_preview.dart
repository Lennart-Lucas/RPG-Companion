import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/features/player/services/player_record_resolver.dart';
import 'package:rpg_companion/features/player/spells/models/spell.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_builder.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_data.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_pages_wrap.dart';

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
    final tagNames = _resolveTagNames(recordState, spell.spellTagIds);
    final data = SpellCardData(
      spell: spell,
      classNames: classNames,
      tagNames: tagNames,
    );

    final bodyMarkdown = SpellCardData.combineBodyMarkdown(
      description: spell.description,
      higherLevels: spell.higherLevels,
    );

    final cards = buildSpellCards(
      data: data,
      bodyMarkdown: bodyMarkdown,
    );

    return SpellCardPagesWrap(cards: cards);
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

  List<String> _resolveTagNames(RecordState state, List<String> tagIds) {
    if (tagIds.isEmpty) return const [];

    final tags = resolveSpellTags(state, spellTagsListQuery);
    final names = <String>[];
    for (final id in tagIds) {
      final match = tags.where((tag) => tag.id == id);
      if (match.isNotEmpty) {
        names.add(match.first.name);
      }
    }
    return names;
  }
}
