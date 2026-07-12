import 'package:flutter/material.dart';
import 'package:rpg_companion/features/player/spells/widgets/mtg/card_text_pagination.dart';
import 'package:rpg_companion/features/player/spells/widgets/mtg/mtg_card_rules_scale.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_data.dart';

List<SpellCard> buildSpellCards({
  required SpellCardData data,
  required String bodyMarkdown,
  MtgCardRulesScaleController? sharedScale,
  double cardScale = 1.0,
  EdgeInsetsGeometry padding = EdgeInsets.zero,
}) {
  final pages = paginateCardBodyText(bodyMarkdown);
  final controller = pages.length > 1
      ? (sharedScale ?? MtgCardRulesScaleController())
      : sharedScale;

  return List<SpellCard>.generate(pages.length, (i) {
    return SpellCard(
      data: data,
      bodyMarkdown: pages[i],
      showMechanics: i == 0,
      continuationIndex: pages.length > 1 ? i + 1 : null,
      continuationTotal: pages.length > 1 ? pages.length : null,
      rulesScaleController: controller,
      cardScale: cardScale,
      padding: padding,
    );
  });
}
