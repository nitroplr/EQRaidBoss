import 'package:eq_raid_boss/Model/member_tick_info.dart';
import 'package:eq_raid_boss/Providers/ticks_sortable_table_variables.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TicksSortableTable extends ConsumerStatefulWidget {
  final List<MemberTickInfo> memberTickInfo;
  final SharedPreferences prefs;

  const TicksSortableTable({Key? key, required this.memberTickInfo, required this.prefs}) : super(key: key);

  @override
  TicksSortableTableState createState() => TicksSortableTableState();
}

class TicksSortableTableState extends ConsumerState<TicksSortableTable> {
  @override
  Widget build(BuildContext context) {
    List<String> columns = ['Player'];
    if (widget.memberTickInfo.isNotEmpty) {
      for (int i = 0; i < widget.memberTickInfo[0].ticks.length; i++) {
        columns.add('${i + 1}');
      }
    }
    bool isAscending = ref.watch(ticksSortableTableVariableProvider).isAscending;
    int sortColumnIndex = ref.watch(ticksSortableTableVariableProvider).sortColumnIndex;
    onSort(sortColumnIndex, isAscending);
    return Scaffold(
      body: SingleChildScrollView(
        controller: ScrollController(),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: PaginatedDataTable(
              rowsPerPage: 25,
              columnSpacing: 10,
              sortAscending: isAscending,
              sortColumnIndex: sortColumnIndex,
              columns: getColumns(columns), source: MyData(memberTickInfo: widget.memberTickInfo),
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

  List<DataRow> getRows() => widget.memberTickInfo.map((MemberTickInfo memberTickInfo) {
        List<DataCell> cells = [DataCell(Text(memberTickInfo.member))];
        memberTickInfo.ticks.forEach((tick) {
          cells.add(DataCell(Text(tick)));
        });
        return DataRow(cells: cells);
      }).toList();

  void onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      widget.memberTickInfo.sort((a, b) {
        if (ascending) {
          return a.member.compareTo(b.member);
        } else {
          return b.member.compareTo(a.member);
        }
      });
    }
    //sort by tick value and member name
    else {
      widget.memberTickInfo.sort((a, b) {
        if (ascending) {
          if (a.ticks[columnIndex - 1] == b.ticks[columnIndex - 1]) {
            return a.member.compareTo(b.member);
          }
          return a.ticks[columnIndex - 1].compareTo(b.ticks[columnIndex - 1]);
        } else {
          if (a.ticks[columnIndex - 1] == b.ticks[columnIndex - 1]) {
            return a.member.compareTo(b.member);
          }
          return b.ticks[columnIndex - 1].compareTo(a.ticks[columnIndex - 1]);
        }
      });
    }
    ref.read(ticksSortableTableVariableProvider).sortColumnIndex = columnIndex;
    ref.read(ticksSortableTableVariableProvider).isAscending = ascending;
  }
}

class MyData extends DataTableSource{
  List<MemberTickInfo> memberTickInfo;
  MyData({required this.memberTickInfo});

  @override
  DataRow? getRow(int index) {
    List<DataCell> cells = [DataCell(Text(memberTickInfo[index].member))];
    memberTickInfo[index].ticks.forEach((tick) {
      cells.add(DataCell(Text(tick)));
    });
    return DataRow(cells: cells);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => memberTickInfo.length;

  @override
  int get selectedRowCount => 0;

}