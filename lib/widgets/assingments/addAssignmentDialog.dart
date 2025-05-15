import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/area.dart';
import 'package:plannerop/core/model/client.dart';
import 'package:plannerop/core/model/task.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/store/clients.dart';
import 'package:plannerop/store/task.dart';
import 'package:plannerop/store/user.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/neumophomic.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/assingments/inChargerSelection.dart';
import 'package:provider/provider.dart';
import './selected_worker_list.dart';
import './assignment_form.dart';
import './success_dialog.dart';

class AddAssignmentDialog extends StatefulWidget {
  const AddAssignmentDialog({Key? key}) : super(key: key);

  @override
  State<AddAssignmentDialog> createState() => AddAssignmentDialogState();
}

class AddAssignmentDialogState extends State<AddAssignmentDialog> {
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
  final _chargerController = TextEditingController();
  bool _startDateLockedByGroup = false;
  bool _startTimeLockedByGroup = false;
  bool _endDateLockedByGroup = false;
  bool _endTimeLockedByGroup = false;

  // Lista de trabajadores seleccionados
  List<Worker> _selectedWorkers = [];
  List<WorkerGroup> _selectedGroups = [];

  // Lista completa de trabajadores (datos de ejemplo)
  final List<Worker> _allWorkers = [];

  List<Area> _areas = [];

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
    final _chargerController = TextEditingController();
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

