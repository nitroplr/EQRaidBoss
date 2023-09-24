import 'package:eq_raid_boss/Model/item_loot.dart';
import 'package:eq_raid_boss/Providers/char_log_file_variables.dart';
import 'package:eq_raid_boss/Providers/loots_sortable_table_variables.dart';
import 'package:eq_raid_boss/Widgets/help_icon.dart';
import 'package:eq_raid_boss/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Providers/blocked_items_variables.dart';

class LootsSortableTable extends ConsumerStatefulWidget {
  final SharedPreferences prefs;

  const LootsSortableTable({Key? key, required this.prefs}) : super(key: key);

  @override
  LootsSortableTableState createState() => LootsSortableTableState();
}

class LootsSortableTableState extends ConsumerState<LootsSortableTable> {
  List<ItemLoot> itemLoots = [];

  @override
  Widget build(BuildContext context) {
    itemLoots = ref.watch(charLogFileVariableProvider).itemLoots;
    final columns = ['Time', 'Looter', 'Item', 'Dropped By'];
    bool isAscending = ref.watch(lootsSortableTableVariableProvider).isAscending;
    int sortColumnIndex = ref.watch(lootsSortableTableVariableProvider).sortColumnIndex;
    onSort(sortColumnIndex, isAscending);
    return Scaffold(
      body: SingleChildScrollView(
          controller: ScrollController(),
          child: SizedBox(
            width: double.maxFinite,
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DataTable(
                        sortAscending: isAscending,
                        sortColumnIndex: sortColumnIndex,
                        columns: getColumns(columns),
                        rows: getRows(itemLoots),
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
                                        onPressed: () => _outputLootSummary(lootedItems: itemLoots, allInfo: true),
                                        child: const Text('All Loot Info')),
                                    ElevatedButton(
                                        onPressed: () => _outputLootSummary(lootedItems: itemLoots, allInfo: false),
                                        child: const Text('Items Only'))
                                  ]),
                              context)),
                      const HelpIcon(helpText: 'Sort columns by clicking on the column header.  Quick block single items with a long press on the item.  Press the copy button to output to clipboard for easy spreadsheet or Raid Builder pasting.', title: 'Loots Info',)
                    ],
                  ),
                )
              ],
            ),
          )),
    );
  }

  List<DataColumn> getColumns(List<String> columns) => columns
      .map((String column) => DataColumn(
            label: Text(column),
            onSort: onSort,
          ))
      .toList();

  //['Time', 'Looter', 'Item', 'Dropped By']
  List<DataRow> getRows(List<ItemLoot> itemLoots) => itemLoots.map((ItemLoot itemLoot) {
        return DataRow(key: ValueKey(itemLoot.id), cells: [
          DataCell(Text(DateFormat('EEE, MMM d, h:mm:ss a').format(itemLoot.time))),
          DataCell(Text(itemLoot.looter)),
          DataCell(
            InkWell(
              child: Text(
                itemLoot.itemLooted == null ? '${itemLoot.itemGiven} (given not looted)' : itemLoot.itemLooted!,
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
              ),
              onLongPress: () {
                List<String> blockedItems = ref.read(blockedItemsVariableProvider).blockedItems;
                blockedItems.add(itemLoot.itemGiven.toLowerCase());
                blockedItems.sort();
                ref
                    .read(charLogFileVariableProvider)
                    .itemLoots
                    .removeWhere((element) => element.itemGiven == itemLoot.itemGiven);
                ref.read(blockedItemsVariableProvider).blockedItems = blockedItems;
                widget.prefs.setStringList('blockedItems', blockedItems);
              },
            ),
          ),
          DataCell(Text(itemLoot.droppedBy != null ? itemLoot.droppedBy! : ''))
        ]);
      }).toList();

  List<DataCell> getCells(List<dynamic> cells) => cells.map((data) {
        var potentialDate = int.tryParse(data.toString());
        if (potentialDate != null) {
          return DataCell(
              Text(DateFormat('EEE, MMM d, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(potentialDate))));
        }
        return DataCell(Text('$data'));
      }).toList();

  //['Time', 'Looter', 'Item', 'Dropped By']
  void onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      itemLoots.sort((a, b) {
        if ((a.itemLooted == null) && (b.itemLooted != null)) {
          return -1;
        }
        if ((b.itemLooted == null) && (a.itemLooted != null)) {
          return 1;
        }
        if (ascending) {
          if (a.time.millisecondsSinceEpoch == b.time.millisecondsSinceEpoch) {
            if (a.looter == b.looter) {
              if (a.itemGiven == b.itemGiven) {
                if ((a.droppedBy == null) || (b.droppedBy == null)) {
                  return a.id.compareTo(b.id);
                }
                return a.droppedBy!.compareTo(b.droppedBy!);
              }
              return a.itemGiven.compareTo(b.itemGiven);
            }
            return a.looter.compareTo(b.looter);
          }
          return b.time.millisecondsSinceEpoch.compareTo(a.time.millisecondsSinceEpoch);
        } else {
          if (a.time.millisecondsSinceEpoch == b.time.millisecondsSinceEpoch) {
            if (a.looter == b.looter) {
              if (a.itemGiven == b.itemGiven) {
                if ((a.droppedBy == null) || (b.droppedBy == null)) {
                  return a.id.compareTo(b.id);
                }
                return a.droppedBy!.compareTo(b.droppedBy!);
              }
              return a.itemGiven.compareTo(b.itemGiven);
            }
            return a.looter.compareTo(b.looter);
          }
          return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
        }
      });
    }
    //sort based on looter, then item, then time
    else if (columnIndex == 1) {
      itemLoots.sort((a, b) {
        if ((a.itemLooted == null) && (b.itemLooted != null)) {
          return -1;
        }
        if ((b.itemLooted == null) && (a.itemLooted != null)) {
          return 1;
        }
        if (ascending) {
          if (a.looter == b.looter) {
            if (a.itemGiven == b.itemGiven) {
              return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
            }
            return a.itemGiven.compareTo(b.itemGiven);
          }
          return a.looter.compareTo(b.looter);
        } else {
          if (a.looter == b.looter) {
            if (a.itemGiven == b.itemGiven) {
              return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
            }
            return a.itemGiven.compareTo(b.itemGiven);
          }
          return b.looter.compareTo(a.looter);
        }
      });
    }
    //sort based on item, then time
    else if (columnIndex == 2) {
      itemLoots.sort((a, b) {
        if ((a.itemLooted == null) && (b.itemLooted != null)) {
          return -1;
        }
        if ((b.itemLooted == null) && (a.itemLooted != null)) {
          return 1;
        }
        if (ascending) {
          if (a.itemGiven == b.itemGiven) {
            return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
          }
          return a.itemGiven.compareTo(b.itemGiven);
        } else {
          if (a.itemGiven == b.itemGiven) {
            return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
          }
          return b.itemGiven.compareTo(a.itemGiven);
        }
      });
    }
    //sort based on dropper, then time
    else if (columnIndex == 3) {
      itemLoots.sort((a, b) {
        if ((a.itemLooted == null) && (b.itemLooted != null)) {
          return -1;
        }
        if ((b.itemLooted == null) && (a.itemLooted != null)) {
          return 1;
        }
        if (ascending) {
          if ((a.droppedBy == b.droppedBy) || (a.droppedBy == null) || (b.droppedBy == null)) {
            if (a.time.millisecondsSinceEpoch == b.time.millisecondsSinceEpoch) {
              return a.itemGiven.compareTo(b.itemGiven);
            }
            return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
          }
          return a.droppedBy!.compareTo(b.droppedBy!);
        } else {
          if ((a.droppedBy == b.droppedBy) || (a.droppedBy == null) || (b.droppedBy == null)) {
            if (a.time.millisecondsSinceEpoch == b.time.millisecondsSinceEpoch) {
              return a.itemGiven.compareTo(b.itemGiven);
            }
            return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
          }
          return b.droppedBy!.compareTo(a.droppedBy!);
        }
      });
    }
    ref.read(lootsSortableTableVariableProvider).sortColumnIndex = columnIndex;
    ref.read(lootsSortableTableVariableProvider).isAscending = ascending;
  }

  void _outputLootSummary({required List<ItemLoot> lootedItems, required bool allInfo}) {
    List<ItemLoot> sortedLoots = lootedItems;

    sortedLoots.sort((a, b) {
      if ((a.itemLooted == null) && (b.itemLooted != null)) {
        return -1;
      }
      if ((b.itemLooted == null) && (a.itemLooted != null)) {
        return 1;
      }
      if (a.itemGiven == b.itemGiven) {
        return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
      }
      return a.itemGiven.compareTo(b.itemGiven);
    });

    StringBuffer output = StringBuffer();

    if (allInfo) {
      for (var item in lootedItems) {
        for (int i = 0; i < item.quantity; i++) {
          output.writeln(item.itemLooted == null
              ? '${DateFormat('EEE, MMM d, h:mm a').format(item.time)};${item.looter};${item.itemGiven} (given not looted);${item.droppedBy}'
              : '${DateFormat('EEE, MMM d, h:mm a').format(item.time)};${item.looter};${item.itemLooted};${item.droppedBy}');
        }
      }
    } else {
      for (var item in lootedItems) {
        output.writeln(item.itemLooted == null ? '${item.itemGiven} (given not looted)' : '${item.itemLooted}');
      }
    }
    popNavigatorContext(context: context);
    Clipboard.setData(ClipboardData(text: output.toString()));
    showSnackBar(context: context, message: 'Loot summary copied to clipboard.');
  }
}
