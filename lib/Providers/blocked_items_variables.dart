import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlockedItemsVariableNotifier extends ChangeNotifier {
  List<String> _blockedItems = [];

  List<String> get blockedItems => _blockedItems;

  set blockedItems(List<String> blocked) {
    _blockedItems = blocked;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifyListeners();
    });
  }
}

final blockedItemsVariableProvider = ChangeNotifierProvider((ref) => BlockedItemsVariableNotifier());