import 'package:eq_raid_boss/Widgets/Tables/chat_channel_linked_loots_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatChannelLinkedLootsWidget extends ConsumerStatefulWidget {
  final SharedPreferences prefs;

  const ChatChannelLinkedLootsWidget({super.key, required this.prefs});

  @override
  ConsumerState createState() => _ItemLootsState();
}

class _ItemLootsState extends ConsumerState<ChatChannelLinkedLootsWidget> {
  @override
  Widget build(BuildContext context) {
    String charFilePath = widget.prefs.getString('characterLogFile')!;
    return charFilePath == ''
        ? const SizedBox()
        : ChatChannelLinkedLootsSortableTable(
            prefs: widget.prefs,
          );
  }
}
