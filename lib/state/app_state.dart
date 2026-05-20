import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  int _revision = 0;
  int _syncRevision = 0;
  ThemeMode _themeMode = ThemeMode.light;

  int get revision => _revision;
  int get syncRevision => _syncRevision;
  ThemeMode get themeMode => _themeMode;

  void markChanged({bool scheduleSync = true}) {
    _revision++;
    if (scheduleSync) {
      _syncRevision++;
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
  }
}
