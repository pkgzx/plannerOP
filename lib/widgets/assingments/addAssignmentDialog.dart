import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:provider/provider.dart';
import './selected_worker_list.dart';

class AddAssignmentDialog extends StatefulWidget {
  const AddAssignmentDialog({Key? key}) : super(key: key);

  @override
  State<AddAssignmentDialog> createState() => _AddAssignmentDialogState();
}

class _AddAssignmentDialogState extends State<AddAssignmentDialog> {
  // Controladores para los campos de texto
  final _zoneController = TextEditingController();
  final _startDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _taskController = TextEditingController();

  // Lista de trabajadores seleccionados
  List<Worker> _selectedWorkers = [];

  // Lista completa de trabajadores (datos de ejemplo)
  final List<Worker> _allWorkers = [
    Worker(
      name: 'Juan Pérez',
      phone: '1234567890',
      document: '12345678',
      area: 'CARGA GENERAL',
      status: WorkerStatus.available,
      startDate: DateTime(2021, 10, 1),
      endDate: DateTime(2021, 10, 31),
    ),
    Worker(
      name: 'María González',
      phone: '1234567890',
      document: '12345678',
      area: 'CARGA GENERAL',
      status: WorkerStatus.available,
      startDate: DateTime(2021, 10, 1),
      endDate: DateTime(2021, 10, 31),
    ),
    Worker(
      name: 'Pedro Rodríguez',
      phone: '1234567890',
      document: '12345678',
      area: 'CARGA GENERAL',
      status: WorkerStatus.available,
      startDate: DateTime(2021, 10, 1),
      endDate: DateTime(2021, 10, 31),
    ),
    Worker(
      name: 'Ana López',
      phone: '1234567890',
      document: '12345678',
      area: 'CARGA GENERAL',
      status: WorkerStatus.available,
      startDate: DateTime(2021, 10, 1),
      endDate: DateTime(2021, 10, 31),
    ),
  ];

  final _area = [
    'CAFE',
    'CARGA GENERAL',
    'CARGA PELIGROSA',
    'CARGA REFRIGERADA',
    'CARGA SECA',
    'OPERADORES MC',
  ];

  // Mapa de tareas predefinidas para cada área
  final Map<String, List<String>> _predefinedTasks = {
    'CAFE': [
      'Inspección de granos',
      'Control de calidad',
      'Medición de humedad',
      'Pesaje de carga',
      'Clasificación de granos',
      'Etiquetado de lotes',
    ],
    'CARGA GENERAL': [
      'Recepción de mercancía',
      'Verificación de documentos',
      'Inspección de contenedores',
      'Control de inventario',
      'Despacho de carga',
      'Embalaje de productos',
    ],
    'CARGA PELIGROSA': [
      'Verificación de etiquetas ADR',
      'Inspección de sellos',
      'Control de temperatura',
      'Verificación de fugas',
      'Control de documentación especial',
      'Inspección de embalajes',
    ],
    'CARGA REFRIGERADA': [
      'Control de temperatura',
      'Inspección de equipos de frío',
      'Verificación de aislamiento',
      'Registro de temperatura',
      'Control de cadena de frío',
      'Inspección de sellos herméticos',
    ],
    'CARGA SECA': [
      'Control de humedad',
      'Inspección de embalajes',
      'Verificación de estiba',
      'Control de plagas',
      'Registro de lotes',
      'Inspección de contenedores',
    ],
  };

  // Lista actual de tareas según el área seleccionada
  List<String> _currentTasks = [];

  @override
  void dispose() {
    _zoneController.dispose();
    _startDateController.dispose();
    _startTimeController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Establecer la fecha y hora actuales por defecto
    _startDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _startTimeController.text = DateFormat('HH:mm').format(DateTime.now());
  }

  // Método para actualizar las tareas según el área seleccionada
  void _updateTasksForArea(String area) {
    setState(() {
      _currentTasks = _predefinedTasks[area] ?? [];
      // Limpiar el campo de tarea cuando se cambia el área
      _taskController.clear();
    });
  }

