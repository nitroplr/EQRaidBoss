import 'package:eq_raid_boss/Providers/char_log_file_variables.dart';
import 'package:eq_raid_boss/Providers/refresh_ticks_variable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showSnackBar({String message = '', bool printToConsole = false, required BuildContext context}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  SnackBar snackbar = SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(
        message,
        textAlign: TextAlign.center,
      ));
  ScaffoldMessenger.of(context).showSnackBar(snackbar);
  if (printToConsole) {
    print(message);
  }
}

void refreshData({required WidgetRef ref}){
  ref.read(charLogFileVariableProvider).byteOffset = 0;
  ref.read(charLogFileVariableProvider).itemLoots = [];
  ref.read(charLogFileVariableProvider).platParcels = [];
  ref.read(refreshTicksVariableProvider).refresh = true;
}