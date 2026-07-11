import 'package:flutter/material.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';

class ResourcesExpandableFab extends StatefulWidget {
  const ResourcesExpandableFab({
    super.key,
    this.selectedAuthorId,
    this.onChanged,
  });

  final String? selectedAuthorId;
  final VoidCallback? onChanged;

  @override
  State<ResourcesExpandableFab> createState() => _ResourcesExpandableFabState();
}

class _ResourcesExpandableFabState extends State<ResourcesExpandableFab>
    with SingleTickerProviderStateMixin {
  bool _open = false;

  void _toggle() => setState(() => _open = !_open);

  Future<void> _addAuthor() async {
    _toggle();
    await RpgNavigation.openAuthorCreate(context);
    widget.onChanged?.call();
  }

  Future<void> _addFile() async {
    _toggle();
    await RpgNavigation.openFileCreate(
      context,
      authorId: widget.selectedAuthorId,
    );
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open) ...[
          FloatingActionButton.extended(
            heroTag: 'add_file',
            onPressed: _addFile,
            icon: const Icon(Icons.insert_drive_file_outlined),
            label: const Text('Add file'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add_author',
            onPressed: _addAuthor,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Add author'),
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          heroTag: 'resources_main_fab',
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(_open ? Icons.close : Icons.add),
          ),
        ),
      ],
    );
  }
}
