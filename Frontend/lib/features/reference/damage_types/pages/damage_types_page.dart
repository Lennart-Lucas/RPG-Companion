import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';
import 'package:rpg_companion/features/dm_tools/resources/services/resource_record_resolver.dart';
import 'package:rpg_companion/features/player/services/player_record_resolver.dart';
import 'package:rpg_companion/features/reference/damage_types/widgets/damage_type_list_tile.dart';

class DamageTypesPage extends StatefulWidget {
  const DamageTypesPage({super.key});

  @override
  State<DamageTypesPage> createState() => _DamageTypesPageState();
}

class _DamageTypesPageState extends State<DamageTypesPage> {
  int _refreshNonce = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDamageTypes());
  }

  void _fetchDamageTypes() {
    context.read<RecordBloc>().remoteCoordinator?.refreshQueryRecords(
          damageTypesListQuery,
        );
  }

  Future<void> _openCreateDamageType() async {
    await RpgNavigation.openDamageTypeCreate(context);
    if (!mounted) return;
    setState(() => _refreshNonce++);
    _fetchDamageTypes();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordBloc, RecordState>(
      buildWhen: (previous, current) {
        if (_refreshNonce > 0) return true;
        return queryRecordsDisplayChanged(
          previous: previous,
          current: current,
          query: damageTypesListQuery,
          recordType: 'damage_types',
        );
      },
      builder: (context, state) {
        final damageTypes = resolveDamageTypes(state, damageTypesListQuery);

        return Scaffold(
          body: damageTypes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IconRegistry.instance.getIconData('Fire Flame') ??
                              Icons.local_fire_department_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No damage types yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add damage types for spells, creatures, and items.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: damageTypes.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return DamageTypeListTile(damageType: damageTypes[index]);
                  },
                ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'add_damage_type',
            onPressed: _openCreateDamageType,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
