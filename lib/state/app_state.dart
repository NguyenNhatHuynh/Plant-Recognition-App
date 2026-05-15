import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  int _revision = 0;

  int get revision => _revision;

  void markChanged() {
    _revision++;
    notifyListeners();
  }
}
