import 'package:flutter/material.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/services/chargersOp/chargersOp.dart';

class ChargersOpProvider extends ChangeNotifier {
  final ChargersopService _chargersopService = ChargersopService();
  List<User> _chargers = [];

  List<User> get chargers => _chargers;

  void addCharger(User charger) {
    _chargers.add(charger);
    notifyListeners();
  }

  Future<void> fetchChargers(BuildContext context) async {
    try {
      final chargers = await _chargersopService.getChargers(context);
      _chargers = chargers;
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }
}
