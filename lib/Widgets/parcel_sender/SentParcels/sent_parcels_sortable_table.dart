import 'package:eq_raid_boss/Model/sent_plat_parcel.dart';
import 'package:eq_raid_boss/Providers/char_log_file_variables.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SentParcelsSortableTable extends ConsumerStatefulWidget {
  const SentParcelsSortableTable({super.key});

  @override
  ConsumerState createState() => _DecaySortableTableState();
}

class _DecaySortableTableState extends ConsumerState<SentParcelsSortableTable> {
  List<SentPlatParcel> sentParcels = [];
  ScrollController? controller;
  int parcelLength = 0;

  @override
  void initState() {
    controller = ScrollController(keepScrollOffset: false);
    super.initState();
  }

  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    sentParcels = ref.watch(charLogFileVariableProvider).sentPlatParcels;
    bool isAscending = ref.watch(sentParcelsSortableTableProvider).isAscending;
    int sortColumnIndex = ref.watch(sentParcelsSortableTableProvider).sortColumnIndex;
    bool needsSort = ref.watch(sentParcelsSortableTableProvider).needsSort;
    if (needsSort || (parcelLength != sentParcels.length)) {
      parcelLength = sentParcels.length;
      onSort(sortColumnIndex, isAscending);
      ref.read(sentParcelsSortableTableProvider).needsSort = false;
    }
    int total = 0;
    sentParcels.forEach((element) {
      total += element.amount;
    });
    //'Receiver', 'Amount', 'Time'
    List<String> columns = ['Receiver', '$total', 'Time'];
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: controller,
              child: Row(
                children: [
                  Expanded(
                    child: PaginatedDataTable(
                      columnSpacing: 0,
                      showFirstLastButtons: true,
                      onPageChanged: (index) {
                        controller!.animateTo(0, duration: const Duration(seconds: 1), curve: Curves.linear);
                      },
                      columns: getColumns(columns),
                      source: MyData(sentParcels: sentParcels),
                      sortColumnIndex: sortColumnIndex,
                      sortAscending: isAscending,
                      rowsPerPage: sentParcels.isEmpty ? 50 : sentParcels.length,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DataColumn> getColumns(List<String> columns) {
    List<DataColumn> dataCols = [];
    for (int i = 0; i < columns.length; i++) {
      dataCols.add(DataColumn(
          label: Text(
            columns[i],
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          onSort: onSort));
    }
    return dataCols;
  }

  //'Receiver', 'Amount', 'Time'
  void onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      _sortByReceiver(ascending: ascending);
    } else if (columnIndex == 1) {
      _sortByAmount(ascending: ascending);
    } else if (columnIndex == 2) {
      _sortByTime(ascending: ascending);
    }
    ref.read(sentParcelsSortableTableProvider).setIsAscendingAndColumn(ascending, columnIndex);
  }

  void _sortByReceiver({required bool ascending}) {
    sentParcels.sort((a, b) {
      if (ascending) {
        if (a.receiver.toLowerCase() == b.receiver.toLowerCase()) {
          if (a.amount == b.amount) {
            return a.id.compareTo(b.id);
          }
          return b.amount.compareTo(a.amount);
        }
        return a.receiver.toLowerCase().compareTo(b.receiver.toLowerCase());
      } else {
        if (a.receiver.toLowerCase() == b.receiver.toLowerCase()) {
          if (a.amount == b.amount) {
            return a.id.compareTo(b.id);
          }
          return b.amount.compareTo(a.amount);
        }
        return b.receiver.toLowerCase().compareTo(a.receiver.toLowerCase());
      }
    });
  }

  void _sortByAmount({required bool ascending}) {
    sentParcels.sort((a, b) {
      if (ascending) {
        if (a.amount == b.amount) {
          if (a.receiver.toLowerCase() == b.receiver.toLowerCase()) {
            return a.id.compareTo(b.id);
          }
          return a.receiver.toLowerCase().compareTo(b.receiver.toLowerCase());
        }
        return a.amount.compareTo(b.amount);
      } else {
        if (a.amount == b.amount) {
          if (a.receiver.toLowerCase() == b.receiver.toLowerCase()) {
            return a.id.compareTo(b.id);
          }
          return a.receiver.toLowerCase().compareTo(b.receiver.toLowerCase());
        }
        return b.amount.compareTo(a.amount);
      }
    });
  }

  void _sortByTime({required bool ascending}) {
    sentParcels.sort((a, b) {
      if (ascending) {
        return a.time.compareTo(b.time);
      } else {
        return b.time.compareTo(a.time);
      }
    });
  }
}

final sentParcelsSortableTableProvider = ChangeNotifierProvider((ref) => SentParcelsSortableTableVariableNotifier());

class SentParcelsSortableTableVariableNotifier extends ChangeNotifier {
  bool _isAscending = true;
  int _sortColumnIndex = 0;
  bool needsSort = true;

  bool get isAscending => _isAscending;

  int get sortColumnIndex => _sortColumnIndex;

  setIsAscendingAndColumn(bool isAscending, int sortColumnIndex) {
    _isAscending = isAscending;
    _sortColumnIndex = sortColumnIndex;
    Future.delayed(Duration.zero).then((value) => notifyListeners());
  }

  sortTable(bool needsSort) {
    this.needsSort = needsSort;
    Future.delayed(Duration.zero).then((value) => notifyListeners());
  }
}

class MyData extends DataTableSource {
  final List<SentPlatParcel> sentParcels;

  MyData({required this.sentParcels});

  DateFormat dateFormat = DateFormat('h:mm:ss a');
  NumberFormat numberFormat = NumberFormat.decimalPattern();

  //'Receiver', 'Amount', 'Time'
  @override
  DataRow? getRow(int index) {
    SentPlatParcel sentPlatParcel = sentParcels[index];
    List<DataCell> cells = [
      DataCell(Text(sentPlatParcel.receiver)),
      DataCell(Text(numberFormat.format(sentPlatParcel.amount))),
      DataCell(Text(dateFormat.format(sentPlatParcel.time))),
    ];
    return DataRow(key: ValueKey(sentPlatParcel.id), cells: cells);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => sentParcels.length;

  @override
  int get selectedRowCount => 0;
}
