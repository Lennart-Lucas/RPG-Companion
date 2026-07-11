import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';
import 'package:rpg_companion/features/dm_tools/resources/services/resource_record_resolver.dart';
import 'package:rpg_companion/features/player/services/player_record_resolver.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_list_tile.dart';
import 'package:rpg_companion/features/player/spells/widgets/spells_expandable_fab.dart';

class SpellsPage extends StatefulWidget {
  const SpellsPage({super.key});

  @override
  State<SpellsPage> createState() => _SpellsPageState();
}

class _SpellsPageState extends State<SpellsPage> {
  int _refreshNonce = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchSpells());
  }

  void _fetchSpells() {
    context.read<RecordBloc>().remoteCoordinator?.refreshQueryRecords(
          spellsListQuery,
        );
  }

  void _onFabChanged() {
    if (!mounted) return;
    setState(() => _refreshNonce++);
    _fetchSpells();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordBloc, RecordState>(
      buildWhen: (previous, current) {
        if (_refreshNonce > 0) return true;
        return queryRecordsDisplayChanged(
          previous: previous,
          current: current,
          query: spellsListQuery,
          recordType: 'spells',
        );
      },
      builder: (context, state) {
        final spells = resolveSpells(state, spellsListQuery);

        return Scaffold(
          body: spells.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IconRegistry.instance
                                  .getIconData('Wand Magic Sparkles') ??
                              Icons.auto_fix_high_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No spells yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a spell or spell tag using the button below.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: spells.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return SpellListTile(
                      spell: spells[index],
                      onTap: () => RpgNavigation.openSpellDetail(
                        context,
                        spells[index],
                      ),
                    );
                  },
                ),
          floatingActionButton: SpellsExpandableFab(
            onChanged: _onFabChanged,
          ),
        );
      },
    );
  }
}
