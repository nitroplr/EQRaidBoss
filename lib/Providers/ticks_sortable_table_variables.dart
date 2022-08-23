import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TicksSortableTableVariableNotifier extends ChangeNotifier {
  bool _isAscending = true;
  int _sortColumnIndex = 0;

  bool get isAscending => _isAscending;

  int get sortColumnIndex => _sortColumnIndex;

  set isAscending(bool isAscending) {
    _isAscending = isAscending;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifyListeners();
    });
  }

  set sortColumnIndex(int sortColumnIndex) {
    _sortColumnIndex = sortColumnIndex;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifyListeners();
    });
  }
}

final ticksSortableTableVariableProvider =
    ChangeNotifierProvider((ref) => TicksSortableTableVariableNotifier());