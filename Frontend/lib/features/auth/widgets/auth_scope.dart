import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Handles auth loading overlay for [MaterialApp.router].
class AuthScope extends StatelessWidget {
  const AuthScope({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthUnknown || state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
