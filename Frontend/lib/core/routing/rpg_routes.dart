/// Path constants and helpers for RPG Companion [GoRouter] routes.
abstract final class RpgRoutes {
  static const login = '/login';
  static const register = '/register';

  static const dmToolsResources = '/dm-tools/resources';
  static const playerClasses = '/player/classes';
  static const playerSpells = '/player/spells';

  static const referenceConditions = '/reference/conditions';
  static const referenceDamageTypes = '/reference/damage-types';
  static const referenceItemProperties = '/reference/item-properties';
  static const referenceSkills = '/reference/skills';
  static const referenceSpellTags = '/reference/spell-tags';
  static const referenceSpellLists = '/reference/spell-lists';

  static const classCreate = '$playerClasses/new';

  static String classDetail(String classId) => '$playerClasses/$classId';

  static const spellTagCreate = '$referenceSpellTags/new';

  static const spellCreate = '$playerSpells/new';

  static String spellDetail(String spellId) => '$playerSpells/$spellId';

  static const authorCreate = '$dmToolsResources/authors/new';
  static const fileCreate = '$dmToolsResources/files/new';

  static String authorDetail(String authorId) =>
      '$dmToolsResources/authors/$authorId';

  static String authorEdit(String authorId) =>
      '$dmToolsResources/authors/$authorId/edit';

  static String fileDetail(String fileId) => '$dmToolsResources/files/$fileId';

  static String fileEdit(String fileId) => '$dmToolsResources/files/$fileId/edit';

  static const shellBranchClasses = 0;
  static const shellBranchSpells = 1;
  static const shellBranchConditions = 2;
  static const shellBranchDamageTypes = 3;
  static const shellBranchItemProperties = 4;
  static const shellBranchSkills = 5;
  static const shellBranchSpellTags = 6;
  static const shellBranchSpellLists = 7;
  static const shellBranchResources = 8;

  static const shellPaths = [
    playerClasses,
    playerSpells,
    referenceConditions,
    referenceDamageTypes,
    referenceItemProperties,
    referenceSkills,
    referenceSpellTags,
    referenceSpellLists,
    dmToolsResources,
  ];

  static const shellMenuKeys = [
    'classes',
    'spells',
    'conditions',
    'damage-types',
    'item-properties',
    'skills',
    'spell-tags',
    'spell-lists',
    'resources',
  ];

  static int shellBranchForPath(String location) {
    for (var i = 0; i < shellPaths.length; i++) {
      if (location.startsWith(shellPaths[i])) return i;
    }
    return shellBranchResources;
  }

  static String shellPathForBranch(int branchIndex) {
    return shellPaths[branchIndex.clamp(0, shellPaths.length - 1)];
  }

  static String shellPathForMenuKey(String menuKey) {
    final index = shellMenuKeys.indexOf(menuKey);
    if (index < 0) return dmToolsResources;
    return shellPaths[index];
  }

  static int shellBranchForMenuKey(String menuKey) {
    final index = shellMenuKeys.indexOf(menuKey);
    if (index < 0) return shellBranchResources;
    return index;
  }

  static String? menuKeyForLocation(String location) {
    final branch = shellBranchForPath(location);
    if (branch < 0 || branch >= shellMenuKeys.length) return null;
    return shellMenuKeys[branch];
  }

  static bool isAuthPath(String location) =>
      location == login || location == register;
}
