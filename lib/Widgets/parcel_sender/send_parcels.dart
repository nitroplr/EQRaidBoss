import 'dart:math';

import 'package:eq_raid_boss/Model/click_enums.dart';
import 'package:eq_raid_boss/Model/send_plat_parcel.dart';
import 'package:eq_raid_boss/Providers/parcel_sender_provider.dart';
import 'package:eq_raid_boss/Widgets/parcel_sender/typing.dart';
import 'package:eq_raid_boss/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';
import 'dart:ffi';

class SendParcels extends ConsumerStatefulWidget {
  final SharedPreferences prefs;

  const SendParcels({super.key, required this.prefs});

  @override
  ConsumerState<SendParcels> createState() => _SendParcelsState();
}

class _SendParcelsState extends ConsumerState<SendParcels> {
  List<SendPlatParcel> sendParcels = [];
  late int platinumFirstClickX;
  late int platinumFirstClickY;
  late int platinumAcceptSecondClickX;
  late int platinumAcceptSecondClickY;
  late int platinumDropCoinsThirdClickX;
  late int platinumDropCoinsThirdClickY;
  late int platinumDepositFourthClickX;
  late int platinumDepositFourthClickY;
  late int receiverInputFifthClickX;
  late int receiverInputFifthClickY;
  late int sendSixthClickX;
  late int sendSixthClickY;
  bool keepGoing = true;
  late final TextEditingController newDelayController;
  int? delay = 150;

