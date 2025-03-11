import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/area.dart';
import 'package:plannerop/core/model/client.dart';
import 'package:plannerop/core/model/task.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/store/clients.dart';
import 'package:plannerop/store/task.dart';
import 'package:plannerop/store/user.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:provider/provider.dart';
import './selected_worker_list.dart';
import './assignment_form.dart';
import './success_dialog.dart';

class AddAssignmentDialog extends StatefulWidget {
  const AddAssignmentDialog({Key? key}) : super(key: key);

  @override
  State<AddAssignmentDialog> createState() => _AddAssignmentDialogState();
}

class _AddAssignmentDialogState extends State<AddAssignmentDialog> {
  // Controladores para los campos de texto
  final _areaController = TextEditingController();
  final _startDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _taskController = TextEditingController();
  final _zoneController = TextEditingController();
  final _clientController = TextEditingController();
  final _endDateController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _motorshipController = TextEditingController();

  // Lista de trabajadores seleccionados
  List<Worker> _selectedWorkers = [];

  // Lista completa de trabajadores (datos de ejemplo)
  final List<Worker> _allWorkers = [];

  List<Area> _areas = [];

  // Boolean para controlar si estamos cargando las tareas
  bool _isLoadingTasks = false;

  // Ahora usaremos TasksProvider para obtener la lista de tareas
  List<String> _currentTasks = [];

  List<Client> _clients = [];

  // variable para controlar el estado de carga
  bool _isSaving = false;

  @override
  void dispose() {
    _areaController.dispose();
    _startDateController.dispose();
    _startTimeController.dispose();
    final _taskController = TextEditingController();
    final _zoneController = TextEditingController();
    final _clientController = TextEditingController();
    final _endDateController = TextEditingController();
    final _endTimeController = TextEditingController();
    // Nuevo controlador para el nombre de la motonave
    final _motorshipController = TextEditingController();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Establecer la fecha y hora actuales por defecto
    _startDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _startTimeController.text = DateFormat('HH:mm').format(DateTime.now());
    // Cargar tareas cuando se inicia el diálogo
    _loadTasks();
  }

