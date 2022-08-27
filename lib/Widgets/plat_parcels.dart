import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlatParcels extends ConsumerStatefulWidget {
  final SharedPreferences prefs;
  const PlatParcels({
    Key? key, required this.prefs
  }) : super(key: key);

  @override
  ConsumerState createState() => _PlatParcelsState();
}

class _PlatParcelsState extends ConsumerState<PlatParcels> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}