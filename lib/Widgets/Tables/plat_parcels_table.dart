import 'package:eq_raid_boss/Model/plat_parcel.dart';
import 'package:eq_raid_boss/Providers/char_log_file_variables.dart';
import 'package:eq_raid_boss/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class PlatParcelsReceivedTable extends ConsumerStatefulWidget {
  const PlatParcelsReceivedTable({
    super.key,
  });

  @override
  ConsumerState createState() => _PlatParcelsTableState();
}

class _PlatParcelsTableState extends ConsumerState<PlatParcelsReceivedTable> {
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
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DataTable(
                      columns: getColumns(columns),
                      rows: getRows(parcels),
                    ),
                  ),
                ],
              ),
              Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => showAnimatedDialog(
                        AlertDialog(
                          title: const Text('Output Parcels Received'),
                          actionsAlignment: MainAxisAlignment.spaceBetween,
                          actions: [
                            ElevatedButton(
                                onPressed: () => _outputParcelSummary(parcels: parcels, allParcels: true),
                                child: const Text('All Parcels')),
                            ElevatedButton(
                                onPressed: () => _outputParcelSummary(parcels: parcels, allParcels: false),
                                child: const Text('Parcel Totals'))
                          ],
                        ),
                        context),
                  ))
            ],
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
  void _outputParcelSummary({required List<PlatParcel> parcels, required bool allParcels}) {
    StringBuffer output = StringBuffer();
    Map<String, int> memberTotals = {};
    for (var parcel in parcels) {
      memberTotals.update(parcel.sender, (value) => (parcel.amount + value), ifAbsent: () => parcel.amount);
      if (allParcels) {
        output.writeln('${parcel.sender};${numberFormat.format(parcel.amount)}');
      }
    }
    if (!allParcels) {
      memberTotals.forEach((key, value) {
        output.writeln('$key;${numberFormat.format(value)}');
      });
    }
    popNavigatorContext(context: context);
    Clipboard.setData(ClipboardData(text: output.toString()));
    showSnackBar(context: context, message: 'Parcels received copied to clipboard.');
  }
}
