import 'package:flutter/material.dart';

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