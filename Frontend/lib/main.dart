import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:rpg_companion/app/rpg_companion_app.dart';
import 'package:rpg_companion/core/app/rpg_anvil_app.dart';
import 'package:rpg_companion/core/auth/shared_preferences_token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferencesTokenStorage.init();
  await RpgAnvilApp.init();
  RpgAnvilApp.instance.authBloc.add(const AppStarted());
  runApp(const RpgCompanionApp());
}
