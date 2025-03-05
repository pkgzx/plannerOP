import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Variable global para FToast
final FToast fToast = FToast();

// Inicializar FToast (llamar esto en initState de los widgets que usan toast)
void initializeToast(BuildContext context) {
  fToast.init(context);
}

// Para notificaciones de éxito
void showSuccessToast(BuildContext context, String message) {
  // Asegurarse que fToast está inicializado
  fToast.init(context);

  // Crear widget para el toast personalizado
  Widget toast = Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      color: Colors.green,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          offset: const Offset(0, 3),
          blurRadius: 6,
        )
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.white),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );

  // Mostrar el toast
  fToast.showToast(
    child: toast,
    gravity: ToastGravity.BOTTOM,
    toastDuration: const Duration(seconds: 3),
  );
}

// Para notificaciones de error
void showErrorToast(BuildContext context, String message) {
  // Asegurarse que fToast está inicializado
  fToast.init(context);

  // Crear widget para el toast personalizado
  Widget toast = Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      color: Colors.red,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          offset: const Offset(0, 3),
          blurRadius: 6,
        )
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.white),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );

  // Mostrar el toast
  fToast.showToast(
    child: toast,
    gravity: ToastGravity.BOTTOM,
    toastDuration: const Duration(seconds: 3),
  );
}
