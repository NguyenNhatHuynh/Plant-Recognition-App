import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  int _revision = 0;
  int _syncRevision = 0;

  int get revision => _revision;
  int get syncRevision => _syncRevision;

  void markChanged({bool scheduleSync = true}) {
    _revision++;
    if (scheduleSync) {
      _syncRevision++;
    }
    notifyListeners();
  }
}
