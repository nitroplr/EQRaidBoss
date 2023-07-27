import 'package:eq_raid_boss/Model/send_plat_parcel.dart';
import 'package:eq_raid_boss/Providers/parcel_sender_provider.dart';
import 'package:eq_raid_boss/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SetParcelReceivers extends ConsumerWidget {
  const SetParcelReceivers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TextEditingController textEditingController = TextEditingController();
    //for testing
    /*textEditingController.text = 'Blastoff;1\nTempus;2\nTempus;3\nTempus 4\nBlastsk;5';
    Future.delayed(Duration.zero).then((value) => _setReceivers(textEditingController, context, ref));*/
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18.0, bottom: 6.0),
          child: ElevatedButton(
              onPressed: () {
                _setReceivers(textEditingController, context, ref);
              },
              child: const Text('Set Parcel Receivers')),
        ),
        const Text('Parcel receiver and price input.'),
        Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: TextField(
          controller: textEditingController,
          maxLines: 1000,
          decoration: const InputDecoration(
                hintMaxLines: 500,
                hintText:
                    'Paste parcels to send here.  Put one parcel on each line with the receiver on the left and ammount on the right.  Example: \nBlastoff 1000\nBlaston 1000 \n        or\nBlastoff;1000\nBlaston;1000'),
        ),
            ))
      ],
    );
  }

  void _setReceivers(TextEditingController textEditingController, BuildContext context, WidgetRef ref) {
    String input = textEditingController.text.trim();
    List<String> lines = input.split('\n');
    List<SendPlatParcel> sendParcels = [];
    for (var line in lines) {
      line = line.trim();
      line = line.replaceAll(',', '');
      if (line.contains(';')) {
        line = line.replaceAll(' ', '');
        List<String> split = line.split(';');
        try {
          if(split.length != 2) throw Exception();
          int amount = int.parse(split[1].trim());
          int numTwoMilSplits = (amount / twoMil).floor();
          for (int i = 0; i < numTwoMilSplits; i++) {
            sendParcels.add(SendPlatParcel(receiver: split[0].trim(), amount: twoMil));
          }
          if ((amount % twoMil) > 0) {
            sendParcels.add(SendPlatParcel(receiver: split[0].trim(), amount: (amount % twoMil)));
          }
        } on Exception {
          showAnimatedDialog(const AlertDialog(content: Text('Input improperly formatted.'),), context);
        }
      } else {
        line = line.replaceAll(RegExp(r'\s+'), ' ');
        List<String> split = line.split(' ');
        try {
          if(split.length != 2) throw Exception();
          int amount = int.parse(split[1].trim());
          int numTwoMilSplits = (amount / twoMil).floor();
          for (int i = 0; i < numTwoMilSplits; i++) {
            sendParcels.add(SendPlatParcel(receiver: split[0].trim(), amount: twoMil));
          }
          if ((amount % twoMil) > 0) {
            sendParcels.add(SendPlatParcel(receiver: split[0].trim(), amount: (amount % twoMil)));
          }
        } on Exception {
          showAnimatedDialog(const AlertDialog(content: Text('Input improperly formatted.'),), context);
        }
      }
    }
    sendParcels.sort((a, b) => a.receiver.toLowerCase().compareTo(b.receiver.toLowerCase()));
    ref.read(parcelReceiverProvider).sendParcels = sendParcels;
  }
}
