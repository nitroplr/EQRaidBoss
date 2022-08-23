import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:eq_raid_boss/Model/item_loot.dart';
import 'package:eq_raid_boss/Providers/blocked_items_variables.dart';
import 'package:eq_raid_boss/Providers/item_loots_variables.dart';
import 'package:eq_raid_boss/Providers/refresh_ticks_variable.dart';
import 'package:eq_raid_boss/Widgets/sortable_table.dart';
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
  Timer? timer;
  DateTime? endTime;

  @override
  void initState() {
    endTime = widget.end;
    String charFilePath = widget.prefs.getString('characterLogFile')!;
    logFile = File(charFilePath);
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      charFilePath = widget.prefs.getString('characterLogFile')!;
      if (charFilePath != '') {
        _buildItemLootsVariables(context);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    timer!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    endTime = ref.read(refreshTicksVariableProvider).endIsNow ? DateTime.now() : widget.end;
    String charFilePath = widget.prefs.getString('characterLogFile')!;
    logFile = File(charFilePath);
    final lootsAsyncValue = ref.watch(itemLootsVariableProvider);
    List<ItemLoot> lootedItems = charFilePath == '' ? [] : _buildItemLoots(lootsAsyncValue: lootsAsyncValue);
    return charFilePath == ''
        ? SizedBox()
        : SortableTable(
            itemLoots: lootedItems,
            prefs: widget.prefs,
          );
  }

  Future<void> _buildItemLootsVariables(BuildContext context) async {
    endTime = ref.read(refreshTicksVariableProvider).endIsNow ? DateTime.now() : widget.end;
    logFile = File(widget.prefs.getString('characterLogFile')!);
    int fileLength = logFile!.lengthSync();
    if (fileLength != ref.read(itemLootsVariableProvider).byteOffset) {
      int byteOffset = ref.read(itemLootsVariableProvider).byteOffset;
      ref.read(itemLootsVariableProvider).byteOffset = fileLength;

      if (byteOffset != 0) {
        await _getNewLoots(byteOffset);
      } else {
        await _getLootsFromEoFtoStartTime(fileLength);
      }
    }
  }

  Future<void> _getLootsFromEoFtoStartTime(int fileLength) async {
    //reading 1mb at a time
    int startOffset = fileLength - 1000000;
    if (startOffset < 0) {
      startOffset = 0;
    }
    int endOffset = fileLength + 1;
    List<String> itemLoots = [];
    await Future.doWhile(() async {
      List<String> newItemLoots = [];
      Stream<String> lines = logFile!
          .openRead(startOffset, endOffset)
          .transform(utf8.decoder) // Decode bytes to UTF-8.
          .transform(const LineSplitter()); // Convert stream to individual lines.
      bool firstLine = true;
      int firstLineOffset = 0;
      try {
        await for (var line in lines) {
          //increment next end offset by 8 * first line character to account for partial lines
          //adding an extra 15 to be safe, but should be guaranteed to not pickup enough of the next line
          // to get parsed
          if (firstLine) {
            firstLineOffset = line.length + 15;
            firstLine = false;
          }
          if (line.contains(RegExp(r'^\[.*\].*$')) && !firstLine) {
            DateTime lineTime = _getLineTime(line: line);
            //end while loop if time is before start time
            if (lineTime.millisecondsSinceEpoch < widget.start.millisecondsSinceEpoch) {
              startOffset = -1;
            }
            if ((line.contains(RegExp(r'--You have looted .*--')) ||
                    line.contains(RegExp(r'--.* has looted .*--'))) &&
                (lineTime.millisecondsSinceEpoch > widget.start.millisecondsSinceEpoch) &&
                (lineTime.millisecondsSinceEpoch < endTime!.millisecondsSinceEpoch)) {
              //handle multiple items dropping
              String lootMessage = line.substring(line.indexOf('--'));
              int indexOfNumber = lootMessage.indexOf(RegExp(r'\d+ '));
              if (indexOfNumber != -1) {
                String numberForward = lootMessage.substring(indexOfNumber);
                line.replaceFirst(RegExp(r' \d+ '), ' a ');
                for (int i = 0; i < int.parse(numberForward.substring(0, numberForward.indexOf(' '))); i++) {
                  newItemLoots.add(line);
                }
              } else {
                newItemLoots.add(line);
              }
            }
          }
        }
        log('File is now closed. $startOffset - $endOffset');
      } catch (e, stackTrace) {
        log('Error: $e \n $stackTrace');
      }
      //ensure last possible read starts from 0
      if (startOffset <= 0) {
        startOffset = -1;
      } else {
        endOffset = startOffset + firstLineOffset;
        startOffset = startOffset - 1000000;
        if (startOffset < 0) {
          startOffset = 0;
        }
      }
      newItemLoots.addAll(itemLoots);
      itemLoots = newItemLoots;
      if (startOffset >= 0) {
        return true;
      } else {
        return false;
      }
    });
    ref.read(itemLootsVariableProvider).itemLoots = itemLoots;
  }

  Future<void> _getNewLoots(int byteOffSet) async {
    List<String> itemLoots = ref.read(itemLootsVariableProvider).itemLoots;
    Stream<String> lines = logFile!
        .openRead(byteOffSet)
        .transform(utf8.decoder) // Decode bytes to UTF-8.
        .transform(const LineSplitter()); // Convert stream to individual lines.
    try {
      await for (var line in lines) {
        if (byteOffSet != 0) {
          log(line);
        }
        DateTime lineTime = _getLineTime(line: line);
        if ((line.contains(RegExp(r'--You have looted .*--')) ||
                line.contains(RegExp(r'--.* has looted .*--'))) &&
            (lineTime.millisecondsSinceEpoch > widget.start.millisecondsSinceEpoch) &&
            (lineTime.millisecondsSinceEpoch < endTime!.millisecondsSinceEpoch)) {
          //handle multiple items dropping
          String lootMessage = line.substring(line.indexOf('--'));
          int indexOfNumber = lootMessage.indexOf(RegExp(r'\d+ '));
          if (indexOfNumber != -1) {
            String numberForward = lootMessage.substring(indexOfNumber);
            line.replaceFirst(RegExp(r' \d+ '), ' a ');
            for (int i = 0; i < int.parse(numberForward.substring(0, numberForward.indexOf(' '))); i++) {
              itemLoots.add(line);
            }
          } else {
            itemLoots.add(line);
          }
        }
      }
      log('File is now closed. ${logFile!.lengthSync()}');
      ref.read(itemLootsVariableProvider).itemLoots = itemLoots;
    } catch (e) {
      log('Error: $e');
    }
  }

  DateTime _getLineTime({required String line}) {
    Map<String, String> months = {
      'Jan': '01',
      'Feb': '02',
      'Mar': '03',
      'Apr': '04',
      'May': '05',
      'Jun': '06',
      'Jul': '07',
      'Aug': '08',
      'Sep': '09',
      'Oct': '10',
      'Nov': '11',
      'Dec': '12',
    };
    String lineTime = line.substring(1, line.indexOf(']'));
    String time =
        lineTime.substring(lineTime.indexOf(RegExp(r'\d\d:')), lineTime.indexOf(RegExp(r' \d\d\d\d')));
    String year = lineTime.substring(lineTime.indexOf(RegExp(r'\d\d\d\d')));
    String month = months[lineTime.substring(4, 7)]!;
    String day = lineTime.substring(8, 10);

    return DateTime.parse('$year-$month-$day $time');
  }

  List<ItemLoot> _buildItemLoots({required ItemLootsVariableNotifier lootsAsyncValue}) {
    List<ItemLoot> itemLoots = [];
    for (var line in lootsAsyncValue.itemLoots) {
      //time
      DateTime time = _getLineTime(line: line);
      String charLogFile = widget.prefs.getString('characterLogFile')!;
      int underscoreIndex = charLogFile.indexOf('_');
      String thisPlayerName =
          charLogFile.substring(underscoreIndex + 1, charLogFile.indexOf('_', underscoreIndex + 1));
      String lootMessage = line.substring(line.indexOf('--'));
      //looter
      String looter = lootMessage.substring(2, lootMessage.indexOf(' '));
      if (looter == 'You') {
        looter = thisPlayerName;
      }

      //quantity
      String quantity = lootMessage.substring(lootMessage.indexOf('looted '));
      quantity = quantity.substring(8);
      quantity = quantity.substring(0, quantity.indexOf(' '));
      quantity = int.tryParse(quantity) == null ? '1' : int.parse(quantity).toString();

      //item
      String item = lootMessage.substring(lootMessage.indexOf('looted '));
      item = item.substring(8);
      item = item.substring(item.indexOf(' ') + 1, item.indexOf('from') - 1).toLowerCase();
      bool blocked = false;
      if (ref.watch(blockedItemsVariableProvider).blockedItems.contains(item)) {
        blocked = true;
      }
      //item dropper
      String droppedBy = lootMessage.substring(lootMessage.indexOf('looted '));
      droppedBy = droppedBy.substring(droppedBy.indexOf('from '));
      droppedBy = droppedBy.substring(5, droppedBy.indexOf('.'));

      if (!blocked) {
        itemLoots
            .add(ItemLoot(time: time, looter: looter, quantity: quantity, item: item, droppedBy: droppedBy));
      }
    }
    return itemLoots;
  }
}