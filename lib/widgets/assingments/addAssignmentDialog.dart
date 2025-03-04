import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/area.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/store/workers.dart';
import 'package:provider/provider.dart';
import './selected_worker_list.dart';
import './assignment_form.dart';
import './success_dialog.dart';
import './predefined_tasks.dart';

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
  final List<Worker> _allWorkers = [];

  List<Area> _areas = [];

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
    debugPrint('Actualizando tareas para: "$area"');

    // Obtener las tareas para esta área
    final List<String> tasksForArea = PredefinedTasks.getTasksForArea(area);

    setState(() {
      _currentTasks = tasksForArea;
      // Limpiar el campo de tarea cuando se cambia el área
      _taskController.clear();
    });

    debugPrint('Total de tareas disponibles: ${_currentTasks.length}');
  }

  // Método para actualizar la lista de trabajadores seleccionados
  void _updateSelectedWorkers(List<Worker> workers) {
    setState(() {
      _selectedWorkers = workers;
    });
  }

  @override
  Widget build(BuildContext context) {
    _areas = Provider.of<AreasProvider>(context).areas;

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
              // Cabecera del diálogo
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

              // Formulario de asignación
              AssignmentForm(
                zoneController: _zoneController,
                startDateController: _startDateController,
                startTimeController: _startTimeController,
                taskController: _taskController,
                currentTasks: _currentTasks,
                areas: _areas,
                onAreaSelected: _updateTasksForArea,
              ),

              const SizedBox(height: 24),
              // Botones de acción
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

    // Si la validación es exitosa, actualizar el estado de los trabajadores y guardar la asignación
    final workersProvider =
        Provider.of<WorkersProvider>(context, listen: false);

    // Si la validación es exitosa, guardar la asignación
    Provider.of<AssignmentsProvider>(context, listen: false).addAssignment(
      workers: _selectedWorkers,
      area: _zoneController.text,
      task: _taskController.text,
      date: DateFormat('dd/MM/yyyy').parse(_startDateController.text),
      time: _startTimeController.text,
    );

    for (var worker in _selectedWorkers) {
      // Parse the date string properly to create a DateTime object
      DateTime assignmentDate =
          DateFormat('dd/MM/yyyy').parse(_startDateController.text);

      // Asignar fecha final como una semana después
      DateTime endDate = assignmentDate.add(const Duration(days: 7));

      workersProvider.assignWorker(worker, endDate);
    }

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
    showAssignmentSuccessDialog(
      context: context,
      selectedWorkers: _selectedWorkers,
      startDateText: _startDateController.text,
      startTimeText: _startTimeController.text,
      taskText: _taskController.text,
      zoneText: _zoneController.text,
    );
  }
}
