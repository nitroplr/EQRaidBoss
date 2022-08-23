import 'package:eq_raid_boss/Model/item_loot.dart';
import 'package:eq_raid_boss/Providers/loots_sortable_table_variables.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Providers/blocked_items_variables.dart';

class LootsSortableTable extends ConsumerStatefulWidget {
  final List<ItemLoot> itemLoots;
  final SharedPreferences prefs;

  const LootsSortableTable({Key? key, required this.itemLoots, required this.prefs}) : super(key: key);

  @override
  LootsSortableTableState createState() => LootsSortableTableState();
}

class LootsSortableTableState extends ConsumerState<LootsSortableTable> {

  @override
  Widget build(BuildContext context) {
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
              rows: getRows(),
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

  List<DataRow> getRows() => widget.itemLoots.map((ItemLoot itemLoot) {
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
      widget.itemLoots.sort(
          (a, b) => compareTime(ascending, a.time.millisecondsSinceEpoch, b.time.millisecondsSinceEpoch));
    }
    //sort based on looter, then item, then time
    else if (columnIndex == 1) {
      widget.itemLoots.sort((a, b) {
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
      widget.itemLoots.sort((a, b) {
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
      widget.itemLoots.sort((a, b) {
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

  int compareString(bool ascending, String value1, String value2) =>
      ascending ? value1.compareTo(value2) : value2.compareTo(value1);

  int compareTime(bool ascending, int millisecondsSinceEpoch, int millisecondsSinceEpoch2) => ascending
      ? millisecondsSinceEpoch.compareTo(millisecondsSinceEpoch2)
      : millisecondsSinceEpoch2.compareTo(millisecondsSinceEpoch);
}