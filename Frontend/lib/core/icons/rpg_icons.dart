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
    IconEntry(
      name: 'User',
      data: FontAwesomeIcons.user,
      category: 'RPG',
      sequence: 2,
      tags: ['player', 'character', 'user', 'person'],
    ),
    IconEntry(
      name: 'Wand Magic Sparkles',
      data: FontAwesomeIcons.wandMagicSparkles,
      category: 'RPG',
      sequence: 3,
      tags: ['spells', 'magic', 'wizard', 'sorcery'],
    ),
    IconEntry(
      name: 'Graduation Cap',
      data: FontAwesomeIcons.graduationCap,
      category: 'RPG',
      sequence: 4,
      tags: ['classes', 'character', 'player', 'school'],
    ),
    IconEntry(
      name: 'Puzzle Piece',
      data: FontAwesomeIcons.puzzlePiece,
      category: 'RPG',
      sequence: 5,
      tags: ['mechanics', 'rules', 'reference', 'extension'],
    ),
    IconEntry(
      name: 'Heart Pulse',
      data: FontAwesomeIcons.heartPulse,
      category: 'RPG',
      sequence: 6,
      tags: ['conditions', 'status', 'health', 'healing'],
    ),
    IconEntry(
      name: 'Fire Flame',
      data: FontAwesomeIcons.fireFlameCurved,
      category: 'RPG',
      sequence: 7,
      tags: ['damage', 'fire', 'energy', 'types'],
    ),
    IconEntry(
      name: 'Sliders',
      data: FontAwesomeIcons.sliders,
      category: 'RPG',
      sequence: 8,
      tags: ['item', 'properties', 'traits', 'tune'],
    ),
    IconEntry(
      name: 'Brain',
      data: FontAwesomeIcons.brain,
      category: 'RPG',
      sequence: 9,
      tags: ['skills', 'ability', 'mind', 'psychology'],
    ),
    IconEntry(
      name: 'Tag',
      data: FontAwesomeIcons.tag,
      category: 'RPG',
      sequence: 10,
      tags: ['spell', 'tags', 'label', 'category'],
    ),
    IconEntry(
      name: 'List Ol',
      data: FontAwesomeIcons.listOl,
      category: 'RPG',
      sequence: 11,
      tags: ['spell', 'lists', 'playlist', 'collection'],
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
  registry.setAlias('player', 'User');
  registry.setAlias('classes', 'Graduation Cap');
  registry.setAlias('spells', 'Wand Magic Sparkles');
  registry.setAlias('mechanics', 'Puzzle Piece');
  registry.setAlias('conditions', 'Heart Pulse');
  registry.setAlias('damage-types', 'Fire Flame');
  registry.setAlias('item-properties', 'Sliders');
  registry.setAlias('skills', 'Brain');
  registry.setAlias('spell-tags', 'Tag');
  registry.setAlias('spell-lists', 'List Ol');
}
