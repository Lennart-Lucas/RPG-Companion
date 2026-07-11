import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';
import 'package:rpg_companion/core/routing/rpg_routes.dart';

const _placeholderContent = SizedBox.shrink();

/// Root shell: overlay sidebar toggled from the app bar hamburger.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedMenuKey =
        RpgRoutes.menuKeyForLocation(location) ?? 'resources';

    return CollapsibleDrawer(
      hideRailWhenClosed: true,
      showAppBar: true,
      shellChild: navigationShell,
      selectedMenuKey: selectedMenuKey,
      onMenuLinkSelected: (menuKey) {
        RpgNavigation.goShellMenuKey(context, menuKey);
      },
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
  }
}
