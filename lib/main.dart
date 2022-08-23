
import 'package:desktop_window/desktop_window.dart';
import 'package:eq_raid_boss/Providers/blocked_items_variables.dart';
import 'package:eq_raid_boss/Providers/item_loots_variables.dart';
import 'package:eq_raid_boss/Providers/refresh_ticks_variable.dart';
import 'package:eq_raid_boss/Widgets/blocked_items_widget.dart';
import 'package:eq_raid_boss/Widgets/dkp_ticks_widget.dart';
import 'package:eq_raid_boss/Widgets/item_loots_widget.dart';
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
  late String startTime;
  String endTime = 'Now';

  @override
  void initState() {
    start = DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch - 28800000);
    end = DateTime.now();
    startTime = DateFormat('EEE, MMM d y, h:mm a').format(start);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          future: SharedPreferences.getInstance(),
          builder: (context, snap) {
            if (snap.hasData) {
              SharedPreferences prefs = snap.data as SharedPreferences;
              prefs.get('eqDirectory') ?? prefs.setString('eqDirectory', '');
              prefs.get('characterLogFile') ?? prefs.setString('characterLogFile', '');
              prefs.getStringList('blockedItems') ?? prefs.setStringList('blockedItems', <String>[]);
              ref.read(blockedItemsVariableProvider).blockedItems = prefs.getStringList('blockedItems')!;
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
                      length: 3,
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
                          ]),
                        ),
                      )),
                  _eqFolder(prefs),
                  _characterLogFile(prefs),
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
        Text(startTime, style: Theme.of(context).textTheme.headline6,),
        ElevatedButton(
            onPressed: () {
              _selectDate(context: context, isEnd: false)
                  .then((value) => _selectTime(context: context, isEnd: false));
            },
            child: const Text('Start')),
      ],
    );
  }

  Widget _endWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(endTime, style: Theme.of(context).textTheme.headline6,),
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
                    ref.read(itemLootsVariableProvider).byteOffset = 0;
                    ref.read(itemLootsVariableProvider).itemLoots = [];
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
              String? result = await FilePicker.platform.getDirectoryPath();
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
              FilePickerResult? result = await FilePicker.platform.pickFiles(allowedExtensions: ['.txt']);
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
        ref.read(refreshTicksVariableProvider).refresh = true;
        ref.read(refreshTicksVariableProvider).endIsNow = false;
        setState(() {
          end = picked;
          endTime = DateFormat('EEE, MMM d y, h:mm a').format(end);
        });
      } else {
        ref.read(refreshTicksVariableProvider).refresh = true;
        setState(() {
          start = picked;
          startTime = DateFormat('EEE, MMM d y, h:mm a').format(start);
        });
      }
      ref.read(itemLootsVariableProvider).byteOffset = 0;
      ref.read(itemLootsVariableProvider).itemLoots = [];
    }
  }

  Future<void> _selectTime({required BuildContext context, required bool isEnd}) async {
    final TimeOfDay? picked = await showTimePicker(
      builder: (context, childWidget) {
        return MediaQuery(
            data: MediaQuery.of(context).copyWith(
                alwaysUse24HourFormat: false),
            // If you want 12-Hour format, just change alwaysUse24HourFormat to false or remove all the builder argument
            child: childWidget!);
      },
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (picked != null) {
      if (isEnd) {
        ref.read(refreshTicksVariableProvider).refresh = true;
        ref.read(refreshTicksVariableProvider).endIsNow = false;
        setState(() {
          int milliSeconds = (1000 * 60 * 60 * picked.hour) + (1000 * 60 * picked.minute);
          end = DateTime.fromMillisecondsSinceEpoch(end.millisecondsSinceEpoch + milliSeconds);
          endTime = DateFormat('EEE, MMM d y, h:mm a').format(end);
        });
      } else {
        ref.read(refreshTicksVariableProvider).refresh = true;
        setState(() {
          int milliSeconds = (1000 * 60 * 60 * picked.hour) + (1000 * 60 * picked.minute);
          start = DateTime.fromMillisecondsSinceEpoch(start.millisecondsSinceEpoch + milliSeconds);
          startTime = DateFormat('EEE, MMM d y, h:mm a').format(start);
        });
      }
      ref.read(itemLootsVariableProvider).byteOffset = 0;
      ref.read(itemLootsVariableProvider).itemLoots = [];
    }
  }
}