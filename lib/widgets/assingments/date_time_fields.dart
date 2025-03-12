import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/utils/toast.dart';

class DateField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final Function(String)? onDateChanged; // Añadir esta callback
  final bool isOptional;

  const DateField({
    Key? key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.onDateChanged, // Opcional para notificar cambios
    this.isOptional = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final DateTime now = DateTime.now();
              final DateTime firstDate = now;
              final DateTime lastDate =
                  DateTime(now.year + 3, now.month, now.day);

              // Intentar usar la fecha actual del campo o usar hoy
              DateTime initialDate;
              try {
                initialDate = DateFormat('dd/MM/yyyy').parse(controller.text);
                // Si la fecha es anterior a hoy, usar hoy
                if (initialDate.isBefore(firstDate)) {
                  initialDate = firstDate;
                }
              } catch (_) {
                initialDate = firstDate;
              }

              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: firstDate,
                lastDate: lastDate,
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF3182CE),
                        onPrimary: Colors.white,
                      ),
                      dialogBackgroundColor: Colors.white,
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                final formattedDate = DateFormat('dd/MM/yyyy').format(picked);
                controller.text = formattedDate;

                // Notificar que la fecha ha cambiado
                if (onDateChanged != null) {
                  onDateChanged!(formattedDate);

                  // Log para debug
                  debugPrint('Fecha cambiada a: $formattedDate');
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: const Color(0xFF718096)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.text.isEmpty ? hint : controller.text,
                      style: TextStyle(
                        color: controller.text.isEmpty
                            ? const Color(0xFFA0AEC0)
                            : Colors.black,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today, color: Color(0xFF718096)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimeField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextEditingController? dateController;
  final bool isOptional;

  const TimeField({
    Key? key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.dateController,
    this.isOptional = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Crear un valor clave para debugging
    debugPrint(
        'TimeField build - date: ${dateController?.text}, time: ${controller.text}');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _selectTime(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: const Color(0xFF718096)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.text.isEmpty ? hint : controller.text,
                      style: TextStyle(
                        color: controller.text.isEmpty
                            ? const Color(0xFFA0AEC0)
                            : Colors.black,
                      ),
                    ),
                  ),
                  const Icon(Icons.access_time, color: Color(0xFF718096)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Extraemos la lógica de selección a un método separado para mayor claridad
  Future<void> _selectTime(BuildContext context) async {
    try {
      // Determinar la hora inicial para el selector
      TimeOfDay initialTime;
      try {
        if (controller.text.isNotEmpty) {
          final timeParts = controller.text.split(':');
          initialTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        } else {
          initialTime = TimeOfDay.now();
        }
      } catch (e) {
        debugPrint('Error parsing time: $e');
        initialTime = TimeOfDay.now();
      }

      // Verificar si es hoy para establecer restricciones de hora
      bool isToday = false;
      TimeOfDay? minimumTime;

      // Solo verificamos restricciones si tenemos una fecha
      if (dateController != null && dateController!.text.isNotEmpty) {
        try {
          final selectedDate =
              DateFormat('dd/MM/yyyy').parse(dateController!.text);
          final now = DateTime.now();

          // Verificar si es hoy
          isToday = selectedDate.year == now.year &&
              selectedDate.month == now.month &&
              selectedDate.day == now.day;

          if (isToday) {
            minimumTime = TimeOfDay.now();
            debugPrint('Es hoy: ${minimumTime.hour}:${minimumTime.minute}');
          } else {
            debugPrint('No es hoy: ${dateController!.text}');
          }
        } catch (e) {
          debugPrint('Error al validar fecha: $e');
        }
      } else {
        debugPrint('No hay fecha seleccionada');
      }

      // Mostrar el selector de hora
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF3182CE),
                onPrimary: Colors.white,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );

      // Si el usuario seleccionó una hora
      if (picked != null) {
        // Comprobación solo si es el día de hoy
        if (isToday && minimumTime != null) {
          final selectedMinutes = picked.hour * 60 + picked.minute;
          final minimumMinutes = minimumTime.hour * 60 + minimumTime.minute;

          if (selectedMinutes < minimumMinutes) {
            showAlertToast(context,
                'No se puede seleccionar una hora anterior a la actual');
            return; // No actualizar el controlador si la hora es inválida
          }
        }

        // Formatear la hora seleccionada
        final hour = picked.hour.toString().padLeft(2, '0');
        final minute = picked.minute.toString().padLeft(2, '0');
        controller.text = '$hour:$minute';

        // Obligar actualización de UI si es necesario
        if (context is StatefulElement) {
          (context.state as State).setState(() {});
        }

        debugPrint('Hora seleccionada: ${controller.text}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error en selector de hora: $e');
      debugPrint('Stack trace: $stackTrace');

      // Mostrar un error genérico
      showErrorToast(context, 'Error al seleccionar la hora');
    }
  }
}