  // Método para procesar los horarios de grupos
  void _processGroupSchedules() {
    if (_selectedGroups.isEmpty) {
      resetGroupScheduleLocks();
      return;
    }
    // Estructura para almacenar fechas y horas completas
    DateTime? earliestStartDateTime;
    DateTime? latestEndDateTime;

    // Procesar cada grupo para encontrar los horarios extremos
    for (var group in _selectedGroups) {
      // 1. Procesar fecha y hora de inicio juntas si ambas existen
      if (group.startDate != null && group.startTime != null) {
        try {
          // Construir un DateTime combinando fecha y hora de inicio
          final dateParts = DateTime.parse(group.startDate!);
          final timeParts = group.startTime!.split(':');
          final hours = int.parse(timeParts[0]);
          final minutes = int.parse(timeParts[1]);

          final combinedStartDateTime = DateTime(
            dateParts.year,
            dateParts.month,
            dateParts.day,
            hours,
            minutes,
          );

          // Actualizar el valor mínimo si corresponde
          if (earliestStartDateTime == null ||
              combinedStartDateTime.isBefore(earliestStartDateTime)) {
            earliestStartDateTime = combinedStartDateTime;
          }
        } catch (e) {
          debugPrint('Error al combinar fecha/hora de inicio: $e');
        }
      }

      // 2. Procesar fecha y hora de fin juntas si ambas existen
      if (group.endDate != null && group.endTime != null) {
        try {
          // Construir un DateTime combinando fecha y hora de fin
          final dateParts = DateTime.parse(group.endDate!);
          final timeParts = group.endTime!.split(':');
          final hours = int.parse(timeParts[0]);
          final minutes = int.parse(timeParts[1]);

          final combinedEndDateTime = DateTime(
            dateParts.year,
            dateParts.month,
            dateParts.day,
            hours,
            minutes,
          );

          // Actualizar el valor máximo si corresponde
          if (latestEndDateTime == null ||
              combinedEndDateTime.isAfter(latestEndDateTime)) {
            latestEndDateTime = combinedEndDateTime;
          }
        } catch (e) {
          debugPrint('Error al combinar fecha/hora de fin: $e');
        }
      }

      // 3. Casos especiales - manejar valores parciales
      // Estos casos son para cuando un grupo solo tiene fecha sin hora o viceversa

      // Caso: Solo fecha de inicio sin hora
      if (group.startDate != null &&
          group.startTime == null &&
          earliestStartDateTime == null) {
        try {
          final startDate = DateTime.parse(group.startDate!);
          // Establecer solo la parte de fecha (hora 00:00)
          if (earliestStartDateTime == null) {
            earliestStartDateTime = DateTime(startDate.year, startDate.month,
                startDate.day, 0, 0 // Hora 00:00 por defecto
                );
          }
        } catch (e) {
          debugPrint('Error al procesar fecha de inicio sin hora: $e');
        }
      }

      // Caso: Solo hora de inicio sin fecha
      if (group.startTime != null &&
          group.startDate == null &&
          earliestStartDateTime == null) {
        try {
          final timeParts = group.startTime!.split(':');
          final hours = int.parse(timeParts[0]);
          final minutes = int.parse(timeParts[1]);

          // Usar la fecha actual con la hora especificada
          final now = DateTime.now();
          final timeOnlyStart =
              DateTime(now.year, now.month, now.day, hours, minutes);

          if (earliestStartDateTime == null) {
            earliestStartDateTime = timeOnlyStart;
          }
        } catch (e) {
          debugPrint('Error al procesar hora de inicio sin fecha: $e');
        }
      }

      // Caso: Solo fecha de fin sin hora
      if (group.endDate != null &&
          group.endTime == null &&
          latestEndDateTime == null) {
        try {
          final endDate = DateTime.parse(group.endDate!);
          // Establecer solo la parte de fecha (hora 23:59)
          if (latestEndDateTime == null) {
            latestEndDateTime = DateTime(endDate.year, endDate.month,
                endDate.day, 23, 59 // Hora 23:59 por defecto para fin del día
                );
          }
        } catch (e) {
          debugPrint('Error al procesar fecha de fin sin hora: $e');
        }
      }

      // Caso: Solo hora de fin sin fecha
      if (group.endTime != null &&
          group.endDate == null &&
          latestEndDateTime == null) {
        try {
          final timeParts = group.endTime!.split(':');
          final hours = int.parse(timeParts[0]);
          final minutes = int.parse(timeParts[1]);

          // Usar la fecha actual con la hora especificada
          final now = DateTime.now();
          final timeOnlyEnd =
              DateTime(now.year, now.month, now.day, hours, minutes);

          if (latestEndDateTime == null) {
            latestEndDateTime = timeOnlyEnd;
          }
        } catch (e) {
          debugPrint('Error al procesar hora de fin sin fecha: $e');
        }
      }
    }

    // Actualizar los controladores con los valores encontrados
    setState(() {
      // Procesar fecha y hora de inicio
      if (earliestStartDateTime != null) {
        // Fecha de inicio
        _startDateController.text =
            DateFormat('dd/MM/yyyy').format(earliestStartDateTime);
        _startDateLockedByGroup = true;

        // Hora de inicio
        final hour = earliestStartDateTime.hour.toString().padLeft(2, '0');
        final minute = earliestStartDateTime.minute.toString().padLeft(2, '0');
        _startTimeController.text = '$hour:$minute';
        _startTimeLockedByGroup = true;
      } else {
        _startDateLockedByGroup = false;
        _startTimeLockedByGroup = false;
      }

      // Procesar fecha y hora de fin
      if (latestEndDateTime != null) {
        // Fecha de fin
        _endDateController.text =
            DateFormat('dd/MM/yyyy').format(latestEndDateTime);
        _endDateLockedByGroup = true;

        // Hora de fin
        final hour = latestEndDateTime.hour.toString().padLeft(2, '0');
        final minute = latestEndDateTime.minute.toString().padLeft(2, '0');
        _endTimeController.text = '$hour:$minute';
        _endTimeLockedByGroup = true;
      } else {
        _endDateLockedByGroup = false;
        _endTimeLockedByGroup = false;
      }
    });
  }

// Método para resetear los bloqueos
  void resetGroupScheduleLocks() {
    setState(() {
      // Desbloquear campos
      _startDateLockedByGroup = false;
      _startTimeLockedByGroup = false;
      _endDateLockedByGroup = false;
      _endTimeLockedByGroup = false;

      // Limpiar valores de fecha y hora de finalización
      // Para inicio, mantener la fecha y hora actuales como valores por defecto
      if (_endDateController.text.isNotEmpty ||
          _endTimeController.text.isNotEmpty) {
        _endDateController.text = '';
        _endTimeController.text = '';
      }

      // Para fecha y hora de inicio, establecer valores predeterminados si están vacíos
      if (_startDateController.text.isEmpty) {
        _startDateController.text =
            DateFormat('dd/MM/yyyy').format(DateTime.now());
      }

      if (_startTimeController.text.isEmpty) {
        _startTimeController.text = DateFormat('HH:mm').format(DateTime.now());
      }

      // debugPrint(
      //     'Horarios desbloqueados y reiniciados - Se eliminaron todos los grupos');
    });
  }

