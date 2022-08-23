import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RefreshTicksVariableNotifier extends ChangeNotifier {
  bool _refresh = false;
  bool _endIsNow = true;

  bool get refresh => _refresh;
  bool get endIsNow => _endIsNow;

  set refresh(bool refresh) {
    _refresh = refresh;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifyListeners();
    });
  }

  set endIsNow(bool endIsNow) {
    _endIsNow = endIsNow;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifyListeners();
    });
  }
}

final refreshTicksVariableProvider =
    ChangeNotifierProvider((ref) => RefreshTicksVariableNotifier());