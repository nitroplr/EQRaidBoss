import 'package:eq_raid_boss/Widgets/parcel_sender/send_parcels.dart';
import 'package:eq_raid_boss/Widgets/parcel_sender/SentParcels/sent_parcels_widget.dart';
import 'package:eq_raid_boss/Widgets/parcel_sender/set_parcel_receivers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParcelSender extends ConsumerStatefulWidget {
  final SharedPreferences prefs;

  const ParcelSender({super.key, required this.prefs});

  @override
  ConsumerState<ParcelSender> createState() => _ParcelSenderState();
}

class _ParcelSenderState extends ConsumerState<ParcelSender> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(width: (MediaQuery.of(context).size.width * .33) - 1, child: const SetParcelReceivers()),
          SizedBox(width: (MediaQuery.of(context).size.width * .33) - 1, child: SendParcels(prefs: widget.prefs)),
          SizedBox(width: (MediaQuery.of(context).size.width * .33) - 1, child: SentParcelsWidget(prefs: widget.prefs))
        ],
      ),
    );
  }
}