  @override
  void initState() {
    newDelayController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    newDelayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _setClickLocations();
    sendParcels = ref.watch(parcelReceiverProvider).sendParcels;
    delay = widget.prefs.getInt('delay');
    if (delay == null) {
      widget.prefs.setInt('delay', 150);
      delay = 150;
    }
    NumberFormat numberFormat = NumberFormat.decimalPattern();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child:  Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      onPressed: () {
                        showAnimatedDialog(
                            AlertDialog(
                              title: const Text('Set Action Delay'),
                              content: SizedBox(
                                width: 400,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                        'There is a built in random 0-100ms delay that will be added to this delay.  This delay is also in milliseconds (1000ms = 1s).'),
                                    TextFormField(
                                        autofocus: true,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                                          LengthLimitingTextInputFormatter(11)
                                        ],
                                        controller: newDelayController,
                                        onFieldSubmitted: (text) {
                                          _setDelay();
                                        }),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: ElevatedButton(
                                          onPressed: () {
                                            _setDelay();
                                          },
                                          child: const Text('Set Delay')),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            context);
                      },
                      icon: const Icon(Icons.edit)),
                  Text('Delay: $delay (ms) '),
                ],
              ),
              ElevatedButton(
                  onPressed: () async {
                    showAnimatedDialog(
                        const AlertDialog(
                          content: Text(
                              'Parcels will begin sending in $parcelDialogDelay seconds.  Please make sure the EQ window has focus.  Move the mouse to cancel.'),
                        ),
                        context);
                    await Future.delayed(const Duration(seconds: parcelDialogDelay)).then((value) async {
                      popNavigatorContext(context: context);
                      await Future.forEach(sendParcels, (SendPlatParcel parcel) async {
                        if (keepGoing) {
                          keepGoing = await _sendParcel(parcel: parcel);
                        } else {
                          return Future(() => null);
                        }
                      });
                      keepGoing = true;
                    });
                  },
                  child: const Text('Send Parcels')),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 10.0),
          child: Text('Parcels to be sent.'),
        ),
        Expanded(
            child: ListView.builder(
                itemCount: sendParcels.length,
                itemBuilder: (BuildContext context, int index) {
                  SendPlatParcel send = sendParcels[index];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(send.receiver), Text(numberFormat.format(send.amount))],
                  );
                })),
      ],
    );
  }

  void _setDelay() {
    int newDelay = int.tryParse(newDelayController.text.trim()) ?? 50;
    widget.prefs.setInt('delay', newDelay);
    setState(() {
      delay = newDelay;
    });
    newDelayController.clear();
    popNavigatorContext(context: context);
  }

  void _setClickLocations() {
    platinumFirstClickX = widget.prefs.getInt(ClickEnums.platinumFirstClickX) ?? 500;
    platinumFirstClickY = widget.prefs.getInt(ClickEnums.platinumFirstClickY) ?? 500;
    platinumAcceptSecondClickX = widget.prefs.getInt(ClickEnums.platinumAcceptSecondClickX) ?? 500;
    platinumAcceptSecondClickY = widget.prefs.getInt(ClickEnums.platinumAcceptSecondClickY) ?? 500;
    platinumDropCoinsThirdClickX = widget.prefs.getInt(ClickEnums.platinumDropCoinsThirdClickX) ?? 500;
    platinumDropCoinsThirdClickY = widget.prefs.getInt(ClickEnums.platinumDropCoinsThirdClickY) ?? 500;
    platinumDepositFourthClickX = widget.prefs.getInt(ClickEnums.platinumDepositFourthClickX) ?? 500;
    platinumDepositFourthClickY = widget.prefs.getInt(ClickEnums.platinumDepositFourthClickY) ?? 500;
    receiverInputFifthClickX = widget.prefs.getInt(ClickEnums.receiverInputFifthClickX) ?? 500;
    receiverInputFifthClickY = widget.prefs.getInt(ClickEnums.receiverInputFifthClickY) ?? 500;
    sendSixthClickX = widget.prefs.getInt(ClickEnums.sendSixthClickX) ?? 500;
    sendSixthClickY = widget.prefs.getInt(ClickEnums.sendSixthClickY) ?? 500;
  }

  ///returns true if you should keep going, false if you should stop
  Future<bool> _sendParcel({required SendPlatParcel parcel}) async {
    SetCursorPos(platinumFirstClickX, platinumFirstClickY);
    await _pause();
    await _leftClick();
    await _pause();

    keepGoing = await _checkCursorNotMovedByUser(x: platinumFirstClickX, y: platinumFirstClickY);
    if (!keepGoing) return false;

    await Typing.deleteText();
    await _pause();
    await Typing.typeNumber(number: parcel.amount);
    await _pause();

    keepGoing = await _checkCursorNotMovedByUser(x: platinumFirstClickX, y: platinumFirstClickY);
    if (!keepGoing) return false;

    SetCursorPos(platinumAcceptSecondClickX, platinumAcceptSecondClickY);
    await _pause();
    await _leftClick();
    await _pause();

    keepGoing = await _checkCursorNotMovedByUser(x: platinumAcceptSecondClickX, y: platinumAcceptSecondClickY);
    if (!keepGoing) return false;

    SetCursorPos(platinumDropCoinsThirdClickX, platinumDropCoinsThirdClickY);
    await _pause();
    await _leftClick();
    await _pause();

    keepGoing = await _checkCursorNotMovedByUser(x: platinumDropCoinsThirdClickX, y: platinumDropCoinsThirdClickY);
    if (!keepGoing) return false;

    SetCursorPos(platinumDepositFourthClickX, platinumDepositFourthClickY);
    await _pause();
    await _leftClick();
    await _pause();

    keepGoing = await _checkCursorNotMovedByUser(x: platinumDepositFourthClickX, y: platinumDepositFourthClickY);
    if (!keepGoing) return false;

    SetCursorPos(receiverInputFifthClickX, receiverInputFifthClickY);
    await _pause();
    await _leftClick();
    await _pause();

    keepGoing = await _checkCursorNotMovedByUser(x: receiverInputFifthClickX, y: receiverInputFifthClickY);
    if (!keepGoing) return false;

    await Typing.deleteText();
    await _pause();

    keepGoing = await _checkCursorNotMovedByUser(x: receiverInputFifthClickX, y: receiverInputFifthClickY);
    if (!keepGoing) return false;

    await Typing.typeString(text: parcel.receiver.toLowerCase());
    await _pause();

    keepGoing = await _checkCursorNotMovedByUser(x: receiverInputFifthClickX, y: receiverInputFifthClickY);
    if (!keepGoing) return false;

    SetCursorPos(sendSixthClickX, sendSixthClickY);
    await _pause();
    await _leftClick();
    await _pause();

    keepGoing = await _checkCursorNotMovedByUser(x: sendSixthClickX, y: sendSixthClickY);
    if (!keepGoing) return false;
    await Future.delayed(const Duration(milliseconds: 2000));
    return true;
  }

  Future<dynamic> _pause() => Future.delayed(Duration(milliseconds: _getRandomPauseTime(max: 100, min: delay!)));

  int _getRandomPauseTime({required int max, required int min}) {
    Random rand = Random(DateTime.now().millisecondsSinceEpoch);
    if (max < 100) {
      return rand.nextInt(100) + min;
    }
    return rand.nextInt(max) + min;
  }

  Future<void> _leftClick() async {
    final mouse = calloc<INPUT>();
    mouse.ref.type = INPUT_MOUSE;
    mouse.ref.mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
    SendInput(1, mouse, sizeOf<INPUT>());
    await Future.delayed(const Duration(milliseconds: 50));
    mouse.ref.mi.dwFlags = MOUSEEVENTF_LEFTUP;
    SendInput(1, mouse, sizeOf<INPUT>());
  }

  Future<bool> _checkCursorNotMovedByUser({required int x, required int y}) async {
    return screenRetriever.getCursorScreenPoint().then((value) {
      if (((value.dx - x) > 50) || ((x - value.dx) > 50)) {
        return false;
      }
      if (((value.dy - y) > 50) || ((y - value.dy) > 50)) {
        return false;
      }
      return true;
    });
  }
}
