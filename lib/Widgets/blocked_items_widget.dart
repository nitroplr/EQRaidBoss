import 'package:eq_raid_boss/Providers/blocked_items_variables.dart';
import 'package:flutter/material.dart';
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
      body: ListView.builder(controller: ScrollController(),itemCount: blockedItems.length, itemBuilder:
          (BuildContext context, int index) {
        return TextButton(onPressed: () {}, child: Text(blockedItems[index]), onLongPress: () {
          blockedItems.removeWhere((element) => element == blockedItems[index]);
          widget.prefs.setStringList('blockedItems', blockedItems);
          blockedVariables.blockedItems = blockedItems;
        },);
      },),
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
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodyText2,
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
                            for(int i = 0; i < sortedBlocked.length; i++){
                              sortedBlocked[i] = sortedBlocked[i].toLowerCase().trim();
                            }
                            blockedVariables.blockedItems = sortedBlocked;
                            widget.prefs.setStringList('blockedItems', blocked.toList());
                            Navigator.pop(context);
                          },
                          child: Text('Block')),
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