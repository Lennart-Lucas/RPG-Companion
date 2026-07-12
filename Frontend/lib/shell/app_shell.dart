import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';
import 'package:rpg_companion/core/routing/rpg_routes.dart';
import 'package:rpg_companion/shell/rpg_shell_app_bar.dart';

const _placeholderContent = SizedBox.shrink();

/// Root shell: overlay sidebar toggled from the app bar hamburger.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String? _lastSyncedLocation;

  void _syncShellChromeForLocation(String location) {
    if (_lastSyncedLocation == location) return;
    _lastSyncedLocation = location;

    if (!RpgRoutes.hidesSectionFooter(location)) {
      RpgShellAppBar.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);

    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        final location = GoRouterState.of(context).matchedLocation;
        _syncShellChromeForLocation(location);

        final selectedMenuKey =
            RpgRoutes.menuKeyForLocation(location) ?? 'resources';

        return CollapsibleDrawer(
          hideRailWhenClosed: true,
          showAppBar: true,
          showSectionFooter: !RpgRoutes.hidesSectionFooter(location),
          shellChild: widget.navigationShell,
          selectedMenuKey: selectedMenuKey,
          onMenuLinkSelected: (menuKey) {
            RpgNavigation.goShellMenuKey(context, menuKey);
          },
          appBarOverrideListenable: RpgShellAppBar.appBarOverrideListenable,
          showSectionFooterListenable:
              RpgShellAppBar.showSectionFooterListenable,
          menuItems: [
            MenuGroup(
              key: 'player',
              label: 'Player',
              iconName: 'User',
              children: [
                MenuLink(
                  key: 'classes',
                  label: 'Classes',
                  iconName: 'Graduation Cap',
                  content: _placeholderContent,
                ),
                MenuLink(
                  key: 'spells',
                  label: 'Spells',
                  iconName: 'Wand Magic Sparkles',
                  content: _placeholderContent,
                ),
              ],
            ),
            MenuGroup(
              key: 'mechanics',
              label: 'Mechanics',
              iconName: 'Puzzle Piece',
              children: [
                MenuLink(
                  key: 'conditions',
                  label: 'Conditions',
                  iconName: 'Heart Pulse',
                  content: _placeholderContent,
                ),
                MenuLink(
                  key: 'damage-types',
                  label: 'Damage types',
                  iconName: 'Fire Flame',
                  content: _placeholderContent,
                ),
                MenuLink(
                  key: 'item-properties',
                  label: 'Item properties',
                  iconName: 'Sliders',
                  content: _placeholderContent,
                ),
                MenuLink(
                  key: 'skills',
                  label: 'Skills',
                  iconName: 'Brain',
                  content: _placeholderContent,
                ),
                MenuLink(
                  key: 'spell-tags',
                  label: 'Spell tags',
                  iconName: 'Tag',
                  content: _placeholderContent,
                ),
                MenuLink(
                  key: 'spell-lists',
                  label: 'Spell lists',
                  iconName: 'List Ol',
                  content: _placeholderContent,
                ),
              ],
            ),
            MenuGroup(
              key: 'dm-tools',
              label: 'DM Tools',
              iconName: 'Dice D20',
              children: [
                MenuLink(
                  key: 'resources',
                  label: 'Resources',
                  iconName: 'Book',
                  content: _placeholderContent,
                ),
              ],
            ),
            MenuAction(
              key: 'logout',
              label: 'Log out',
              iconName: 'Logout',
              action: () {
                context.read<AuthBloc>().add(const LogoutRequested());
              },
            ),
          ],
        );
      },
    );
  }
}
