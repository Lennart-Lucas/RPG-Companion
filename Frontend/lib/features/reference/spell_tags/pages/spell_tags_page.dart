import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';
import 'package:rpg_companion/core/routing/rpg_navigation.dart';
import 'package:rpg_companion/features/dm_tools/resources/services/resource_record_resolver.dart';
import 'package:rpg_companion/features/player/services/player_record_resolver.dart';
import 'package:rpg_companion/features/reference/spell_tags/widgets/spell_tag_list_tile.dart';

class SpellTagsPage extends StatefulWidget {
  const SpellTagsPage({super.key});

  @override
  State<SpellTagsPage> createState() => _SpellTagsPageState();
}

class _SpellTagsPageState extends State<SpellTagsPage> {
  int _refreshNonce = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchSpellTags());
  }

  void _fetchSpellTags() {
    context.read<RecordBloc>().remoteCoordinator?.refreshQueryRecords(
          spellTagsListQuery,
        );
  }

  Future<void> _openCreateSpellTag() async {
    await RpgNavigation.openSpellTagCreate(context);
    if (!mounted) return;
    setState(() => _refreshNonce++);
    _fetchSpellTags();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordBloc, RecordState>(
      buildWhen: (previous, current) {
        if (_refreshNonce > 0) return true;
        return queryRecordsDisplayChanged(
          previous: previous,
          current: current,
          query: spellTagsListQuery,
          recordType: 'spell_tags',
        );
      },
      builder: (context, state) {
        final spellTags = resolveSpellTags(state, spellTagsListQuery);

        return Scaffold(
          body: spellTags.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IconRegistry.instance.getIconData('Tag') ??
                              Icons.sell_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No spell tags yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add tags to categorize and filter spells.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: spellTags.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return SpellTagListTile(spellTag: spellTags[index]);
                  },
                ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'add_spell_tag',
            onPressed: _openCreateSpellTag,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
