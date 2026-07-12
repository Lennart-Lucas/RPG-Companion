import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Controls the shell [CollapsibleDrawer] app bar for pushed detail routes.
final class RpgShellAppBar {
  RpgShellAppBar._();

  static final appBarOverrideListenable =
      ValueNotifier<DrawerAppBarOverride?>(null);

  static final showSectionFooterListenable = ValueNotifier<bool>(true);

  static void setDetail({
    required VoidCallback onBack,
    String? title,
    List<Widget>? actions,
  }) {
    appBarOverrideListenable.value = DrawerAppBarOverride(
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack,
      ),
      title: title,
      useEmptyTitle: title == null,
      actions: actions,
    );
    showSectionFooterListenable.value = false;
  }

  static void syncDetail({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
  }) {
    setDetail(
      onBack: () => popDetail(context),
      title: title,
      actions: actions,
    );
  }

  static List<Widget> editDeleteActions({
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    bool deleting = false,
  }) {
    return [
      IconButton(
        tooltip: 'Edit',
        onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined),
      ),
      IconButton(
        tooltip: 'Delete',
        onPressed: deleting ? null : onDelete,
        icon: const Icon(Icons.delete_outline),
      ),
    ];
  }

  static Future<bool> confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }

  static void showBackOnly({required VoidCallback onBack}) {
    setDetail(onBack: onBack);
  }

  static void clear() {
    if (appBarOverrideListenable.value == null &&
        showSectionFooterListenable.value) {
      return;
    }
    appBarOverrideListenable.value = null;
    showSectionFooterListenable.value = true;
  }

  static void popDetail(BuildContext context) {
    clear();
    context.pop();
  }
}

/// Detail page body with a large background icon.
class RpgDetailPageBody extends StatelessWidget {
  const RpgDetailPageBody({
    super.key,
    required this.icon,
    required this.child,
    this.loading = false,
  });

  final IconData icon;
  final Widget child;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AnvilBackgroundIcon(
      icon: icon,
      opacity: 0.32,
      baseSize: 260,
      child: loading ? const Center(child: CircularProgressIndicator()) : child,
    );
  }
}

/// Applies a back-only shell app bar while this route is visible.
mixin RpgShellDetailPage<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      RpgShellAppBar.showBackOnly(onBack: _popDetail);
    });
  }

  @override
  void dispose() {
    RpgShellAppBar.clear();
    super.dispose();
  }

  void _popDetail() {
    if (!mounted) return;
    RpgShellAppBar.popDetail(context);
  }
}

/// Tracks shell app bar title/actions for a loaded record detail page.
mixin RpgShellRecordDetailPage<T extends StatefulWidget> on State<T> {
  @protected
  void disposeShellDetailAppBar() {
    RpgShellAppBar.clear();
  }

  @protected
  void syncShellDetailAppBar({
    required String title,
    List<Widget>? actions,
  }) {
    RpgShellAppBar.syncDetail(
      context: context,
      title: title,
      actions: actions,
    );
  }
}