  // Método para actualizar la lista de trabajadores seleccionados
  void _updateSelectedWorkers(List<Worker> workers) {
    setState(() {
      _selectedWorkers = workers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 600,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nueva Asignación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF718096),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Lista de trabajadores seleccionados
              SelectedWorkersList(
                selectedWorkers: _selectedWorkers,
                onWorkersChanged: _updateSelectedWorkers,
                availableWorkers: _allWorkers,
              ),

              const SizedBox(height: 24),

              // Campo de selección de zona
              _buildDropdownField(
                'Área',
                'Seleccionar área',
                Icons.location_on_outlined,
                _zoneController,
                _area,
                onSelected: (value) {
                  // Actualizar las tareas cuando se selecciona un área
                  _updateTasksForArea(value);
                },
              ),

              // Campo de fecha de inicio
              _buildDateField(
                'Fecha de inicio',
                'DD/MM/AAAA',
                Icons.calendar_today_outlined,
                _startDateController,
              ),

              // Campo de hora de inicio
              _buildTimeField(
                'Hora de inicio',
                'HH:MM',
                Icons.schedule_outlined,
                _startTimeController,
              ),

              // Campo para seleccionar tarea (ahora es un dropdown basado en el área)
              _buildDropdownField(
                'Tarea',
                _zoneController.text.isEmpty
                    ? 'Primero selecciona un área'
                    : 'Seleccionar tarea',
                Icons.assignment_outlined,
                _taskController,
                _currentTasks,
                enabled: _zoneController.text.isNotEmpty,
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  NeumorphicButton(
                    style: NeumorphicStyle(
                      depth: 2,
                      intensity: 0.6,
                      color: Colors.white,
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Color(0xFF718096),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  NeumorphicButton(
                    style: NeumorphicStyle(
                      depth: 2,
                      intensity: 0.6,
                      color: const Color(0xFF3182CE),
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      // Validar los campos antes de continuar
                      if (_validateFields()) {
                        Navigator.of(context).pop();
                        _showSuccessDialog(context);
                      }
                    },
                    child: const Text(
                      'Guardar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller,
    List<String> options, {
    Function(String)? onSelected,
    bool enabled = true,
  }) {
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
            onTap: enabled
                ? () {
                    _showDropdownDialog(context, hint, options, controller,
                        onSelected: onSelected);
                  }
                : () {
                    // Si no está habilitado, mostrar un mensaje
                    if (label == 'Tarea') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Primero debes seleccionar un área'),
                          backgroundColor: Color(0xFFE53E3E),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: enabled
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFE2E8F0).withOpacity(0.7),
                ),
                borderRadius: BorderRadius.circular(8),
                color: enabled ? Colors.white : const Color(0xFFF7FAFC),
              ),
              child: Row(
                children: [
                  Icon(icon,
                      size: 20,
                      color: enabled
                          ? const Color(0xFF718096)
                          : const Color(0xFF718096).withOpacity(0.7)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.text.isEmpty ? hint : controller.text,
                      style: TextStyle(
                        color: controller.text.isEmpty
                            ? (enabled
                                ? const Color(0xFFA0AEC0)
                                : const Color(0xFFA0AEC0).withOpacity(0.7))
                            : (enabled ? Colors.black : Colors.black87),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down,
                      color: enabled
                          ? const Color(0xFF718096)
                          : const Color(0xFF718096).withOpacity(0.7)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller,
  ) {
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

              // Fecha inicial: hoy
              final DateTime firstDate = now;

              // Fecha final: 3 años desde ahora (esto asegura que siempre será posterior)
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
                setState(() {
                  controller.text = DateFormat('dd/MM/yyyy').format(picked);
                });
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

  Widget _buildTimeField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller,
  ) {
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
              TimeOfDay? initialTime;
              try {
                final timeParts = controller.text.split(':');
                if (timeParts.length == 2) {
                  initialTime = TimeOfDay(
                    hour: int.parse(timeParts[0]),
                    minute: int.parse(timeParts[1]),
                  );
                }
              } catch (_) {
                initialTime = TimeOfDay.now();
              }

              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: initialTime ?? TimeOfDay.now(),
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
                setState(() {
                  // Formatear con ceros a la izquierda
                  final hour = picked.hour.toString().padLeft(2, '0');
                  final minute = picked.minute.toString().padLeft(2, '0');
                  controller.text = '$hour:$minute';
                });
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
                  const Icon(Icons.access_time, color: Color(0xFF718096)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDropdownDialog(
    BuildContext context,
    String title,
    List<String> options,
    TextEditingController controller, {
    Function(String)? onSelected,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((option) {
                return ListTile(
                  title: Text(option),
                  onTap: () {
                    controller.text = option;
                    Navigator.of(context).pop();
                    setState(() {});

                    // Si hay una función de callback, la llamamos
                    if (onSelected != null) {
                      onSelected(option);
                    }
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  bool _validateFields() {
    if (_selectedWorkers.isEmpty) {
      _showValidationError('Por favor, selecciona al menos un trabajador');
      return false;
    }

    if (_zoneController.text.isEmpty) {
      _showValidationError('Por favor, selecciona un área');
      return false;
    }

    if (_startDateController.text.isEmpty) {
      _showValidationError('Por favor, selecciona una fecha de inicio');
      return false;
    }

    if (_startTimeController.text.isEmpty) {
      _showValidationError('Por favor, selecciona una hora de inicio');
      return false;
    }

    if (_taskController.text.isEmpty) {
      _showValidationError('Por favor, selecciona una tarea');
      return false;
    }

    // Si la validación es exitosa, guardar la asignación
    Provider.of<AssignmentsProvider>(context, listen: false).addAssignment(
      workers: _selectedWorkers,
      area: _zoneController.text,
      task: _taskController.text,
      date: DateFormat('dd/MM/yyyy').parse(_startDateController.text),
      time: _startTimeController.text,
    );

    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE53E3E),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF38A169),
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  '¡Asignación creada exitosamente!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'La asignación para ${_selectedWorkers.length} trabajador${_selectedWorkers.length > 1 ? 'es' : ''} ha sido programada para el ${_startDateController.text} a las ${_startTimeController.text}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tarea: ${_taskController.text}\nÁrea: ${_zoneController.text}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF718096),
                  ),
                ),
                if (_selectedWorkers.length <= 3) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Trabajadores: ${_selectedWorkers.map((w) => w.name).join(', ')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: 2,
                    intensity: 0.6,
                    color: const Color(0xFF3182CE),
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Aceptar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
