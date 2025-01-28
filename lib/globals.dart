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
  ref.read(charLogFileVariableProvider).allItemLootsInRange.clear();
  ref.read(charLogFileVariableProvider).byteOffset = 0;
  ref.read(charLogFileVariableProvider).itemLoots = [];
  ref.read(charLogFileVariableProvider).platParcels = [];
  ref.read(charLogFileVariableProvider).chatChannelLoots = [];
  ref.read(refreshTicksVariableProvider).refresh = true;
}

Future<void> showAnimatedDialog(Widget dialog, BuildContext context, [bool? barrierDismissable]) {
  return showGeneralDialog(
    barrierColor: Colors.blueGrey.withAlpha(64),
    barrierDismissible: barrierDismissable ?? true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    context: context,
    pageBuilder: (ctx, a1, a2) {
      return dialog;
    },
    transitionBuilder: (ctx, a1, a2, child) {
      var curve = Curves.easeOutCubic.transform(a1.value) - 1.0;
      return Transform(
        transform: Matrix4.translationValues(0.0, curve * 400, 0.0),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 500),
  );
}


void popNavigatorContext({required BuildContext context}) {
  if (context.mounted) {
    Navigator.of(context).pop();
  }
}
const int parcelDialogDelay = 5;

const int twoMil = 2000000;