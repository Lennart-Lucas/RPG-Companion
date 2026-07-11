/// Path constants and helpers for RPG Companion [GoRouter] routes.
abstract final class RpgRoutes {
  static const login = '/login';
  static const register = '/register';

  static const dmToolsResources = '/dm-tools/resources';

  static const shellBranchResources = 0;

  static const shellPaths = [
    dmToolsResources,
  ];

  static const shellMenuKeys = [
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
