
import 'package:eq_raid_boss/Model/item_loot.dart';
import 'package:eq_raid_boss/Model/plat_parcel.dart';
import 'package:eq_raid_boss/Model/sent_plat_parcel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CharLogFileVariableNotifier extends ChangeNotifier {
  List<ItemLoot> _itemLoots = [];
  List<ItemLoot> _allItemLootsInRange = [];
  List<PlatParcel> _platParcels = [];
  List<SentPlatParcel> _sentPlatParcels = [];

  int _byteOffset = 0;
  bool _isProcessing = false;

  List<ItemLoot> get itemLoots => _itemLoots;
  List<ItemLoot> get allItemLootsInRange => _allItemLootsInRange;
  List<PlatParcel> get platParcels => _platParcels;
  List<SentPlatParcel> get sentPlatParcels => _sentPlatParcels;

  int get byteOffset => _byteOffset;
  bool get  isProcessing=> _isProcessing;

  set itemLoots(List<ItemLoot> loots) {
    _itemLoots = loots;
    notifyListeners();
  }

  set allItemLootsInRange(List<ItemLoot> loots) {
    _allItemLootsInRange = loots;
    notifyListeners();
  }

  set platParcels(List<PlatParcel> parcels) {
    _platParcels = parcels;
    notifyListeners();
  }

  set sentPlatParcels(List<SentPlatParcel> sentParcels){
    _sentPlatParcels = sentParcels;
    notifyListeners();
  }

  set byteOffset(int offset) {
    _byteOffset = offset;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifyListeners();
    });
  }

  set isProcessing(bool isProcessing){
    _isProcessing = isProcessing;
  }

  void updateOffsetAndParcels({required int offset,required List<PlatParcel> parcels,required List<SentPlatParcel> sentParcels}){
    _byteOffset = offset;
    _platParcels = parcels;
    _sentPlatParcels = sentParcels;
    notifyListeners();
  }
}

final charLogFileVariableProvider = ChangeNotifierProvider((ref) => CharLogFileVariableNotifier());