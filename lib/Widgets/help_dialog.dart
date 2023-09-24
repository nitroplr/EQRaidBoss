import 'package:flutter/material.dart';

class HelpDialog extends StatelessWidget {
  final String helpText;
  final String? title;
  final bool? centerHelp;

  const HelpDialog({super.key, required this.helpText, this.title, this.centerHelp});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: title == null
          ? null
          : Text(
        title!,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: SelectableText(
        helpText,
        textAlign: centerHelp != null ? TextAlign.center : null,
      ),
    );
  }
}