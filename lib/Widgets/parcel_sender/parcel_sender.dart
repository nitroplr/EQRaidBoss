import 'dart:ffi';
import 'package:eq_raid_boss/Widgets/parcel_sender/characters.dart';
import 'package:ffi/ffi.dart';

import 'package:eq_raid_boss/globals.dart';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';

class ParcelSender extends StatefulWidget {
  final SharedPreferences prefs;

  const ParcelSender({super.key, required this.prefs});

  @override
  State<ParcelSender> createState() => _ParcelSenderState();
}

class _ParcelSenderState extends State<ParcelSender> {
  final int dialogDelay = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
              onPressed: () {
                Future.delayed(const Duration(seconds: 2)).then((value) {
                  SetCursorPos(50, 50);
                  screenRetriever.getPrimaryDisplay().then((value) {
                    print(screenRetriever.getCursorScreenPoint().then((value) => print('${value.dx} ${value.dy}')));
                  });
                });
              },
              child: const Text('Move Cursor')),
          ElevatedButton(
              onPressed: () {
                _setCursorPositions(context);
              },
              child: const Text('Set cursor positions.')),
          ElevatedButton(
              onPressed: () async {
                int platinumFirstClickX = widget.prefs.getInt(ClickEnums.platinumFirstClickX) ?? 500;
                int platinumFirstClickY = widget.prefs.getInt(ClickEnums.platinumFirstClickY) ?? 500;
                int platinumQuantitySecondClickX = widget.prefs.getInt(ClickEnums.platinumQuantitySecondClickX) ?? 500;
                int platinumQuantitySecondClickY = widget.prefs.getInt(ClickEnums.platinumQuantitySecondClickY) ?? 500;
                int platinumAcceptThirdClickX = widget.prefs.getInt(ClickEnums.platinumAcceptThirdClickX) ?? 500;
                int platinumAcceptThirdClickY = widget.prefs.getInt(ClickEnums.platinumAcceptThirdClickY) ?? 500;
                int platinumDropCoinsFourthClickX =
                    widget.prefs.getInt(ClickEnums.platinumDropCoinsFourthClickX) ?? 500;
                int platinumDropCoinsFourthClickY =
                    widget.prefs.getInt(ClickEnums.platinumDropCoinsFourthClickY) ?? 500;
                int platinumDepositFifthClickX = widget.prefs.getInt(ClickEnums.platinumDepositFifthClickX) ?? 500;
                int platinumDepositFifthClickY = widget.prefs.getInt(ClickEnums.platinumDepositFifthClickY) ?? 500;
                int receiverInputSixthClickX = widget.prefs.getInt(ClickEnums.receiverInputSixthClickX) ?? 500;
                int receiverInputSixthClickY = widget.prefs.getInt(ClickEnums.receiverInputSixthClickY) ?? 500;
                int sendSeventhClickX = widget.prefs.getInt(ClickEnums.sendSeventhClickX) ?? 500;
                int sendSeventhClickY = widget.prefs.getInt(ClickEnums.sendSeventhClickY) ?? 500;
                showAnimatedDialog(
                    AlertDialog(
                      content: Text(
                          'Parcels will begin sending in $dialogDelay seconds.  Please make sure the EQ window has focus.'),
                    ),
                    context);
                await Future.delayed(Duration(seconds: dialogDelay)).then((value) {
                  popNavigatorContext(context: context);
                  //SetCursorPos(platinumFirstClickX, platinumFirstClickY);
                });
                await CharacterCodes.typeNumber(number: 01234567890);
                final mouse = calloc<INPUT>();
                mouse.ref.type = INPUT_MOUSE;
                mouse.ref.mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
                SendInput(1, mouse, sizeOf<INPUT>());
                await Future.delayed(const Duration(milliseconds: 50));
                mouse.ref.mi.dwFlags = MOUSEEVENTF_LEFTUP;
                SendInput(1, mouse, sizeOf<INPUT>());
              },
              child: const Text('Send Parcels')),
        ],
      ),
    );
  }

  void _setCursorPositions(BuildContext context) {
    windowManager.setAlwaysOnTop(true);
    _dialogDelay(dialogDelay, context);
    showAnimatedDialog(AlertDialog(content: Text('Hold mouse cursor over platinum for $dialogDelay seconds.')), context)
        .then((value) {
      screenRetriever.getCursorScreenPoint().then((value) {
        widget.prefs.setInt(ClickEnums.platinumFirstClickX, value.dx.floor());
        widget.prefs.setInt(ClickEnums.platinumFirstClickY, value.dy.floor());
      });
      _dialogDelay(dialogDelay, context);
      showAnimatedDialog(
              AlertDialog(content: Text('Hold mouse cursor over platinum quantity input for $dialogDelay seconds.')),
              context)
          .then((value) {
        screenRetriever.getCursorScreenPoint().then((value) {
          widget.prefs.setInt(ClickEnums.platinumQuantitySecondClickX, value.dx.floor());
          widget.prefs.setInt(ClickEnums.platinumQuantitySecondClickY, value.dy.floor());
        });
        _dialogDelay(dialogDelay, context);
        showAnimatedDialog(
                AlertDialog(content: Text('Hold mouse cursor over platinum accept for $dialogDelay seconds.')), context)
            .then((value) {
          screenRetriever.getCursorScreenPoint().then((value) {
            widget.prefs.setInt(ClickEnums.platinumAcceptThirdClickX, value.dx.floor());
            widget.prefs.setInt(ClickEnums.platinumAcceptThirdClickY, value.dy.floor());
          });
          _dialogDelay(dialogDelay, context);
          showAnimatedDialog(
                  AlertDialog(
                      content: Text('Hold mouse cursor over platinum \'Drop coins here\' for $dialogDelay seconds.')),
                  context)
              .then((value) {
            screenRetriever.getCursorScreenPoint().then((value) {
              widget.prefs.setInt(ClickEnums.platinumDropCoinsFourthClickX, value.dx.floor());
              widget.prefs.setInt(ClickEnums.platinumDropCoinsFourthClickY, value.dy.floor());
            });
            _dialogDelay(dialogDelay, context);
            showAnimatedDialog(
                    AlertDialog(content: Text('Hold mouse cursor over platinum \'Deposit\' for $dialogDelay seconds.')),
                    context)
                .then((value) {
              screenRetriever.getCursorScreenPoint().then((value) {
                widget.prefs.setInt(ClickEnums.platinumDepositFifthClickX, value.dx.floor());
                widget.prefs.setInt(ClickEnums.platinumDepositFifthClickY, value.dy.floor());
              });
              _dialogDelay(dialogDelay, context);
              showAnimatedDialog(
                      AlertDialog(
                          content:
                              Text('Hold mouse cursor over parcel \'To:\' text input field for $dialogDelay seconds.')),
                      context)
                  .then((value) {
                screenRetriever.getCursorScreenPoint().then((value) {
                  widget.prefs.setInt(ClickEnums.receiverInputSixthClickX, value.dx.floor());
                  widget.prefs.setInt(ClickEnums.receiverInputSixthClickY, value.dy.floor());
                });
                _dialogDelay(dialogDelay, context);
                showAnimatedDialog(
                        AlertDialog(
                            content: Text('Hold mouse cursor over parcel \'Send\' button for $dialogDelay seconds.')),
                        context)
                    .then((value) {
                  screenRetriever.getCursorScreenPoint().then((value) {
                    widget.prefs.setInt(ClickEnums.sendSeventhClickX, value.dx.floor());
                    widget.prefs.setInt(ClickEnums.sendSeventhClickY, value.dy.floor());
                  });

                  windowManager.setAlwaysOnTop(false);
                  showSnackBar(context: context, message: 'Cursor positions set.');
                });
              });
            });
          });
        });
      });
    });
  }

  Future <void> _dialogDelay(int dialogDelay, BuildContext context) async {
    await Future.delayed(Duration(seconds: dialogDelay)).then((value) => popNavigatorContext(context: context));
  }
}

class ClickEnums {
  static const String platinumFirstClickX = 'platinumFirstClickX';
  static const String platinumFirstClickY = 'platinumFirstClickY';

  static const String platinumQuantitySecondClickX = 'platinumQuantitySecondClickX';
  static const String platinumQuantitySecondClickY = 'platinumQuantitySecondClickY';

  static const String platinumAcceptThirdClickX = 'platinumAcceptThirdClickX';
  static const String platinumAcceptThirdClickY = 'platinumAcceptThirdClickY';

  static const String platinumDropCoinsFourthClickX = 'platinumDropCoinsFourthClickX';
  static const String platinumDropCoinsFourthClickY = 'platinumDropCoinsFourthClickY';

  static const String platinumDepositFifthClickX = 'platinumDepositFifthClickX';
  static const String platinumDepositFifthClickY = 'platinumDepositFifthClickY';

  static const String receiverInputSixthClickX = 'receiverInputSixthClickX';
  static const String receiverInputSixthClickY = 'receiverInputSixthClickY';

  static const String sendSeventhClickX = 'sendSeventhClickX';
  static const String sendSeventhClickY = 'sendSeventhClickY';
}
