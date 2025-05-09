import 'package:flutter/material.dart';
import 'package:plannerop/core/model/user.dart';

class UserProvider with ChangeNotifier {
  late User _user;
  bool _hasUser = false;

  User get user => _user;
  bool get hasUser => _hasUser;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  // Método para limpiar los datos del usuario
  void clearUser() {
    _hasUser = false;
    notifyListeners();
  }
}
