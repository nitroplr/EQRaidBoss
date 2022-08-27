import 'dart:io';
import 'package:eq_raid_boss/Model/item_loot.dart';
import 'package:eq_raid_boss/Providers/item_loots_variables.dart';
import 'package:eq_raid_boss/Providers/refresh_ticks_variable.dart';
import 'package:eq_raid_boss/Providers/loots_sortable_table_variables.dart';
import 'package:eq_raid_boss/Widgets/loots_sortable_table.dart';
import 'package:eq_raid_boss/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ItemLoots extends ConsumerStatefulWidget {
  final SharedPreferences prefs;
  final DateTime start;
  final DateTime end;

  const ItemLoots({
    Key? key,
    required this.prefs,
    required this.start,
    required this.end,
  }) : super(key: key);

  @override
  ConsumerState createState() => _ItemLootsState();
}

class _ItemLootsState extends ConsumerState<ItemLoots> {
  File? logFile;
  DateTime? endTime;

  @override
  void initState() {
    endTime = widget.end;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    endTime = ref.read(refreshTicksVariableProvider).endIsNow ? DateTime.now() : widget.end;
    String charFilePath = widget.prefs.getString('characterLogFile')!;
    logFile = File(charFilePath);
    final lootsAsyncValue = ref.watch(charLogFileVariableProvider);
    return charFilePath == ''
        ? const SizedBox()
        : InkWell(
            onTap: () {
              _outputLootSummary(lootedItems: lootsAsyncValue.itemLoots);
            },
            mouseCursor: SystemMouseCursors.basic,
            child: LootsSortableTable(
              itemLoots: lootsAsyncValue.itemLoots,
              prefs: widget.prefs,
            ),
          );
  }

  void _outputLootSummary({required List<ItemLoot> lootedItems}) {
    int columnIndex = ref.read(lootsSortableTableVariableProvider).sortColumnIndex;
    bool ascending = ref.read(lootsSortableTableVariableProvider).isAscending;

    _sortLoots(columnIndex, lootedItems, ascending);

    StringBuffer output = StringBuffer('Time;Looter;Item;Dropped By\n');
    for (var item in lootedItems) {
      output.writeln(
          '${DateFormat('EEE, MMM d, h:mm a').format(item.time)};${item.looter};${item.item};${item.droppedBy}');
    }

    _sortLoots(2, lootedItems, true);

    output.writeln('\n');
    for (var item in lootedItems) {
      output.writeln(item.item);
    }

    Clipboard.setData(ClipboardData(text: output.toString()));
    showSnackBar(context: context, message: 'Loot summary copied to clipboard.');
  }

  void _sortLoots(int columnIndex, List<ItemLoot> lootedItems, bool ascending) {
    if (columnIndex == 0) {
      lootedItems.sort(
          (a, b) => compareTime(ascending, a.time.millisecondsSinceEpoch, b.time.millisecondsSinceEpoch));
    }
    //sort based on looter, then item, then time
    else if (columnIndex == 1) {
      lootedItems.sort((a, b) {
        if (ascending) {
          if (a.looter == b.looter) {
            if (a.item == b.item) {
              return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
            }
            return a.item.compareTo(b.item);
          }
          return a.looter.compareTo(b.looter);
        } else {
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
      lootedItems.sort((a, b) {
        if (ascending) {
          if (a.item == b.item) {
            return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
          }
          return a.item.compareTo(b.item);
        } else {
          if (a.item == b.item) {
            return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
          }
          return b.item.compareTo(a.item);
        }
      });
    }
    //sort based on dropper, then time
    else if (columnIndex == 3) {
      lootedItems.sort((a, b) {
        if (ascending) {
          if (a.droppedBy == b.droppedBy) {
            if (a.time.millisecondsSinceEpoch == b.time.millisecondsSinceEpoch) {
              return a.item.compareTo(b.item);
            }
            return a.time.millisecondsSinceEpoch.compareTo(b.time.millisecondsSinceEpoch);
          }
          return a.droppedBy.compareTo(b.droppedBy);
        } else {
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
  }

  int compareTime(bool ascending, int millisecondsSinceEpoch, int millisecondsSinceEpoch2) => ascending
      ? millisecondsSinceEpoch.compareTo(millisecondsSinceEpoch2)
      : millisecondsSinceEpoch2.compareTo(millisecondsSinceEpoch);
}