import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rpg_companion/core/routing/auth_bloc_listenable.dart';
import 'package:rpg_companion/core/routing/rpg_routes.dart';
import 'package:rpg_companion/features/auth/pages/login_page.dart';
import 'package:rpg_companion/features/auth/pages/register_page.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/models/author.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/pages/author_create_page.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/pages/author_detail_page.dart';
import 'package:rpg_companion/features/dm_tools/resources/authors/pages/author_edit_page.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/models/resource_file.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/pages/file_create_page.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/pages/file_detail_page.dart';
import 'package:rpg_companion/features/dm_tools/resources/files/pages/file_edit_page.dart';
import 'package:rpg_companion/features/dm_tools/resources/pages/resources_page.dart';
import 'package:rpg_companion/features/player/classes/models/character_class.dart';
import 'package:rpg_companion/features/player/classes/pages/class_create_page.dart';
import 'package:rpg_companion/features/player/classes/pages/class_detail_page.dart';
import 'package:rpg_companion/features/player/classes/pages/classes_page.dart';
import 'package:rpg_companion/features/player/spells/models/spell.dart';
import 'package:rpg_companion/features/player/spells/pages/spell_create_page.dart';
import 'package:rpg_companion/features/player/spells/pages/spell_detail_page.dart';
import 'package:rpg_companion/features/player/spells/pages/spells_page.dart';
import 'package:rpg_companion/features/player/spell_tags/pages/spell_tag_create_page.dart';
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
            path: RpgRoutes.playerClasses,
            child: const ClassesPage(),
            nestedRoutes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ClassCreatePage(),
              ),
              GoRoute(
                path: ':classId',
                builder: (context, state) => ClassDetailPage(
                  classId: state.pathParameters['classId']!,
                  characterClass: state.extra as CharacterClass?,
                ),
              ),
            ],
          ),
          _shellBranch(
            path: RpgRoutes.playerSpells,
            child: const SpellsPage(),
            nestedRoutes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const SpellCreatePage(),
              ),
              GoRoute(
                path: 'spell-tags/new',
                builder: (context, state) => const SpellTagCreatePage(),
              ),
              GoRoute(
                path: ':spellId',
                builder: (context, state) => SpellDetailPage(
                  spellId: state.pathParameters['spellId']!,
                  spell: state.extra as Spell?,
                ),
              ),
            ],
          ),
          _shellBranch(
            path: RpgRoutes.dmToolsResources,
            child: const ResourcesPage(),
            nestedRoutes: [
              GoRoute(
                path: 'authors/new',
                builder: (context, state) => const AuthorCreatePage(),
              ),
              GoRoute(
                path: 'authors/:authorId',
                builder: (context, state) => AuthorDetailPage(
                  authorId: state.pathParameters['authorId']!,
                  author: state.extra as Author?,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => AuthorEditPage(
                      authorId: state.pathParameters['authorId']!,
                      author: state.extra as Author?,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'files/new',
                builder: (context, state) => FileCreatePage(
                  authorId: state.uri.queryParameters['authorId'],
                ),
              ),
              GoRoute(
                path: 'files/:fileId',
                builder: (context, state) => FileDetailPage(
                  fileId: state.pathParameters['fileId']!,
                  file: state.extra as ResourceFile?,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => FileEditPage(
                      fileId: state.pathParameters['fileId']!,
                      file: state.extra as ResourceFile?,
                    ),
                  ),
                ],
              ),
            ],
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

  static Future<void> openAuthorCreate(BuildContext context) {
    return context.push(RpgRoutes.authorCreate);
  }

  static Future<void> openAuthorDetail(BuildContext context, Author author) {
    return context.push(RpgRoutes.authorDetail(author.id), extra: author);
  }

  static Future<void> openAuthorEdit(BuildContext context, Author author) {
    return context.push(RpgRoutes.authorEdit(author.id), extra: author);
  }

  static Future<String?> openFileCreate(
    BuildContext context, {
    String? authorId,
  }) {
    final uri = authorId == null || authorId.isEmpty
        ? RpgRoutes.fileCreate
        : '${RpgRoutes.fileCreate}?authorId=$authorId';
    return context.push<String?>(uri);
  }

  static Future<void> openFileDetail(
    BuildContext context,
    ResourceFile file,
  ) {
    return context.push(RpgRoutes.fileDetail(file.id), extra: file);
  }

  static Future<void> openFileEdit(
    BuildContext context,
    ResourceFile file,
  ) {
    return context.push(RpgRoutes.fileEdit(file.id), extra: file);
  }

  static Future<void> openClassCreate(BuildContext context) {
    return context.push(RpgRoutes.classCreate);
  }

  static Future<void> openClassDetail(
    BuildContext context,
    CharacterClass characterClass,
  ) {
    return context.push(
      RpgRoutes.classDetail(characterClass.id),
      extra: characterClass,
    );
  }

  static Future<void> openSpellTagCreate(BuildContext context) {
    return context.push(RpgRoutes.spellTagCreate);
  }

  static Future<void> openSpellCreate(BuildContext context) {
    return context.push(RpgRoutes.spellCreate);
  }

  static Future<void> openSpellDetail(BuildContext context, Spell spell) {
    return context.push(
      RpgRoutes.spellDetail(spell.id),
      extra: spell,
    );
  }
}
