
import 'package:eq_raid_boss/Model/send_plat_parcel.dart';
import 'package:eq_raid_boss/Model/sent_plat_parcel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

SentPlatParcel? mostRecentSent;

class ParcelReceivereNotifier extends ChangeNotifier {
  List<SendPlatParcel> _sendParcels = [];

  List<SendPlatParcel> get sendParcels => _sendParcels;

  set sendParcels(List<SendPlatParcel> sendParcels) {
    _sendParcels = sendParcels;
    notifyListeners();
  }
}

final parcelReceiverProvider = ChangeNotifierProvider((ref) => ParcelReceivereNotifier());