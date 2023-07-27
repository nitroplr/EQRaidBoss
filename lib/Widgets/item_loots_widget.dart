import 'dart:io';
import 'package:eq_raid_boss/Providers/char_log_file_variables.dart';
import 'package:eq_raid_boss/Providers/refresh_ticks_variable.dart';
import 'package:eq_raid_boss/Widgets/Tables/loots_sortable_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        : LootsSortableTable(
          prefs: widget.prefs,
        );
  }

  int compareTime(bool ascending, int millisecondsSinceEpoch, int millisecondsSinceEpoch2) => ascending
      ? millisecondsSinceEpoch.compareTo(millisecondsSinceEpoch2)
      : millisecondsSinceEpoch2.compareTo(millisecondsSinceEpoch);
}