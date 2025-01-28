import 'package:eq_raid_boss/Model/chat_channel_loot.dart';
import 'package:eq_raid_boss/Providers/char_log_file_variables.dart';
import 'package:eq_raid_boss/Providers/chat_channel_loots_provider.dart';
import 'package:eq_raid_boss/Providers/loots_sortable_table_variables.dart';
import 'package:eq_raid_boss/Widgets/help_icon.dart';
import 'package:eq_raid_boss/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Providers/blocked_items_variables.dart';

class ChatChannelLinkedLootsSortableTable extends ConsumerStatefulWidget {
  final SharedPreferences prefs;

  const ChatChannelLinkedLootsSortableTable({super.key, required this.prefs});

  @override
  LootsSortableTableState createState() => LootsSortableTableState();
}

class LootsSortableTableState extends ConsumerState<ChatChannelLinkedLootsSortableTable> {
  final TextEditingController chatChannelController = TextEditingController();
  List<ChatChannelLoot> chatChannelLoots = [];
  int buildCount = 0;

  @override
  void dispose() {
    chatChannelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    chatChannelLoots = ref.watch(charLogFileVariableProvider).chatChannelLoots;
    String chatChannel = ref.watch(chatChannelProvider);
    final columns = ['Time', 'Item', 'Linked By'];
    bool isAscending = ref.watch(lootsSortableTableVariableProvider).isAscending;
    int sortColumnIndex = ref.watch(lootsSortableTableVariableProvider).sortColumnIndex;
    onSort(sortColumnIndex, isAscending);
    return Scaffold(
      body: SingleChildScrollView(
          controller: ScrollController(),
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    child: PaginatedDataTable(
                      header: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                              onPressed: () {
                                chatChannelController.clear();
                                showAnimatedDialog(
                                    AlertDialog(
                                      title: Text('Set Chat Channel'),
                                      content: Column(spacing: 8.0, mainAxisSize: MainAxisSize.min, children: [
                                        Text(
                                            'Set a case-sensitive chat channel to parse loot from.  To create a channel in EverQuest type /join channelName:password.  To auto-join multiple channels in EverQuest type /join General, channelName:password,...  To link loot from the advanced loot window, set your default chat channel to the channel you created for loot collecting and right click the name of the NPC\'s loot you would like to link.'),
                                        TextField(
                                          autofocus: true,
                                            controller: chatChannelController,
                                            style: Theme.of(context).textTheme.bodyMedium,
                                            decoration: const InputDecoration(
                                              labelText: 'Channel Name',
                                            ),
                                            onSubmitted: (text) {
                                              _submitNewChatChannel();
                                            }),
                                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                          ElevatedButton(
                                              onPressed: () => _submitNewChatChannel(), child: Text('Submit'))
                                        ])
                                      ]),
                                    ),
                                    context);
                              },
                              icon: Icon(Icons.edit)),
                          Text(chatChannel.isNotEmpty ? 'Chat Channel: $chatChannel' : 'Chat channel not set.')
                        ],
                      ),
                      sortAscending: isAscending,
                      sortColumnIndex: sortColumnIndex,
                      columns: getColumns(columns),
                      source: MyData(chatChannelLoots: chatChannelLoots, ref: ref, prefs: widget.prefs),
                      rowsPerPage: 100,
                      showFirstLastButtons: true,
                    ),
                  )
                ],
              ),
              //_outputLootSummary(lootedItems: itemLoots);
              Positioned(
                right: 0,
                top: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(
                          Icons.copy,
                        ),
                        onPressed: () => showAnimatedDialog(
                            AlertDialog(
                                title: const Text('Output Loot'),
                                actionsAlignment: MainAxisAlignment.spaceBetween,
                                actions: [
                                  ElevatedButton(
                                      onPressed: () =>
                                          _outputLootSummary(chatChannelLoots: chatChannelLoots, allInfo: true),
                                      child: const Text('All Loot Info')),
                                  ElevatedButton(
                                      onPressed: () =>
                                          _outputLootSummary(chatChannelLoots: chatChannelLoots, allInfo: false),
                                      child: const Text('Items Only'))
                                ]),
                            context)),
                    const HelpIcon(
                      helpText:
                          'Sort columns by clicking on the column header.  Quick block single items with a long press on the item.  Press the copy button to output to clipboard for easy spreadsheet or Raid Builder pasting.',
                      title: 'Loots Info',
                    )
                  ],
                ),
              )
            ],
          )),
    );
  }

  List<DataColumn> getColumns(List<String> columns) => columns
      .map((String column) => DataColumn(
            label: Text(column),
            onSort: onSort,
          ))
      .toList();

  //['Time', 'Item', 'Linked By']
  void onSort(int columnIndex, bool ascending) {
    //time
    if (columnIndex == 0) {
      chatChannelLoots.sort((a, b) {
        if (ascending) {
          if (a.time.millisecondsSinceEpoch == b.time.millisecondsSinceEpoch) {
            if (a.linkedBy == b.linkedBy) {
              if (a.itemName == b.itemName) {
                return a.id.compareTo(b.id);
              }
              return a.itemName.compareTo(b.itemName);
            }
            return a.linkedBy.compareTo(b.linkedBy);
          }
          return b.time.millisecondsSinceEpoch.compareTo(a.time.millisecondsSinceEpoch);
        } else {
          if (a.time.millisecondsSinceEpoch == b.time.millisecondsSinceEpoch) {
            if (a.linkedBy == b.linkedBy) {
              if (a.itemName == b.itemName) {
                return a.id.compareTo(b.id);
              }
              return a.itemName.compareTo(b.itemName);
            }
            return a.linkedBy.compareTo(b.linkedBy);
          }
          return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
        }
      });
    }
    //item
    else if (columnIndex == 1) {
      chatChannelLoots.sort((a, b) {
        if (ascending) {
          if (a.itemName == b.itemName) {
            if (a.time.millisecondsSinceEpoch == b.time.millisecondsSinceEpoch) {
              if (a.linkedBy == b.linkedBy) {
                return a.id.compareTo(b.id);
              }
              return a.linkedBy.compareTo(b.linkedBy);
            }
            return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
          }
          return a.itemName.compareTo(b.itemName);
        } else {
          if (a.itemName == b.itemName) {
            if (a.time.millisecondsSinceEpoch == b.time.millisecondsSinceEpoch) {
              if (a.linkedBy == b.linkedBy) {
                return a.id.compareTo(b.id);
              }
              return a.linkedBy.compareTo(b.linkedBy);
            }
            return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
          }
          return b.itemName.compareTo(a.itemName);
        }
      });
    }
    //linked by
    else if (columnIndex == 2) {
      chatChannelLoots.sort((a, b) {
        if (ascending) {
          if (a.linkedBy == b.linkedBy) {
            if (a.time.millisecondsSinceEpoch == b.time.millisecondsSinceEpoch) {
              if (a.itemName == b.itemName) {
                return a.id.compareTo(b.id);
              }
              return a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase());
            }
            return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
          }
          return a.linkedBy.compareTo(b.linkedBy);
        } else {
          if (a.linkedBy == b.linkedBy) {
            if (a.time.millisecondsSinceEpoch == b.time.millisecondsSinceEpoch) {
              if (a.itemName == b.itemName) {
                return a.id.compareTo(b.id);
              }
              return a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase());
            }
            return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
          }
          return b.linkedBy.compareTo(a.linkedBy);
        }
      });
    }
    ref.read(lootsSortableTableVariableProvider).sortColumnIndex = columnIndex;
    ref.read(lootsSortableTableVariableProvider).isAscending = ascending;
  }

  void _outputLootSummary({required List<ChatChannelLoot> chatChannelLoots, required bool allInfo}) {
    StringBuffer output = StringBuffer();

    if (allInfo) {
      for (var item in chatChannelLoots) {
        output.writeln('${DateFormat('EEE, MMM d, h:mm a').format(item.time)};${item.itemName};${item.linkedBy}');
      }
    } else {
      for (var item in chatChannelLoots) {
        output.writeln(item.itemName);
      }
    }
    popNavigatorContext(context: context);
    Clipboard.setData(ClipboardData(text: output.toString()));
    showSnackBar(context: context, message: 'Loot summary copied to clipboard.');
  }

  void _submitNewChatChannel() {
    String name = chatChannelController.text.trim();
    widget.prefs.setString('chatChannel', name);
    ref.read(chatChannelProvider.notifier).setChatChannel(channel: name);
    refreshData(ref: ref);
    popNavigatorContext(context: context);
  }
}

