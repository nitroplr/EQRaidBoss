import 'package:eq_raid_boss/Model/item_loot.dart';
import 'package:eq_raid_boss/Providers/char_log_file_variables.dart';
import 'package:eq_raid_boss/Providers/loots_sortable_table_variables.dart';
import 'package:flutter/material.dart';
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
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: double.maxFinite,
            child: DataTable(
              sortAscending: isAscending,
              sortColumnIndex: sortColumnIndex,
              columns: getColumns(columns),
              rows: getRows(itemLoots),
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

  List<DataRow> getRows(List<ItemLoot> itemLoots) => itemLoots.map((ItemLoot itemLoot) {
        return DataRow(cells: [
          DataCell(Text(DateFormat('EEE, MMM d, h:mm a').format(itemLoot.time))),
          DataCell(Text(itemLoot.looter)),
          DataCell(
            InkWell(
              child: Text(
                itemLoot.item,
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
              ),
              onLongPress: () {
                List<String> blockedItems = ref.read(blockedItemsVariableProvider).blockedItems;
                blockedItems.add(itemLoot.item);
                blockedItems.sort();
                ref.read(charLogFileVariableProvider).itemLoots.removeWhere((element) => element.item ==
                    itemLoot.item);
                ref.read(blockedItemsVariableProvider).blockedItems = blockedItems;
                widget.prefs.setStringList('blockedItems', blockedItems);
              },
            ),
          ),
          DataCell(Text(itemLoot.droppedBy))
        ]);
      }).toList();

  List<DataCell> getCells(List<dynamic> cells) => cells.map((data) {
        var potentialDate = int.tryParse(data.toString());
        if (potentialDate != null) {
          return DataCell(Text(
              DateFormat('EEE, MMM d, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(potentialDate))));
        }
        return DataCell(Text('$data'));
      }).toList();

  void onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      itemLoots.sort(
          (a, b) {
            if (ascending) {
              if (a.time.millisecondsSinceEpoch == b.time.millisecondsSinceEpoch) {
                if (a.looter == b.looter) {
                  if (a.item == b.item) {
                    return a.droppedBy.compareTo(b.droppedBy);
                  }
                  return a.item.compareTo(b.item);
                }
                return a.looter.compareTo(b.looter);
              }
              return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
            }else {

              if (a.time.millisecondsSinceEpoch == b.time.millisecondsSinceEpoch) {
                if (a.looter == b.looter) {
                  if (a.item == b.item) {
                    return a.droppedBy.compareTo(b.droppedBy);
                  }
                  return a.item.compareTo(b.item);
                }
                return a.looter.compareTo(b.looter);
              }
              return b.time.millisecondsSinceEpoch.compareTo(a.time.millisecondsSinceEpoch);
            }
          });
    }
    //sort based on looter, then item, then time
    else if (columnIndex == 1) {
      itemLoots.sort((a, b) {
        if (ascending) {
          if (a.looter == b.looter) {
            if (a.item == b.item) {
              return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
            }
            return a.item.compareTo(b.item);
          }
          return a.looter.compareTo(b.looter);
        }else {
          if (a.looter == b.looter) {
            if (a.item == b.item) {
              return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
            }
            return a.item.compareTo(b.item);
          }
          return b.looter.compareTo(a.looter);
        }
      });
    }
    //sort based on item, then time
    else if (columnIndex == 2) {
      itemLoots.sort((a, b) {
        if (ascending) {
          if (a.item == b.item) {
            return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
          }
          return a.item.compareTo(b.item);
        }else {
          if (a.item == b.item) {
            return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
          }
          return b.item.compareTo(a.item);
        }
      });
    }
    //sort based on dropper, then time
    else if (columnIndex == 3) {
      itemLoots.sort((a, b) {
        if (ascending) {
          if (a.droppedBy == b.droppedBy) {
            if (a.time.millisecondsSinceEpoch == b.time.millisecondsSinceEpoch) {
              return a.item.compareTo(b.item);
            }
            return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
          }
          return a.droppedBy.compareTo(b.droppedBy);
        }else {
          if (a.droppedBy == b.droppedBy) {
            if (a.time.millisecondsSinceEpoch == b.time.millisecondsSinceEpoch) {
              return a.item.compareTo(b.item);
            }
            return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
          }
          return b.droppedBy.compareTo(a.droppedBy);
        }
      });
    }
    ref.read(lootsSortableTableVariableProvider).sortColumnIndex = columnIndex;
    ref.read(lootsSortableTableVariableProvider).isAscending = ascending;
  }
}