
import 'package:eq_raid_boss/Model/item_loot.dart';
import 'package:eq_raid_boss/Model/plat_parcel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CharLogFileVariableNotifier extends ChangeNotifier {
  List<ItemLoot> _itemLoots = [];
  List<ItemLoot> _allItemLootsInRange = [];
  List<PlatParcel> _platParcels = [];
  int _byteOffset = 0;
  bool _isProcessing = false;

  List<ItemLoot> get itemLoots => _itemLoots;
  List<ItemLoot> get allItemLootsInRange => _allItemLootsInRange;
  List<PlatParcel> get platParcels => _platParcels;
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

  set byteOffset(int offset) {
    _byteOffset = offset;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifyListeners();
    });
  }

  set isProcessing(bool isProcessing){
    _isProcessing = isProcessing;
  }

  void updateOffsetAndParcels(int offset, List<PlatParcel> parcels){
    _byteOffset = offset;
    _platParcels = parcels;
    notifyListeners();
  }
}

final charLogFileVariableProvider = ChangeNotifierProvider((ref) => CharLogFileVariableNotifier());