class MyData extends DataTableSource {
  final List<ChatChannelLoot> chatChannelLoots;
  final WidgetRef ref;
  final SharedPreferences prefs;
  int hereCount = 0;

  MyData({required this.chatChannelLoots, required this.ref, required this.prefs});

  @override
  DataRow? getRow(int index) {
    ChatChannelLoot chatChannelLoot = chatChannelLoots[index];
    List<DataCell> cells = [
      DataCell(Text(DateFormat('EEE, MMM d, h:mm:ss a').format(chatChannelLoot.time))),
      DataCell(
        InkWell(
          child: Text(
            chatChannelLoot.itemName,
            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
          ),
          onLongPress: () {
            List<String> blockedItems = ref.read(blockedItemsVariableProvider).blockedItems;
            blockedItems.add(chatChannelLoot.itemName.toLowerCase());
            blockedItems.sort();
            ref
                .read(charLogFileVariableProvider)
                .chatChannelLoots
                .removeWhere((element) => element.itemName == chatChannelLoot.itemName);
            ref.read(blockedItemsVariableProvider).blockedItems = blockedItems;
            prefs.setStringList('blockedItems', blockedItems);
          },
        ),
      ),
      DataCell(Text(chatChannelLoot.linkedBy))
    ];
    return DataRow(cells: cells, key: ValueKey(chatChannelLoot.id));
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => chatChannelLoots.length;

  @override
  int get selectedRowCount => 0;
}
