import 'package:eq_raid_boss/Model/item_loot.dart';
import 'package:eq_raid_boss/Providers/blocked_items_variables.dart';
import 'package:eq_raid_boss/Providers/char_log_file_variables.dart';
import 'package:eq_raid_boss/Providers/shared_preferences_provider.dart';
import 'package:eq_raid_boss/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlockedItems extends ConsumerStatefulWidget {
  final SharedPreferences prefs;

  const BlockedItems({
    Key? key,
    required this.prefs,
  }) : super(key: key);

  @override
  ConsumerState createState() => _BlockedItemsState();
}

class _BlockedItemsState extends ConsumerState<BlockedItems> {
  TextEditingController? blockListInputController;

  @override
  void initState() {
    blockListInputController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    blockListInputController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BlockedItemsVariableNotifier blockedVariables = ref.watch(blockedItemsVariableProvider);
    Set<String> blockedItemsSet = blockedVariables.blockedItems.toSet();
    List<String> blockedItems = blockedItemsSet.toList();
    blockedItems.sort();
    return Scaffold(
      body: Stack(
        children: [
          ListView.builder(
            controller: ScrollController(),
            itemCount: blockedItems.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: Text(blockedItems[index]),
                      onLongPress: () {
                        List<ItemLoot> allItems = ref.read(charLogFileVariableProvider).allItemLootsInRange;
                        for (var itemLoot in allItems) {
                          if (itemLoot.itemGiven == blockedItems[index]) {
                            ref.read(charLogFileVariableProvider).itemLoots.add(itemLoot);
                          }
                        }
                        ref.read(charLogFileVariableProvider).itemLoots =
                            ref.read(charLogFileVariableProvider).itemLoots;
                        blockedItems.removeWhere((element) => element == blockedItems[index]);
                        widget.prefs.setStringList('blockedItems', blockedItems);
                        blockedVariables.blockedItems = blockedItems;
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Align(
                alignment: Alignment.topRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        onPressed: () {
                          showAnimatedDialog(
                              AlertDialog(
                                title: const Text('Delete Blocked List'),
                                actions: [
                                  ElevatedButton(
                                      onPressed: () {
                                        ref.read(blockedItemsVariableProvider).blockedItems = [];
                                        ref.read(sharedPreferencesProvider).setStringList('blockedItems', []);
                                        popNavigatorContext(context: context);
                                      },
                                      child: const Text('Yes')),
                                  ElevatedButton(
                                      onPressed: () => popNavigatorContext(context: context), child: const Text('No'))
                                ],
                              ),
                              context);
                        },
                        icon: const Icon(Icons.delete_forever)),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        StringBuffer blockedItemsString = StringBuffer();
                        for (var blockedItem in blockedItems) {
                          blockedItemsString.writeln(blockedItem);
                        }
                        Clipboard.setData(ClipboardData(text: blockedItemsString.toString()));
                        showSnackBar(context: context, message: 'Blocked items copied to clipboard.');
                      },
                    ),
                  ],
                )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: blockListInputController,
                        style: Theme.of(context).textTheme.bodyMedium,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        decoration: const InputDecoration(
                          labelText: 'Items To Block',
                        ),
                      ),
                      ElevatedButton(
                          onPressed: () {
                            Set<String> blocked = widget.prefs.getStringList('blockedItems')!.toSet();
                            Set<String> newBlocked = blockListInputController!.text.split('\n').toSet();
                            blocked.addAll(newBlocked);
                            List<String> sortedBlocked = blocked.toList();
                            sortedBlocked.sort();
                            for (int i = 0; i < sortedBlocked.length; i++) {
                              sortedBlocked[i] = sortedBlocked[i].toLowerCase().trim();
                            }
                            blockedVariables.blockedItems = sortedBlocked;
                            widget.prefs.setStringList('blockedItems', blocked.toList());
                            Navigator.pop(context);
                          },
                          child: const Text('Block')),
                    ],
                  ),
                ),
              );
            },
          ).then((value) => blockListInputController!.clear());
        },
      ),
    );
  }
}
