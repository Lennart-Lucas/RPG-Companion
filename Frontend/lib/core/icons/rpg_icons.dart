import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Icons for RPG Companion sidebar and features.
const IconSet rpgSidebarIcons = IconSet(
  categories: [
    IconCategory(name: 'RPG', sequence: 3),
  ],
  entries: [
    IconEntry(
      name: 'Book',
      data: FontAwesomeIcons.book,
      category: 'RPG',
      sequence: 0,
      tags: ['book', 'resources', 'reference', 'lore', 'notes'],
    ),
    IconEntry(
      name: 'Dice D20',
      data: FontAwesomeIcons.diceD20,
      category: 'RPG',
      sequence: 1,
      tags: ['dice', 'd20', 'rpg', 'game', 'tabletop'],
    ),
  ],
);

/// Registers default Anvil Foundry icon sets and RPG sidebar icons.
void setupRpgIcons() {
  final registry = IconRegistry.instance;
  registry.registerAll(
    defaultGeneralIcons +
        defaultGoalIcons +
        defaultInputIcons +
        rpgSidebarIcons,
  );

  registry.setAlias('dm-tools', 'Dice D20');
  registry.setAlias('resources', 'Book');
}
