import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/pages/tabs/home.dart';
import 'package:plannerop/store/auth.dart';
import 'package:plannerop/store/user.dart';
import 'package:plannerop/utils/dataManager.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:provider/provider.dart';

Future<void> tryAutoLogin(bool mounted, Function setState, bool _isLoading,
    BuildContext context) async {
  if (!mounted) return;

  // Usar un timer para evitar que el loader se quede colgado indefinidamente
  Timer? timeoutTimer;

  setState(() {
    _isLoading = true;
  });

  // Configurar un timeout para evitar que el loader se quede infinitamente
  timeoutTimer = Timer(const Duration(seconds: 8), () {
    if (mounted && _isLoading) {
      debugPrint('⚠️ AutoLogin timeout: cancelando operación');
      setState(() {
        _isLoading = false;
      });
    }
  });

  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool success = await authProvider.tryAutoLogin(context);

    // Cancelar el timer ya que hemos terminado correctamente
    timeoutTimer.cancel();

    if (!mounted) return;

    if (success) {
      // Inicializar datos del usuario a partir del token
      final decodedToken = JwtDecoder.decode(authProvider.accessToken);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      userProvider.setUser(User(
        name: decodedToken['username'],
        id: decodedToken['id'],
        dni: decodedToken['dni'],
        phone: decodedToken['phone'],
        cargo: decodedToken['occupation'],
      ));

      // Mostrar un loader más visible durante la carga de datos
      if (mounted) {
        // Un overlay más sofisticado para la carga de datos
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return PopScope(
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) {
                  debugPrint('Retroceso bloqueado');
                }
              },
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Cargando sesión...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }

      // Cargar datos con manejo de errores mejorado
      try {
        await DataManager().loadDataAfterAuthentication(context);
      } catch (dataError) {
        debugPrint('Error cargando datos: $dataError');
        // Continuar incluso si hay error en la carga de datos
      }

      // Navegar al dashboard
      if (mounted) {
        // Cerrar el diálogo de carga si está abierto
        if (ModalRoute.of(context)?.isCurrent != true) {
          Navigator.of(context).pop();
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const Home()),
        );
      }
    }
  } catch (e) {
    debugPrint('Error en auto-login: $e');
    // Cancelar el timer en caso de error
    timeoutTimer.cancel();
  } finally {
    // Asegurarnos de que _isLoading se establezca en false incluso si hay error
    if (mounted && _isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

Future<void> login(GlobalKey<FormState> _formKey, BuildContext context,
    bool mounted, String username, String password) async {
  if (_formKey.currentState!.validate()) {
    // Variable para controlar si el diálogo está mostrado
    bool dialogIsOpen = true;

    // Mantener una referencia al contexto del diálogo
    BuildContext? dialogContextRef;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Guardar la referencia al contexto del diálogo
        dialogContextRef = dialogContext;

        return PopScope(
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              debugPrint('Retroceso bloqueado');
            }
          }, // Prevenir cierre con el botón atrás
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        );
      },
    );

    // Función para cerrar el diálogo de manera segura
    void closeDialog() {
      if (dialogIsOpen && mounted && dialogContextRef != null) {
        Navigator.of(dialogContextRef!).pop();
        dialogIsOpen = false;
      }
    }

    // Configurar un timeout para cerrar el diálogo después de 15 segundos
    // Aumentado a 15 segundos para dar más tiempo a la carga de datos
    Future.delayed(const Duration(seconds: 15), () {
      if (dialogIsOpen) {
        closeDialog();
        if (mounted) {
          showAlertToast(
              context, 'La operación está tardando demasiado tiempo');
        }
      }
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Usar el nuevo método de login que guardará las credenciales
      final success = await authProvider.login(
        username,
        password,
        context,
      );

      if (success) {
        // Inicializar datos del usuario
        final decodedToken = JwtDecoder.decode(authProvider.accessToken);
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        userProvider.setUser(User(
          name: decodedToken['username'],
          id: decodedToken['id'],
          dni: decodedToken['dni'],
          phone: decodedToken['phone'],
          cargo: decodedToken['occupation'],
        ));

        // Cargar datos mientras se muestra el loader
        await DataManager().loadDataAfterAuthentication(context);

        // Navegar al dashboard
        if (mounted) {
          closeDialog();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
          );
        }
      } else {
        closeDialog();
        if (mounted) {
          showErrorToast(
              context, authProvider.error ?? 'Error de autenticación');
        }
      }
    } catch (e) {
      debugPrint('❌ Error en login: $e');
      closeDialog();
      if (mounted) {
        showErrorToast(context, 'Error de conexión: $e');
      }
    }
  }
}
