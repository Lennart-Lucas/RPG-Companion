import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/app/rpg_anvil_app.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';
import 'package:rpg_companion/features/auth/widgets/auth_scope.dart';

class RpgCompanionApp extends StatefulWidget {
  const RpgCompanionApp({super.key});

  @override
  State<RpgCompanionApp> createState() => _RpgCompanionAppState();
}

class _RpgCompanionAppState extends State<RpgCompanionApp> {
  @override
  void initState() {
    super.initState();
    RpgRouterHost.init(RpgAnvilApp.instance.authBloc);
  }

  @override
  Widget build(BuildContext context) {
    final router = RpgRouterHost.instance.router;

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(
          value: RpgAnvilApp.instance.authBloc,
        ),
        BlocProvider<RecordBloc>.value(
          value: RpgAnvilApp.instance.recordBloc,
        ),
      ],
      child: MaterialApp.router(
        title: 'RPG Companion',
        debugShowCheckedModeBanner: false,
        theme: theHubTheme,
        themeMode: ThemeMode.dark,
        routerConfig: router,
        builder: (context, child) => AuthScope(child: child),
      ),
    );
  }
}
