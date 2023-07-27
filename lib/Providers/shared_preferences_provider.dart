import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  //allows for overriding with an awaited future in main.dart before application startup
  throw UnimplementedError();
});