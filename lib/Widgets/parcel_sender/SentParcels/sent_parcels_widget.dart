import 'package:eq_raid_boss/Model/click_enums.dart';
import 'package:eq_raid_boss/Model/sent_plat_parcel.dart';
import 'package:eq_raid_boss/Providers/char_log_file_variables.dart';
import 'package:eq_raid_boss/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class SentParcelsWidget extends ConsumerWidget {
  final SharedPreferences prefs;

  const SentParcelsWidget({super.key, required this.prefs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateFormat dateFormat = DateFormat('h:mm:ss a');
    NumberFormat numberFormat = NumberFormat.decimalPattern();
    List<SentPlatParcel> sentParcels = ref.watch(charLogFileVariableProvider).sentPlatParcels;
    sentParcels.sort((a, b) => a.receiver.toLowerCase().compareTo(b.receiver.toLowerCase()));
    return LayoutBuilder(builder: (context, constraints) {
      double offset = 3;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 18.0, bottom: 6.0),
            child: ElevatedButton(
                onPressed: () => _setCursorPositions(context), child: const Text('Set cursor positions.')),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Parcels sent between start and now.'),
                IconButton(onPressed: (){
                  StringBuffer out = StringBuffer();
                  for (var sentParcel in sentParcels) {
                    out.writeln('${sentParcel.receiver};${numberFormat.format(sentParcel.amount)}');
                  }
                  Clipboard.setData(ClipboardData(text: out.toString()));
                  showSnackBar(context: context, message: 'Parcels sent copied to clipboard.');
                }, icon: const Icon(Icons.copy)),
              ],
            ),
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: sentParcels.length,
                  itemBuilder: (BuildContext context, int index) {
                    SentPlatParcel sentPlatParcel = sentParcels[index];
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: (constraints.maxWidth / 3) - offset, child: Text(sentPlatParcel.receiver)),
                          SizedBox(
                              width: (constraints.maxWidth / 3) - offset,
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text(numberFormat.format(sentPlatParcel.amount), textAlign: TextAlign.center)
                              ])),
                          SizedBox(
                              width: (constraints.maxWidth / 3) - offset,
                              child: Text(dateFormat.format(sentPlatParcel.time)))
                        ],
                      ),
                    );
                  })),
        ],
      );
    });
  }

  void _setCursorPositions(BuildContext context) {
    windowManager.setAlwaysOnTop(true);
    _dialogDelay(parcelDialogDelay, context);
    showAnimatedDialog(
            const AlertDialog(content: Text('Hold mouse cursor over platinum for $parcelDialogDelay seconds.')),
            context, false)
        .then((value) {
      screenRetriever.getCursorScreenPoint().then((value) {
        prefs.setInt(ClickEnums.platinumFirstClickX, value.dx.floor());
        prefs.setInt(ClickEnums.platinumFirstClickY, value.dy.floor());
      });
      _dialogDelay(parcelDialogDelay, context);
      showAnimatedDialog(
              const AlertDialog(
                  content: Text('Hold mouse cursor over platinum accept for $parcelDialogDelay seconds.')),
              context, false)
          .then((value) {
        screenRetriever.getCursorScreenPoint().then((value) {
          prefs.setInt(ClickEnums.platinumAcceptSecondClickX, value.dx.floor());
          prefs.setInt(ClickEnums.platinumAcceptSecondClickY, value.dy.floor());
        });
        _dialogDelay(parcelDialogDelay, context);
        showAnimatedDialog(
                const AlertDialog(
                    content:
                        Text('Hold mouse cursor over platinum \'Drop coins here\' for $parcelDialogDelay seconds.')),
                context, false)
            .then((value) {
          screenRetriever.getCursorScreenPoint().then((value) {
            prefs.setInt(ClickEnums.platinumDropCoinsThirdClickX, value.dx.floor());
            prefs.setInt(ClickEnums.platinumDropCoinsThirdClickY, value.dy.floor());
          });
          _dialogDelay(parcelDialogDelay, context);
          showAnimatedDialog(
                  const AlertDialog(
                      content: Text('Hold mouse cursor over platinum \'Deposit\' for $parcelDialogDelay seconds.')),
                  context, false)
              .then((value) {
            screenRetriever.getCursorScreenPoint().then((value) {
              prefs.setInt(ClickEnums.platinumDepositFourthClickX, value.dx.floor());
              prefs.setInt(ClickEnums.platinumDepositFourthClickY, value.dy.floor());
            });
            _dialogDelay(parcelDialogDelay, context);
            showAnimatedDialog(
                    const AlertDialog(
                        content: Text(
                            'Hold mouse cursor over parcel \'To:\' text input field for $parcelDialogDelay seconds.')),
                    context, false)
                .then((value) {
              screenRetriever.getCursorScreenPoint().then((value) {
                prefs.setInt(ClickEnums.receiverInputFifthClickX, value.dx.floor());
                prefs.setInt(ClickEnums.receiverInputFifthClickY, value.dy.floor());
              });
              _dialogDelay(parcelDialogDelay, context);
              showAnimatedDialog(
                      const AlertDialog(
                          content:
                              Text('Hold mouse cursor over parcel \'Send\' button for $parcelDialogDelay seconds.')),
                      context, false)
                  .then((value) {
                screenRetriever.getCursorScreenPoint().then((value) {
                  prefs.setInt(ClickEnums.sendSixthClickX, value.dx.floor());
                  prefs.setInt(ClickEnums.sendSixthClickY, value.dy.floor());
                });

                windowManager.setAlwaysOnTop(false);
                showSnackBar(context: context, message: 'Cursor positions set.');
              });
            });
          });
        });
      });
    });
  }

  Future<void> _dialogDelay(int dialogDelay, BuildContext context) async {
    await Future.delayed(Duration(seconds: dialogDelay)).then((value) => popNavigatorContext(context: context));
  }
}
