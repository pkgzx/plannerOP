import 'package:flutter/material.dart';
import 'package:plannerop/core/model/user.dart';

class UserProvider with ChangeNotifier {
  late User _user;

  User get user => _user;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }
}
