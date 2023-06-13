import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:desktop_window/desktop_window.dart';
import 'package:eq_raid_boss/Model/item_loot.dart';
import 'package:eq_raid_boss/Model/plat_parcel.dart';
import 'package:eq_raid_boss/Providers/blocked_items_variables.dart';
import 'package:eq_raid_boss/Providers/char_log_file_variables.dart';
import 'package:eq_raid_boss/Providers/refresh_ticks_variable.dart';
import 'package:eq_raid_boss/Widgets/blocked_items_widget.dart';
import 'package:eq_raid_boss/Widgets/dkp_ticks_widget.dart';
import 'package:eq_raid_boss/Widgets/item_loots_widget.dart';
import 'package:eq_raid_boss/Widgets/plat_parcels.dart';
import 'package:eq_raid_boss/globals.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    _setWindowSize(context);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'EQ Raid Boss'),
    );
  }

//C:\Users\nitro\Desktop\EQ Raid Boss\eq_raid_boss\windows\runner\main.cpp
  //set window size there, window title also gets set there
  Future<void> _setWindowSize(BuildContext context) async {
    DesktopWindow.setMinWindowSize(const Size(400, 400));
    //DesktopWindow.setWindowSize(const Size(1000, 600));
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  ConsumerState createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  late DateTime start;
  late DateTime end;
  SharedPreferences? prefs;
  Timer? timer;
  late String startTime;
  String endTime = 'Now';
  File? logFile;

  @override
  void initState() {
    start = DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch - 28800000);
    end = DateTime.now();
    startTime = DateFormat('EEE, MMM d y, h:mm a').format(start);
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (prefs != null) {
        String charFilePath = prefs!.getString('characterLogFile')!;
        logFile = File(charFilePath);
        charFilePath = prefs!.getString('characterLogFile')!;
        if (charFilePath != '') {
          _buildItemLootsVariables(context);
        }
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          future: SharedPreferences.getInstance(),
          builder: (context, snap) {
            if (snap.hasData) {
              prefs = snap.data as SharedPreferences;
              prefs!.get('eqDirectory') ?? prefs!.setString('eqDirectory', '');
              prefs!.get('characterLogFile') ?? prefs!.setString('characterLogFile', '');
              prefs!.getStringList('blockedItems') ?? prefs!.setStringList('blockedItems', <String>[]);
              ref.read(blockedItemsVariableProvider).blockedItems = prefs!.getStringList('blockedItems')!;
              ref.read(blockedItemsVariableProvider).blockedItems.sort();
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _startWidget(context),
                      _endWidget(context),
                    ],
                  ),
                  DefaultTabController(
                      length: 4,
                      child: Expanded(
                        child: Scaffold(
                          appBar: const TabBar(
                            labelColor: Colors.black,
                            tabs: [
                              Tab(
                                icon: Text('Loots'),
                              ),
                              Tab(
                                icon: Text('Blocked'),
                              ),
                              Tab(
                                icon: Text('Ticks'),
                              ),
                              Tab(
                                icon: Text('Plat Parcels'),
                              ),
                            ],
                          ),
                          body: TabBarView(children: [
                            ItemLoots(
                              prefs: prefs!,
                              start: start,
                              end: end,
                            ),
                            BlockedItems(prefs: prefs!),
                            DKPTicks(
                              prefs: prefs!,
                              start: start,
                              end: end,
                            ),
                            PlatParcels(prefs: prefs!),
                          ]),
                        ),
                      )),
                  _eqFolder(prefs!),
                  _characterLogFile(prefs!),
                ],
              );
            } else if (snap.hasError) {
              return ErrorWidget(snap.error.toString());
            } else {
              return const LinearProgressIndicator();
            }
          }),
    );
  }

  Widget _startWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          startTime,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        ElevatedButton(
            onPressed: () {
              _selectDate(context: context, isEnd: false).then((value) => _selectTime(context: context, isEnd: false));
            },
            child: const Text('Start')),
      ],
    );
  }

  Widget _endWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          endTime,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ElevatedButton(
                  onPressed: () {
                    _selectDate(context: context, isEnd: true)
                        .then((value) => _selectTime(context: context, isEnd: true));
                  },
                  child: const Text('End')),
            ),
            ElevatedButton(
                onPressed: () {
                  if (ref.read(refreshTicksVariableProvider).endIsNow == false) {
                    ref.read(refreshTicksVariableProvider).endIsNow = true;
                    ref.read(charLogFileVariableProvider).byteOffset = 0;
                    ref.read(charLogFileVariableProvider).itemLoots = [];
                    setState(() {
                      endTime = 'Now';
                    });
                  }
                },
                child: const Text('Now')),
          ],
        ),
      ],
    );
  }

  Row _eqFolder(SharedPreferences prefs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
            onPressed: () async {
              String? result = await FilePicker.platform.getDirectoryPath().then((value) {
                refreshData(ref: ref);
                return value;
              });
              if (result != null) {
                prefs.setString('eqDirectory', result);
              }
              setState(() {});
            },
            icon: const Icon(Icons.folder)),
        Text('EQ Folder: ${prefs.get('eqDirectory')}'),
      ],
    );
  }

  Row _characterLogFile(SharedPreferences prefs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(allowedExtensions: ['.txt']).then((value) {
                refreshData(ref: ref);
                return value;
              });
              if (result != null) {
                prefs.setString('characterLogFile', result.files[0].path!);
              }
              setState(() {});
            },
            icon: const Icon(Icons.folder)),
        Text('Character Log File: ${prefs.get('characterLogFile')}'),
      ],
    );
  }

  Future<void> _selectDate({required BuildContext context, required bool isEnd}) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        initialDatePickerMode: DatePickerMode.day,
        firstDate: DateTime(1999),
        lastDate: DateTime(2101));
    if (picked != null) {
      if (isEnd) {
        ref.read(refreshTicksVariableProvider).endIsNow = false;
        setState(() {
          end = picked;
          endTime = DateFormat('EEE, MMM d y, h:mm a').format(end);
        });
      } else {
        setState(() {
          start = picked;
          startTime = DateFormat('EEE, MMM d y, h:mm a').format(start);
        });
      }
    }
  }

  Future<void> _selectTime({required BuildContext context, required bool isEnd}) async {
    final TimeOfDay? picked = await showTimePicker(
      builder: (context, childWidget) {
        return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            // If you want 12-Hour format, just change alwaysUse24HourFormat to false or remove all the builder argument
            child: childWidget!);
      },
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (picked != null) {
      if (isEnd) {
        ref.read(refreshTicksVariableProvider).endIsNow = false;
        setState(() {
          int milliSeconds = (1000 * 60 * 60 * picked.hour) + (1000 * 60 * picked.minute);
          end = DateTime.fromMillisecondsSinceEpoch(end.millisecondsSinceEpoch + milliSeconds);
          endTime = DateFormat('EEE, MMM d y, h:mm a').format(end);
        });
      } else {
        setState(() {
          int milliSeconds = (1000 * 60 * 60 * picked.hour) + (1000 * 60 * picked.minute);
          start = DateTime.fromMillisecondsSinceEpoch(start.millisecondsSinceEpoch + milliSeconds);
          startTime = DateFormat('EEE, MMM d y, h:mm a').format(start);
        });
      }
      refreshData(ref: ref);
    }
  }

  Future<void> _buildItemLootsVariables(BuildContext context) async {
    end = ref.read(refreshTicksVariableProvider).endIsNow ? DateTime.now() : end;
    logFile = File(prefs!.getString('characterLogFile')!);
    int fileLength = await logFile!.length();
    if (fileLength != ref.read(charLogFileVariableProvider).byteOffset) {
      int byteOffset = ref.read(charLogFileVariableProvider).byteOffset;

      if (byteOffset != 0) {
        await _getNewLoots(fileLength);
      } else {
        await _getLootsParcelsFromEoFtoStartTime(fileLength);
      }
    }
  }

  Future<void> _getLootsParcelsFromEoFtoStartTime(int fileLength) async {
    if (ref.read(charLogFileVariableProvider).isProcessing == false) {
      ref.read(charLogFileVariableProvider).isProcessing = true;
      //reading 1mb at a time
      int startOffset = fileLength - 1000000;
      if (startOffset < 0) {
        startOffset = 0;
      }
      int endOffset = fileLength + 1;
      List<PlatParcel> parcels = [];
      List<String> newItemLines = [];
      await Future.doWhile(() async {
        Stream<String> lines = logFile!
            .openRead(startOffset, endOffset)
            .transform(utf8.decoder) // Decode bytes to UTF-8.
            .transform(const LineSplitter()); // Convert stream to individual lines.
        bool firstLine = true;
        int firstLineOffset = 0;
        try {
          await for (var line in lines) {
            //increment next end offset by first line length to account for partial lines
            //adding an extra 15 to be safe, but should be guaranteed to not pickup enough of the next line
            // to get parsed
            if (firstLine) {
              firstLineOffset = line.length + 15;
              firstLine = false;
            }
            if (line.contains(RegExp(r'^\[.*\].*$')) && !firstLine) {
              DateTime lineTime = _getLineTime(line: line);
              //end while loop if time is before start time
              if (lineTime.millisecondsSinceEpoch < start.millisecondsSinceEpoch) {
                startOffset = -1;
              }
              //itemloot lines
              if ((line.contains(RegExp(r'--You have looted .*--')) ||
                      line.contains(RegExp(r'--.* has looted .*--'))) &&
                  (lineTime.millisecondsSinceEpoch > start.millisecondsSinceEpoch) &&
                  (lineTime.millisecondsSinceEpoch < end.millisecondsSinceEpoch)) {
                //handle multiple items dropping
                String lootMessage = line.substring(line.indexOf('--'));
                int indexOfNumber = lootMessage.indexOf(RegExp(r'\d+ '));
                if (indexOfNumber != -1) {
                  String numberForward = lootMessage.substring(indexOfNumber);
                  line.replaceFirst(RegExp(r' \d+ '), ' a ');
                  for (int i = 0; i < int.parse(numberForward.substring(0, numberForward.indexOf(' '))); i++) {
                    newItemLines.add(line);
                  }
                } else {
                  newItemLines.add(line);
                }
              }
              //parcel lines
              if (line.contains(RegExp(r'^\[.*\].* hands you the Money \(\d+p\) that was sent from .*$')) &&
                  (lineTime.millisecondsSinceEpoch > start.millisecondsSinceEpoch) &&
                  (lineTime.millisecondsSinceEpoch < end.millisecondsSinceEpoch)) {
                int amount = 0;
                String sender = line.substring(line.indexOf('that was sent from ') + 19, line.length - 1);
                RegExp regex = RegExp(r'(\d+)');
                var matches = regex.allMatches(line).toList();
                amount = int.parse(line.substring(matches[matches.length - 1].start, matches[matches.length - 1].end));
                parcels.add(PlatParcel(sender: sender, amount: amount, time: lineTime));
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
        if (startOffset >= 0) {
          return true;
        } else {
          return false;
        }
      });
      _buildItemLoots(itemLines: newItemLines);
      ref.read(charLogFileVariableProvider).updateOffsetAndParcels(fileLength, parcels);
      ref.read(charLogFileVariableProvider).isProcessing = false;
    }
  }

  Future<void> _getNewLoots(int fileLength) async {
    if (ref.read(charLogFileVariableProvider).isProcessing == false) {
      ref.read(charLogFileVariableProvider).isProcessing = true;
      int byteOffSet = ref.read(charLogFileVariableProvider).byteOffset;
      List<String> newLines = [];
      List<PlatParcel> parcels = ref.read(charLogFileVariableProvider).platParcels;
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
          if ((line.contains(RegExp(r'--You have looted .*--')) || line.contains(RegExp(r'--.* has looted .*--'))) &&
              (lineTime.millisecondsSinceEpoch > start.millisecondsSinceEpoch) &&
              (lineTime.millisecondsSinceEpoch < end.millisecondsSinceEpoch)) {
            //handle multiple items dropping
            String lootMessage = line.substring(line.indexOf('--'));
            int indexOfNumber = lootMessage.indexOf(RegExp(r'\d+ '));
            if (indexOfNumber != -1) {
              String numberForward = lootMessage.substring(indexOfNumber);
              line.replaceFirst(RegExp(r' \d+ '), ' a ');
              for (int i = 0; i < int.parse(numberForward.substring(0, numberForward.indexOf(' '))); i++) {
                newLines.add(line);
              }
            } else {
              newLines.add(line);
            }
          }
          //parcel lines
          if (line.contains(RegExp(r'^\[.*\].* hands you the Money \(\d+p\) that was sent from .*$')) &&
              (lineTime.millisecondsSinceEpoch > start.millisecondsSinceEpoch) &&
              (lineTime.millisecondsSinceEpoch < end.millisecondsSinceEpoch)) {
            int amount = 0;
            String sender = line.substring(line.indexOf('that was sent from ') + 19, line.length - 1);
            RegExp regex = RegExp(r'(\d+)');
            var matches = regex.allMatches(line).toList();
            amount = int.parse(line.substring(matches[matches.length - 1].start, matches[matches.length - 1].end));
            parcels.add(PlatParcel(sender: sender, amount: amount, time: lineTime));
          }
        }
        log('File is now closed. ${logFile!.lengthSync()}');
        ref.read(charLogFileVariableProvider).platParcels = parcels;
      } catch (e) {
        log('Error: $e');
      }
      _buildItemLoots(itemLines: newLines);
      ref.read(charLogFileVariableProvider).byteOffset = fileLength;
      ref.read(charLogFileVariableProvider).isProcessing = false;
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
    String time = lineTime.substring(lineTime.indexOf(RegExp(r'\d\d:')), lineTime.indexOf(RegExp(r' \d\d\d\d')));
    String year = lineTime.substring(lineTime.indexOf(RegExp(r'\d\d\d\d')));
    String month = months[lineTime.substring(4, 7)]!;
    String day = lineTime.substring(8, 10);

    return DateTime.parse('$year-$month-$day $time');
  }

  void _buildItemLoots({required List<String> itemLines}) {
    List<ItemLoot> filteredItemLoots = [];
    List<ItemLoot> allItemLoots = [];
    for (var line in itemLines) {
      //time
      DateTime time = _getLineTime(line: line);
      String charLogFile = prefs!.getString('characterLogFile')!;
      int underscoreIndex = charLogFile.indexOf('_');
      String thisPlayerName = charLogFile.substring(underscoreIndex + 1, charLogFile.indexOf('_', underscoreIndex + 1));
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

      ItemLoot itemLoot = ItemLoot(time: time, looter: looter, quantity: quantity, item: item, droppedBy: droppedBy);
      if (!blocked) {
        filteredItemLoots.add(itemLoot);
      }
      allItemLoots.add(itemLoot);
    }
    filteredItemLoots.addAll(ref.read(charLogFileVariableProvider).itemLoots);
    ref.read(charLogFileVariableProvider).itemLoots = filteredItemLoots;
    allItemLoots.addAll(ref.read(charLogFileVariableProvider).allItemLootsInRange);
    ref.read(charLogFileVariableProvider).allItemLootsInRange = allItemLoots;
  }
}