  // Método para cargar tareas desde el API
  Future<void> _loadTasks() async {
    setState(() {
      _isLoadingTasks = true;
    });

    try {
      final tasksProvider = Provider.of<TasksProvider>(context, listen: false);

      // Intentar cargar si aún no se ha hecho
      if (!tasksProvider.hasAttemptedLoading) {
        await tasksProvider.loadTasksIfNeeded(context);
      }

      // Actualizar la lista local con los nombres de tareas
      // Ahora siempre tendremos tareas (predeterminadas o de API)
      setState(() {
        _currentTasks = tasksProvider.taskNames;
      });
    } catch (e) {
      debugPrint('Error al cargar tareas: $e');

      // En caso de error, usar lista predeterminada
      setState(() {
        _currentTasks = [];
      });

      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar tareas: Usando lista predeterminada'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTasks = false;
        });
      }
    }
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
    _clients = Provider.of<ClientsProvider>(context).clients;

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
                areaController: _areaController,
                startDateController: _startDateController,
                startTimeController: _startTimeController,
                taskController: _taskController,
                currentTasks: _currentTasks,
                zoneController: _zoneController,
                clientController: _clientController,
                areas: _areas,
                clients: _clients,
                endDateController: _endDateController,
                endTimeController: _endTimeController,
                showEndDateTime: true,
                motorshipController: _motorshipController,
              ),

              const SizedBox(height: 24),
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  NeumorphicButton(
                    style: NeumorphicStyle(
                      depth: _isSaving ? 0 : 2,
                      intensity: 0.6,
                      color: _isSaving
                          ? const Color(
                              0xFF90CDF4) // Color más claro cuando está guardando
                          : const Color.fromARGB(255, 248, 248, 248),
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
                    onPressed: _isSaving
                        ? null
                        : () async {
                            // Cambiar al estado de carga
                            setState(() {
                              _isSaving = true;
                            });

                            // Validar los campos antes de continuar
                            final isValid = await _validateFields(context);

                            // Si la validación falló, volver al estado normal
                            if (!isValid) {
                              setState(() {
                                _isSaving = false;
                              });
                              return;
                            }

                            // Si todo salió bien, cerrar el diálogo y mostrar éxito
                            Navigator.of(context).pop();
                            _showSuccessDialog(context);
                          },
                    child: Container(
                      width: 100, // Ancho fijo para evitar cambios de tamaño
                      child: Center(
                        child: _isSaving
                            // Mostrar indicador de progreso mientras guarda
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Guardando',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            // Mostrar texto normal cuando no está guardando
                            : const Text(
                                'Guardar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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

  Future<bool> _validateFields(BuildContext context) async {
    // Validaciones existentes
    if (_selectedWorkers.isEmpty) {
      showAlertToast(context, 'Por favor, selecciona al menos un trabajador');
      return false;
    }

    if (_areaController.text.isEmpty) {
      showAlertToast(context, 'Por favor, selecciona un área');
      return false;
    }

    if (_startDateController.text.isEmpty) {
      showAlertToast(context, 'Por favor, selecciona una fecha de inicio');
      return false;
    }

    if (_startTimeController.text.isEmpty) {
      showAlertToast(context, 'Por favor, selecciona una hora de inicio');
      return false;
    }

    if (_taskController.text.isEmpty) {
      showAlertToast(context, 'Por favor, selecciona una tarea');
      return false;
    }

    if (_zoneController.text.isEmpty) {
      showAlertToast(context, 'Por favor, selecciona una zona');
      return false;
    }

    if (_clientController.text.isEmpty) {
      showAlertToast(context, 'Por favor, selecciona un cliente');
      return false;
    }

    // Validación para el campo de motonave cuando el área es BUQUE
    if (_areaController.text.toUpperCase() == 'BUQUE' &&
        _motorshipController.text.isEmpty) {
      showAlertToast(context, 'Por favor, ingresa el nombre de la motonave');
      return false;
    }

    try {
      // Obtener proveedores
      final workersProvider =
          Provider.of<WorkersProvider>(context, listen: false);
      final areasProvider = Provider.of<AreasProvider>(context, listen: false);
      final tasksProvider = Provider.of<TasksProvider>(context, listen: false);
      final assignmentsProvider =
          Provider.of<AssignmentsProvider>(context, listen: false);

      // Parsear fecha de inicio
      final startDate =
          DateFormat('dd/MM/yyyy').parse(_startDateController.text);

      // Parsear fecha de fin si está presente
      DateTime? endDate;
      if (_endDateController.text.isNotEmpty) {
        endDate = DateFormat('dd/MM/yyyy').parse(_endDateController.text);
      }

      // Extraer IDs de las entidades seleccionadas
      final selectedArea = areasProvider.areas.firstWhere(
          (area) => area.name == _areaController.text,
          orElse: () => Area(
              id: 0,
              name: _areaController.text) // Área por defecto si no se encuentra
          );

      // Encontrar ID de la tarea seleccionada
      int taskId = 1; // Valor por defecto
      final selectedTask = tasksProvider.tasks.firstWhere(
          (task) => task.name == _taskController.text,
          orElse: () => Task(
              id: 1,
              name:
                  _taskController.text) // Tarea por defecto si no se encuentra
          );

      taskId = selectedTask.id;

      var clientsProvider =
          Provider.of<ClientsProvider>(context, listen: false);

      // Extraer ID del cliente
      int clientId = clientsProvider.clients
          .firstWhere((client) => client.name == _clientController.text,
              orElse: () => Client(
                  id: 1,
                  name: _clientController
                      .text) // Cliente por defecto si no se encuentra
              )
          .id;

      // Obtener zona numéricamente
      int zoneNum = 1; // Por defecto
      final zoneText = _zoneController.text;
      if (zoneText.startsWith('Zona ')) {
        zoneNum = int.tryParse(zoneText.substring(5)) ?? 1;
      }

      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // ID del usuario actual
      final userId = userProvider.user.id ?? 1;

      // Si la validación es exitosa, guardar la asignación
      final success = await assignmentsProvider.addAssignment(
        workers: _selectedWorkers,
        area: _areaController.text,
        areaId: selectedArea.id,
        task: _taskController.text,
        taskId: taskId,
        date: startDate,
        time: _startTimeController.text,
        zoneId: zoneNum,
        userId: userId,
        clientId: clientId,
        clientName: _clientController.text,
        endDate: endDate,
        endTime:
            _endTimeController.text.isNotEmpty ? _endTimeController.text : null,
        motorship: _areaController.text.toUpperCase() == 'BUQUE'
            ? _motorshipController.text
            : null,
        context: context, // Pasar el contexto para el token
      );

      // Si hubo error al guardar
      if (!success) {
        _showValidationError(
            'Error al guardar la asignación: ${assignmentsProvider.error}');
        return false;
      }

      // Actualizar estado de los trabajadores
      for (var worker in _selectedWorkers) {
        // Asignar fecha final como una semana después o usar la fecha proporcionada
        DateTime workerEndDate =
            endDate ?? startDate.add(const Duration(days: 7));
        workersProvider.assignWorker(worker, workerEndDate);
      }

      return true;
    } catch (e) {
      debugPrint('Error en _validateFields: $e');
      _showValidationError('Error al procesar los datos: $e');
      return false;
    }
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
