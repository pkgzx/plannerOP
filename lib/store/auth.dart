import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:plannerop/services/auth/authStorageService.dart';
import 'package:plannerop/services/auth/signin.dart';

class AuthProvider extends ChangeNotifier {
  String _accessToken = '';
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  String get accessToken => _accessToken;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  final AuthStorageService _authStorage = AuthStorageService();
  final SigninService _signinService = SigninService();

  void setAccessToken(String token) {
    _accessToken = token;
    _isAuthenticated = token.isNotEmpty;
    notifyListeners();
  }

  void clearAccessToken() {
    _accessToken = '';
    _isAuthenticated = false;
    notifyListeners();
  }

  // Método para iniciar sesión y guardar credenciales
  Future<bool> login(
      String username, String password, BuildContext context) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _signinService.signin(username, password, context);

      if (response.isSuccess) {
        _accessToken = response.accessToken;
        _isAuthenticated = true;

        // Guardar credenciales encriptadas
        await _authStorage.saveCredentials(
          token: response.accessToken,
          username: username,
          password: password,
        );

        notifyListeners();
        return true;
      } else {
        _error = 'Credenciales inválidas';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cerrar sesión y limpiar datos almacenados
  Future<void> logout() async {
    await _authStorage.clearCredentials();
    _accessToken = '';
    _isAuthenticated = false;
    notifyListeners();
  }

  // Intentar iniciar sesión automáticamente al iniciar la app
  Future<bool> tryAutoLogin(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Verificar si hay un token válido primero
      if (await _authStorage.isTokenValid()) {
        final token = await _authStorage.getToken();
        if (token != null) {
          _accessToken = token;
          _isAuthenticated = true;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      // Si no hay token válido pero hay credenciales guardadas, intentar login automático
      final username = await _authStorage.getUsername();
      final password = await _authStorage.getPassword();

      if (username != null && password != null) {
        final response =
            await _signinService.signin(username, password, context);

        if (response.isSuccess) {
          _accessToken = response.accessToken;
          _isAuthenticated = true;

          // Actualizar el token y la fecha de último login
          await _authStorage.saveCredentials(
            token: response.accessToken,
            username: username,
            password: password,
          );

          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Error en auto-login: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
