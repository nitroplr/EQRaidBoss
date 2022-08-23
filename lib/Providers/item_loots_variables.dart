
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ItemLootsVariableNotifier extends ChangeNotifier {
  List<String> _itemLoots = [];
  int _byteOffset = 0;

  List<String> get itemLoots => _itemLoots;

  int get byteOffset => _byteOffset;

  set itemLoots(List<String> loots) {
    _itemLoots = loots;
    notifyListeners();
  }

  set byteOffset(int offset) {
    _byteOffset = offset;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifyListeners();
    });
  }
}

final itemLootsVariableProvider = ChangeNotifierProvider((ref) => ItemLootsVariableNotifier());