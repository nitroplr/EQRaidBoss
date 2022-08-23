import 'dart:developer';
import 'dart:io';
import 'package:eq_raid_boss/Model/tick.dart';
import 'package:eq_raid_boss/Providers/refresh_ticks_variable.dart';
import 'package:eq_raid_boss/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DKPTicks extends ConsumerStatefulWidget {
  final SharedPreferences prefs;
  final DateTime start;
  final DateTime end;

  const DKPTicks({Key? key, required this.prefs, required this.start, required this.end}) : super(key: key);

  @override
  ConsumerState createState() => _DKPTicksState();
}

class _DKPTicksState extends ConsumerState<DKPTicks> {
  List<File> raidDumps = [];
  List<FileSystemEntity> files = [];
  Directory? directory;
  String streamPath = '';

  @override
  void initState() {
    directory = Directory(widget.prefs.getString('eqDirectory')!);
    _getLogFiles();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _getLogFiles();
    directory = Directory(widget.prefs.getString('eqDirectory')!);
    if (ref.read(refreshTicksVariableProvider).refresh == true) {
      ref.read(refreshTicksVariableProvider).refresh = false;
      _getLogFiles();
    }
    List<Tick> ticks = [];
    _getTicks(ticks);
    String attendance = _getAttendance(ticks);
    return StreamBuilder<FileSystemEvent>(
        stream: directory!.watch(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.path.contains('RaidRoster')) {
              if (streamPath != snapshot.data!.path) {
                _getLogFiles();
                _getTicks(ticks);
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  setState(() {
                    streamPath = snapshot.data!.path;
                  });
                });
              }
            }
            return _attendanceView(context, attendance);
          } else if (snapshot.hasError) {
            log(snapshot.error.toString());
            return const SizedBox();
          }
          return _attendanceView(context, attendance);
        });
  }

  Widget _attendanceView(BuildContext context, String attendance) {
    return ListView(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Center(
            child: InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: attendance));
                  showSnackBar(context: context, message: 'Attendance summary copied to clipboard.');
                },
                child: Text(attendance)),
          ),
        )
      ],
    );
  }

  void _getLogFiles() {
    DateTime endTime =
        ref.read(refreshTicksVariableProvider).endIsNow ? DateTime.now() : widget.end;
    files.clear();
    raidDumps.clear();
    files = directory!.listSync();
    files = files
        .where((element) =>
            (element.path.contains('RaidRoster')) &&
            (element.statSync().modified.millisecondsSinceEpoch < endTime.millisecondsSinceEpoch &&
                element.statSync().modified.millisecondsSinceEpoch > widget.start.millisecondsSinceEpoch))
        .toList();
    files.sort((a, b) =>
        a.statSync().modified.millisecondsSinceEpoch.compareTo(b.statSync().modified.millisecondsSinceEpoch));
    //get all raid dumps
    for (var fileEntity in files) {
      raidDumps.add(File(fileEntity.path));
      log(fileEntity.path);
    }
  }

  void _getTicks(List<Tick> ticks) {
    for (var file in raidDumps) {
      String contents = file.readAsStringSync();
      if (contents.length > 2) {
        contents.trim();
        contents = contents.replaceAll(contents.substring(1, 2), ' ');
        Set<String> membersInTick = _parseTick(contents);
        ticks.add(Tick(membersInTick: membersInTick));
      }
    }
  }

  Set<String> _parseTick(String tick) {
    Set<String> members = {};
    List<String> lines = tick.split('\n');

    for (var line in lines) {
      if (line.length > 3) {
        int indexOfFirstSpace = line.indexOf(' ');
        int indexOfSecondSpace = line.indexOf(' ', indexOfFirstSpace + 1);
        String member = line.substring(indexOfFirstSpace, indexOfSecondSpace);
        member.trim();
        members.add(member);
      }
    }

    return members;
  }

  String _getAttendance(List<Tick> ticks) {
    StringBuffer returnString = StringBuffer('');
    Set<String> allMembersInAllTicks = {};
    for (var tick in ticks) {
      for (var member in tick.membersInTick) {
        allMembersInAllTicks.add(member);
      }
    }
    List<String> allMembersSorted = allMembersInAllTicks.toList();
    allMembersSorted.sort();

    for (var member in allMembersSorted) {
      returnString.write('$member;');
      for (int i = 0; i < ticks.length; i++) {
        if (ticks[i].membersInTick.contains(member) && (i != ticks.length - 1)) {
          returnString.write('1;');
        } else if (!ticks[i].membersInTick.contains(member) && (i != ticks.length - 1)) {
          returnString.write('0;');
        } else if (ticks[i].membersInTick.contains(member)) {
          returnString.write('1\n');
        } else {
          returnString.write('0\n');
        }
      }
    }

    return returnString.toString();
  }
}