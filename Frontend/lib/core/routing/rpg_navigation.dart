import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rpg_companion/core/routing/auth_bloc_listenable.dart';
import 'package:rpg_companion/core/routing/rpg_routes.dart';
import 'package:rpg_companion/features/auth/pages/login_page.dart';
import 'package:rpg_companion/features/auth/pages/register_page.dart';
import 'package:rpg_companion/shell/home_shell.dart';

GoRouter buildRpgRouter({
  required AuthBloc authBloc,
  required Listenable refreshListenable,
}) {
  return GoRouter(
    initialLocation: RpgRoutes.home,
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
        return RpgRoutes.home;
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
      GoRoute(
        path: RpgRoutes.home,
        builder: (context, state) => const HomeShell(),
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
}
