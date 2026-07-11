import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rpg_companion/core/routing/auth_bloc_listenable.dart';
import 'package:rpg_companion/core/routing/rpg_routes.dart';
import 'package:rpg_companion/features/auth/pages/login_page.dart';
import 'package:rpg_companion/features/auth/pages/register_page.dart';
import 'package:rpg_companion/features/dm_tools/resources/pages/resources_page.dart';
import 'package:rpg_companion/shell/app_shell.dart';

Page<void> _noTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

StatefulShellBranch _shellBranch({
  required String path,
  required Widget child,
  List<RouteBase> nestedRoutes = const [],
}) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        pageBuilder: (context, state) => _noTransitionPage(
          state: state,
          child: child,
        ),
        routes: nestedRoutes,
      ),
    ],
  );
}

GoRouter buildRpgRouter({
  required AuthBloc authBloc,
  required Listenable refreshListenable,
}) {
  return GoRouter(
    initialLocation: RpgRoutes.dmToolsResources,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = authBloc.state;
      if (authState is AuthUnknown || authState is AuthLoading) {
        return null;
      }

      final location = state.matchedLocation;
      final isAuthenticated = authState is Authenticated;

      if (!isAuthenticated && !RpgRoutes.isAuthPath(location)) {
        return RpgRoutes.login;
      }
      if (isAuthenticated && RpgRoutes.isAuthPath(location)) {
        return RpgRoutes.dmToolsResources;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RpgRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RpgRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          _shellBranch(
            path: RpgRoutes.dmToolsResources,
            child: const ResourcesPage(),
          ),
        ],
      ),
    ],
  );
}

class RpgRouterHost {
  RpgRouterHost._({
    required this.router,
    required this.authListenable,
  });

  final GoRouter router;
  final AuthBlocListenable authListenable;

  static RpgRouterHost? _instance;

  static RpgRouterHost get instance {
    final host = _instance;
    if (host == null) {
      throw StateError('Call RpgRouterHost.init() before accessing router.');
    }
    return host;
  }

  static void init(AuthBloc authBloc) {
    if (_instance != null) return;
    final authListenable = AuthBlocListenable(authBloc);
    _instance = RpgRouterHost._(
      authListenable: authListenable,
      router: buildRpgRouter(
        authBloc: authBloc,
        refreshListenable: authListenable,
      ),
    );
  }
}

abstract final class RpgNavigation {
  static Future<void> openRegister(BuildContext context) {
    return context.push(RpgRoutes.register);
  }

  static void goShellMenuKey(BuildContext context, String menuKey) {
    final branch = RpgRoutes.shellBranchForMenuKey(menuKey);
    final shell = StatefulNavigationShell.maybeOf(context);
    shell?.goBranch(branch);
    context.go(RpgRoutes.shellPathForMenuKey(menuKey));
  }
}
