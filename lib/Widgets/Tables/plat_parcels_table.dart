import 'package:eq_raid_boss/Model/plat_parcel.dart';
import 'package:eq_raid_boss/Providers/char_log_file_variables.dart';
import 'package:eq_raid_boss/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class PlatParcelsTable extends ConsumerStatefulWidget {
  const PlatParcelsTable({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState createState() => _PlatParcelsTableState();
}

class _PlatParcelsTableState extends ConsumerState<PlatParcelsTable> {
  NumberFormat numberFormat = NumberFormat.decimalPattern();
  @override
  Widget build(BuildContext context) {
    List<PlatParcel> parcels = ref.watch(charLogFileVariableProvider).platParcels;
    int total = 0;
    for (var element in parcels) {
      total += element.amount;
    }
    final columns = ['Time', 'Sender', '$total'];
    parcels.sort((a, b) {
      if (a.sender == b.sender) {
        if (a.amount == b.amount) {
          return a.time.compareTo(b.time);
        }
        return a.amount.compareTo(b.amount);
      }
      return a.sender.compareTo(b.sender);
    });
    return Scaffold(
      body: SingleChildScrollView(
          controller: ScrollController(),
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: double.maxFinite,
            child: InkWell(
              onTap: () {
                _outputParcelSummary(parcels: parcels);
              },
              mouseCursor: SystemMouseCursors.basic,
              child: DataTable(
                columns: getColumns(columns),
                rows: getRows(parcels),
              ),
            ),
          )),
    );
  }

  List<DataColumn> getColumns(List<String> columns) => columns
      .map((String column) => DataColumn(
            label: Text(column),
          ))
      .toList();

  List<DataRow> getRows(List<PlatParcel> parcels) => parcels.map((PlatParcel parcel) {
        return DataRow(cells: [
          DataCell(Text(DateFormat('EEE, MMM d, h:mm a').format(parcel.time))),
          DataCell(Text(parcel.sender)),
          DataCell(
            Text(
              numberFormat.format(parcel.amount),
            ),
          ),
        ]);
      }).toList();

  List<DataCell> getCells(List<dynamic> cells) => cells.map((data) {
        var potentialDate = int.tryParse(data.toString());
        if (potentialDate != null) {
          return DataCell(
              Text(DateFormat('EEE, MMM d, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(potentialDate))));
        }
        return DataCell(Text('$data'));
      }).toList();

  ///parcels must be sorted
  void _outputParcelSummary({required List<PlatParcel> parcels}) {
    StringBuffer output = StringBuffer('Sender;Plat Sent\n');
    Map<String, int> memberTotals = {};
    for (var parcel in parcels) {
      memberTotals.update(parcel.sender, (value) => (parcel.amount + value), ifAbsent: () => parcel.amount);
      output.writeln('${parcel.sender};${numberFormat.format(parcel.amount)}');
    }
    output.writeln('\nSender;Total Sent');
    memberTotals.forEach((key, value) {output.writeln('$key;${numberFormat.format(value)}');});

    Clipboard.setData(ClipboardData(text: output.toString()));
    showSnackBar(context: context, message: 'Parcel summary copied to clipboard.');
  }
}
