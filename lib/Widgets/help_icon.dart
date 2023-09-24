import 'package:eq_raid_boss/Widgets/help_dialog.dart';
import 'package:eq_raid_boss/globals.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HelpIcon extends StatelessWidget {
  final String helpText;
  final String? title;
  final bool? centerHelp;

  const HelpIcon({super.key, required this.helpText, this.title, this.centerHelp});

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () {
          showAnimatedDialog(
              HelpDialog(
                helpText: helpText,
                title: title,
                centerHelp: centerHelp,
              ),
              context);
        },
        icon: const Icon(CupertinoIcons.question));
  }
}