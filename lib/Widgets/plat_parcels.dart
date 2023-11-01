import 'package:eq_raid_boss/Widgets/Tables/plat_parcels_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlatParcelsReceived extends ConsumerStatefulWidget {
  final SharedPreferences prefs;
  const PlatParcelsReceived({
    super.key, required this.prefs
  });

  @override
  ConsumerState createState() => _PlatParcelsState();
}

class _PlatParcelsState extends ConsumerState<PlatParcelsReceived> {
  @override
  Widget build(BuildContext context) {
    return const PlatParcelsReceivedTable();
  }
}