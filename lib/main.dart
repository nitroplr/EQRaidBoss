import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:eq_raid_boss/Model/item_loot.dart';
import 'package:eq_raid_boss/Model/plat_parcel.dart';
import 'package:eq_raid_boss/Model/sent_plat_parcel.dart';
import 'package:eq_raid_boss/Providers/blocked_items_variables.dart';
import 'package:eq_raid_boss/Providers/char_log_file_variables.dart';
import 'package:eq_raid_boss/Providers/refresh_ticks_variable.dart';
import 'package:eq_raid_boss/Providers/shared_preferences_provider.dart';
import 'package:eq_raid_boss/Widgets/blocked_items_widget.dart';
import 'package:eq_raid_boss/Widgets/dkp_ticks_widget.dart';
import 'package:eq_raid_boss/Widgets/item_loots_widget.dart';
import 'package:eq_raid_boss/Widgets/parcel_sender/parcel_sender.dart';
import 'package:eq_raid_boss/Widgets/plat_parcels.dart';
import 'package:eq_raid_boss/globals.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.setSize(const Size(1300, 1000));
  await windowManager.setMinimumSize(const Size(500, 500));
  final sharedPreferences = await SharedPreferences.getInstance();
  runApp(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWith((ref) => sharedPreferences)], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'EQ Raid Boss'),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  ConsumerState createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  late DateTime start;
  late DateTime end;
  late SharedPreferences prefs;
  Timer? timer;
  late String startTime;
  String endTime = 'Now';
  File? logFile;
  late String thisPlayerName;
  final Uuid uuid = const Uuid();

  @override
  void initState() {
    prefs = ref.read(sharedPreferencesProvider);
    String charLogFile = prefs.getString('characterLogFile') ?? "";
    start = DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch - 28800000);
    end = DateTime.now();
    startTime = DateFormat('EEE, MMM d y, h:mm a').format(start);
    if(charLogFile != ""){
      int underscoreIndex = charLogFile.indexOf('_');
      thisPlayerName = charLogFile.substring(underscoreIndex + 1, charLogFile.indexOf('_', underscoreIndex + 1));
    }else{
      prefs.setString('characterLogFile', "");
    }
    timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      String charFilePath = prefs.getString('characterLogFile')!;
      logFile = File(charFilePath);
      charFilePath = prefs.getString('characterLogFile')!;
      if (charFilePath != '') {
        _buildItemLootsVariables(context);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    prefs.get('eqDirectory') ?? prefs.setString('eqDirectory', '');
    prefs.get('characterLogFile') ?? prefs.setString('characterLogFile', '');
    prefs.getStringList('blockedItems') ?? prefs.setStringList('blockedItems', <String>[]);
    ref.read(blockedItemsVariableProvider).blockedItems = prefs.getStringList('blockedItems')!;
    ref.read(blockedItemsVariableProvider).blockedItems.sort();
    return Scaffold(
        body: Column(
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
            length: 5,
            initialIndex: 0,
            child: Expanded(
              child: Scaffold(
                appBar: const TabBar(
                  labelColor: Colors.black,
                  tabs: [
                    Tab(icon: Text('Loots')),
                    Tab(icon: Text('Blocked Loots')),
                    Tab(icon: Text('DKP Ticks')),
                    Tab(icon: Text('Plat Parcels Received')),
                    Tab(icon: Text('Plat Parcel Sender'))
                  ],
                ),
                body: TabBarView(children: [
                  ItemLoots(
                    prefs: prefs,
                    start: start,
                    end: end,
                  ),
                  BlockedItems(prefs: prefs),
                  DKPTicks(
                    prefs: prefs,
                    start: start,
                    end: end,
                  ),
                  PlatParcelsReceived(prefs: prefs),
                  ParcelSender(prefs: prefs),
                ]),
              ),
            )),
        _logFiles(prefs),
      ],
    ));
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

  Row _logFiles(SharedPreferences prefs) {
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
                String path = result.files[0].path!;
                path = path.substring(0, path.lastIndexOf('Logs'));
                prefs.setString('eqDirectory', path);
              }
              setState(() {});
            },
            icon: const Icon(Icons.folder)),
        Expanded(child: Text('Character Log File: ${prefs.get('characterLogFile')}', overflow: TextOverflow.ellipsis)),
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
    logFile = File(prefs.getString('characterLogFile')!);
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
      //reading 10mb at a time
      int startOffset = fileLength - 10000000;
      if (startOffset < 0) {
        startOffset = 0;
      }
      int endOffset = fileLength + 1;
      List<PlatParcel> parcels = [];
      List<SentPlatParcel> sentParcels = [];
      await Future.doWhile(() async {
        int openTime = DateTime.now().millisecondsSinceEpoch;
        Stream<String> lines = logFile!
            .openRead(startOffset, endOffset)
            .transform(utf8.decoder) // Decode bytes to UTF-8.
            .transform(const LineSplitter()); // Convert stream to individual lines.
        bool firstLine = true;
        int firstLineOffset = 0;
        try {
          List<String> newItemLines = [];
          List<ItemLoot> newGivenLoots = [];
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
              //check if item has been given
              if ((line.contains(RegExp(r'.* won the .* roll on .* with a roll of \d*.')) ||
                      line.contains(' was given to ') ||
                      line.contains(RegExp(r'] \d+ .* were given to'))) &&
                  (lineTime.millisecondsSinceEpoch > start.millisecondsSinceEpoch) &&
                  (lineTime.millisecondsSinceEpoch < end.millisecondsSinceEpoch)) {
                newGivenLoots.addAll(_handleLootGiven(line, lineTime));
              }
              //itemloot lines
              if ((line.contains("--You have looted ") ||
                      line.contains(RegExp(r'--.* has looted .*--'))) &&
                  (lineTime.millisecondsSinceEpoch > start.millisecondsSinceEpoch) &&
                  (lineTime.millisecondsSinceEpoch < end.millisecondsSinceEpoch)) {
                newItemLines.add(line);
              }
              //parcel lines
              if (line.contains(' hands you the Money ') && (line.contains(' that was sent from ')) &&
                  (lineTime.millisecondsSinceEpoch > start.millisecondsSinceEpoch) &&
                  (lineTime.millisecondsSinceEpoch < end.millisecondsSinceEpoch)) {
                int amount = 0;
                String sender = line.substring(line.indexOf('that was sent from ') + 19, line.length - 1);
                RegExp regex = RegExp(r'(\d+)');
                var matches = regex.allMatches(line).toList();
                amount = int.parse(line.substring(matches[matches.length - 1].start, matches[matches.length - 1].end));
                parcels.add(PlatParcel(sender: sender, amount: amount, time: lineTime));
              }
              //parcels sent
              if (line.contains(' told you, \'I will deliver the Money ') && line.contains(" as soon as possible!\'") &&
                  (lineTime.millisecondsSinceEpoch > start.millisecondsSinceEpoch) &&
                  (lineTime.millisecondsSinceEpoch < end.millisecondsSinceEpoch)) {
                int amount = 0;
                String receiver = line.substring(line.indexOf(') to ') + 5, line.indexOf(' as soon as possible!'));
                RegExp regex = RegExp(r'(\d+)');
                var matches = regex.allMatches(line).toList();
                amount = int.parse(line.substring(matches[matches.length - 1].start, matches[matches.length - 1].end));
                sentParcels
                    .add(SentPlatParcel(receiver: receiver, amount: amount, time: lineTime, id: const Uuid().v4()));
              }
            }
          }
          _buildItemLoots(itemLines: newItemLines);
          ref.read(charLogFileVariableProvider).itemLoots.addAll(newGivenLoots);
          log('File is now closed. $startOffset - $endOffset\nTime open: ${(DateTime.now().millisecondsSinceEpoch - openTime) / 1000} secs');
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
      ref
          .read(charLogFileVariableProvider)
          .updateOffsetAndParcels(offset: fileLength, parcels: parcels, sentParcels: sentParcels);
      ref.read(charLogFileVariableProvider).isProcessing = false;
    }
  }

  Future<void> _getNewLoots(int fileLength) async {
    if (ref.read(charLogFileVariableProvider).isProcessing == false) {
      ref.read(charLogFileVariableProvider).isProcessing = true;
      int byteOffSet = ref.read(charLogFileVariableProvider).byteOffset;
      List<String> newLines = [];
      List<PlatParcel> parcels = ref.read(charLogFileVariableProvider).platParcels;
      List<SentPlatParcel> sentParcels = ref.read(charLogFileVariableProvider).sentPlatParcels;
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

          //check if item has been given
          if ((line.contains(RegExp(r'.* won the .* roll on .* with a roll of \d*.')) ||
                  line.contains(RegExp(r'.* was given to .*.')) ||
                  line.contains(RegExp(r'] \d+ .* were given to'))) &&
              (lineTime.millisecondsSinceEpoch > start.millisecondsSinceEpoch) &&
              (lineTime.millisecondsSinceEpoch < end.millisecondsSinceEpoch)) {
            _handleLootGiven(line, lineTime);
          }
          if ((line.contains(RegExp(r'--You have looted .*--')) || line.contains(RegExp(r'--.* has looted .*--'))) &&
              (lineTime.millisecondsSinceEpoch > start.millisecondsSinceEpoch) &&
              (lineTime.millisecondsSinceEpoch < end.millisecondsSinceEpoch)) {
            //handle multiple items dropping
            newLines.add(line);
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
          if (line.contains(
                  RegExp(r"^\[.*\].* told you, 'I will deliver the Money \(\d+p\) to .* as soon as possible!'$")) &&
              (lineTime.millisecondsSinceEpoch > start.millisecondsSinceEpoch) &&
              (lineTime.millisecondsSinceEpoch < end.millisecondsSinceEpoch)) {
            int amount = 0;
            String receiver = line.substring(line.indexOf(') to ') + 5, line.indexOf(' as soon as possible!'));
            RegExp regex = RegExp(r'(\d+)');
            var matches = regex.allMatches(line).toList();
            amount = int.parse(line.substring(matches[matches.length - 1].start, matches[matches.length - 1].end));
            SentPlatParcel sentPlatParcel =
                SentPlatParcel(id: const Uuid().v4(), receiver: receiver, amount: amount, time: lineTime);
            sentParcels.add(sentPlatParcel);
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

  List<ItemLoot> _handleLootGiven(String line, DateTime lineTime) {
    String itemGiven = '';
    String looter = '';
    String quantity = '0';
    if (line.contains(RegExp(r'.* won the .* roll on .* with a roll of \d*.'))) {
      itemGiven = line.substring(line.indexOf('item(s): ') + 9, line.indexOf(' with a roll')).toLowerCase();
      looter = line.substring(line.indexOf('] ') + 2, line.indexOf(' won the '));
      if (looter == 'you') {
        looter = thisPlayerName;
      }
      quantity = line.substring(line.indexOf('roll on ') + 8, line.indexOf(' item(s): '));
    }
    if (line.contains(RegExp(r'.* was given to .*.'))) {
      int firstIndex = line.indexOf('] A ');
      if (firstIndex == -1) {
        firstIndex = line.indexOf('] An ') + 5;
      } else {
        firstIndex += 4;
      }
      itemGiven = line.substring(firstIndex, line.indexOf(' was given to ')).toLowerCase();
      looter = line.substring(line.indexOf(' was given to ') + 14, line.lastIndexOf('.'));
      if (looter == 'you') {
        looter = thisPlayerName;
      }
    }
    if (line.contains(RegExp(r'] \d+ .* were given to'))) {
      int indexOfNumber = line.indexOf('] ') + 2;
      int indexAfterNumber = line.indexOf(' ', indexOfNumber);
      quantity = line.substring(indexOfNumber, indexAfterNumber);
      itemGiven = line.substring(indexAfterNumber + 1, line.indexOf(' were given to')).toLowerCase();
      int indexLooter = line.indexOf('were given to ') + 14;
      looter = line.substring(indexLooter, line.indexOf('.', indexLooter));
      if (looter == 'you') {
        looter = thisPlayerName;
      }
    }
    int q = int.parse(quantity);
    List<ItemLoot> itemsGiven = [];
    for (int i = 0; i < q; i++) {
      ItemLoot itemLoot = ItemLoot(
          time: lineTime,
          looter: looter,
          quantity: 1,
          itemLooted: null,
          droppedBy: null,
          id: uuid.v4(),
          itemGiven: itemGiven);
      ref.read(charLogFileVariableProvider).allItemLootsInRange.add(itemLoot);
      if (!ref.read(blockedItemsVariableProvider).blockedItems.contains(itemGiven)) {
        itemsGiven.add(itemLoot);
      }
    }
    return itemsGiven;
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
    List<ItemLoot> allItemLootsInRangeProvider = ref.read(charLogFileVariableProvider).allItemLootsInRange;
    List<ItemLoot> itemLootsToAdd = [];
    for (var line in itemLines) {
      //time
      DateTime time = _getLineTime(line: line);
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

      //item dropper
      String droppedBy = lootMessage.substring(lootMessage.indexOf('looted '));
      droppedBy = droppedBy.substring(droppedBy.indexOf('from '));
      droppedBy = droppedBy.substring(5, droppedBy.indexOf('.'));
      int q = int.parse(quantity);
      for (int i = 0; i < q; i++) {
        ItemLoot itemLoot = ItemLoot(
            time: time,
            looter: looter,
            quantity: 1,
            itemLooted: item,
            droppedBy: droppedBy,
            id: const Uuid().v4(),
            itemGiven: item);
        bool foundMatch = false;
        for (var itemLootFor in allItemLootsInRangeProvider) {
          if ((itemLootFor.looter == itemLoot.looter) &&
              (itemLootFor.itemGiven == itemLoot.itemGiven) &&
              (itemLootFor.itemLooted == null)) {
            foundMatch = true;
            itemLootFor.quantity = int.parse(quantity);
            itemLootFor.itemLooted = itemLoot.itemLooted;
            itemLootFor.droppedBy = droppedBy;
            itemLoot.id = itemLootFor.id;
          }
        }
        if (!foundMatch &&
            (time.millisecondsSinceEpoch > start.millisecondsSinceEpoch) &&
            (time.millisecondsSinceEpoch < end.millisecondsSinceEpoch)) {
          ref.read(charLogFileVariableProvider).allItemLootsInRange.add(itemLoot);
          if (!ref.read(blockedItemsVariableProvider).blockedItems.contains(itemLoot.itemLooted)) {
            itemLootsToAdd.add(itemLoot);
          }
        }
      }
    }
    //trigger ui update
    ref.read(charLogFileVariableProvider).itemLoots.addAll(itemLootsToAdd);
  }
}
