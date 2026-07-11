import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';
import 'package:rpg_companion/features/dm_tools/resources/services/resource_record_resolver.dart';
import 'package:rpg_companion/features/player/classes/widgets/class_list_tile.dart';
import 'package:rpg_companion/features/player/services/player_record_resolver.dart';

class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  int _refreshNonce = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchClasses());
  }

  void _fetchClasses() {
    context.read<RecordBloc>().remoteCoordinator?.refreshQueryRecords(
          classesListQuery,
        );
  }

  Future<void> _openCreateClass() async {
    await RpgNavigation.openClassCreate(context);
    if (!mounted) return;
    setState(() => _refreshNonce++);
    _fetchClasses();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordBloc, RecordState>(
      buildWhen: (previous, current) {
        if (_refreshNonce > 0) return true;
        return queryRecordsDisplayChanged(
          previous: previous,
          current: current,
          query: classesListQuery,
          recordType: 'classes',
        );
      },
      builder: (context, state) {
        final classes = resolveClasses(state, classesListQuery);

        return Scaffold(
          body: classes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IconRegistry.instance.getIconData('Graduation Cap') ??
                              Icons.school_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No classes yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a class to start building your character options.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: classes.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return ClassListTile(
                      characterClass: classes[index],
                      onTap: () => RpgNavigation.openClassDetail(
                        context,
                        classes[index],
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'add_class',
            onPressed: _openCreateClass,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