  // Método para cargar tareas desde el API
  Future<void> _loadTasks() async {
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
      showAlertToast(context, 'Error al cargar las tareas');
    } finally {}
  }

  // Método para actualizar la lista de trabajadores seleccionados
  void _updateSelectedWorkers(List<Worker> workers) {
    setState(() {
      _selectedWorkers = workers;
    });
    // _processGroupSchedules();
  }

// Método para actualizar grupos, agregar este método
  void updateSelectedGroups(List<WorkerGroup> groups) {
    setState(() {
      _selectedGroups = groups;
    });

    // Procesar horarios de grupos cuando cambian los grupos
    _processGroupSchedules();
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
                selectedGroups: _selectedGroups,
                onGroupsChanged: updateSelectedGroups,
              ),
              const SizedBox(height: 12),

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
                startDateLocked: _startDateLockedByGroup,
                startTimeLocked: _startTimeLockedByGroup,
                endDateLocked: _endDateLockedByGroup,
                endTimeLocked: _endTimeLockedByGroup,
              ),

              const SizedBox(height: 24),

              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: MultiChargerSelectionField(
                  controller: _chargerController,
                ),
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
                    style: neumorphicButtonStyle(
                      color: _isSaving
                          ? const Color(0xFF90CDF4)
                          : const Color.fromARGB(255, 248, 248, 248),
                      depth: _isSaving ? 0 : 2,
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

    // Validación para campo encargados
    if (_chargerController.text.isEmpty) {
      showAlertToast(context, 'Por favor, selecciona al menos un encargado');
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

      zoneNum = _zoneController.text.isEmpty == true ? 0 : zoneNum;

      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // ID del usuario actual
      final userId = userProvider.user.id;
// Dentro del método _validateFields, modifica cómo se procesan los chargerIds:

// Obtener los IDs de encargados del controlador
      List<int> chargerIds = [];
      if (_chargerController.text.isNotEmpty) {
        try {
          // El controlador contiene IDs separados por coma
          final chargerIdStrings = _chargerController.text.split(',');
          for (String idStr in chargerIdStrings) {
            if (idStr.trim().isNotEmpty) {
              final parsedId = int.parse(idStr.trim());
              if (parsedId > 0) {
                chargerIds.add(parsedId);
              }
            }
          }

          // Asegurarse de que los IDs estén impresos para debug
          // debugPrint('Encargados seleccionados IDs: $chargerIds');
        } catch (e) {
          // En caso de error, ignorar pero imprimir
          debugPrint('Error al procesar IDs de encargados: $e');
          debugPrint('Texto en controller: ${_chargerController.text}');
        }
      }

      // debugPrint('Datos de la asignación: $zoneNum');
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
        chargerIds: chargerIds,
        context: context, // Pasar el contexto para el token
        groups: _selectedGroups,
      );

      // Si hubo error al guardar
      if (!success) {
        showValidationError(context,
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
      showValidationError(context, 'Error al procesar los datos: $e');
      return false;
    }
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
