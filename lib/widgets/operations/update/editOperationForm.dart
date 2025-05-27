import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/core/model/client.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/clients.dart';
import 'package:plannerop/store/operations.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/operations.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/operations/components/utils/dateField.dart';
import 'package:plannerop/widgets/operations/components/workers/selected_worker_list.dart';
import 'package:plannerop/widgets/operations/components/utils/timeField.dart';
import 'package:provider/provider.dart';

class EditOperationForm extends StatefulWidget {
  final Operation assignment;
  final Function(Operation) onSave;
  final VoidCallback onCancel;

  const EditOperationForm({
    Key? key,
    required this.assignment,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  EditOperationFormState createState() => EditOperationFormState();
}

class EditOperationFormState extends State<EditOperationForm> {
  // Controladores
  late TextEditingController _areaController;
  late TextEditingController _taskController;
  late TextEditingController _startDateController;
  late TextEditingController _startTimeController;
  late TextEditingController _endDateController;
  late TextEditingController _endTimeController;
  late TextEditingController _zoneController;
  late TextEditingController _motorshipController;
  late TextEditingController _clientController;

  // Estado de la edición
  late List<Worker> _selectedWorkers;
  bool _isShipArea = false;
  late List<WorkerGroup> _selectedGroups;

  // Contadores para forzar la reconstrucción de los campos de fecha/hora
  final int _dateUpdateCounter = 0;
  int _timeUpdateCounter = 0;
  final int _endDateUpdateCounter = 0;
  int _endTimeUpdateCounter = 0;
  @override
  void initState() {
    super.initState();

    // Inicializar grupos desde la operación existente
    _selectedGroups = List.from(widget.assignment.groups);

    // Inicializar controladores con los datos de la operación
    _areaController = TextEditingController(text: widget.assignment.area);
    // _taskController = TextEditingController(text: widget.assignment.task);
    _startDateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(widget.assignment.date),
    );
    _startTimeController = TextEditingController(text: widget.assignment.time);
    _endDateController = TextEditingController(
      text: widget.assignment.endDate != null
          ? DateFormat('dd/MM/yyyy').format(widget.assignment.endDate!)
          : '',
    );
    _endTimeController = TextEditingController(
      text: widget.assignment.endTime ?? '',
    );
    _zoneController =
        TextEditingController(text: 'Zona ${widget.assignment.zone}');
    _motorshipController = TextEditingController(
      text: widget.assignment.motorship ?? '',
    );
    _clientController = TextEditingController();

    // Inicializar trabajadores seleccionados
    // _selectedWorkers = List.from(widget.assignment.workers);

    // Verificar si es un área de barco
    _checkIfShipArea(widget.assignment.area);

    // Buscar el nombre del cliente después del build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeClientName();

      // IMPORTANTE: Forzar sincronización de grupos al inicializar
      if (_selectedGroups.isNotEmpty) {
        _processGroupSchedules();
      }
    });
  }

  void _initializeClientName() {
    final clientsProvider =
        Provider.of<ClientsProvider>(context, listen: false);
    final client = clientsProvider.getClientById(widget.assignment.clientId);
    if (client != null) {
      _clientController.text = client.name;
    }
  }

  void _checkIfShipArea(String area) {
    setState(() {
      _isShipArea = area.toUpperCase().contains('BUQUE');
    });
  }

  void _handleDateChanged(String date) {
    setState(() {
      _timeUpdateCounter++;
    });
  }

  void _handleEndDateChanged(String date) {
    setState(() {
      _endTimeUpdateCounter++;
    });
  }

  @override
  void dispose() {
    _areaController.dispose();
    _taskController.dispose();
    _startDateController.dispose();
    _startTimeController.dispose();
    _endDateController.dispose();
    _endTimeController.dispose();
    _zoneController.dispose();
    _motorshipController.dispose();
    _clientController.dispose();
    super.dispose();
  }

  // Dentro de la clase _EditAssignmentFormState, modifica el método build()

  @override
  Widget build(BuildContext context) {
    final clientsProvider = Provider.of<ClientsProvider>(context);
    final workersProvider = Provider.of<WorkersProvider>(context);

    var client = clientsProvider.getClientById(widget.assignment.clientId);
    client ??=
        Client(id: widget.assignment.clientId, name: "Cliente no encontrado");

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3182CE).withValues(alpha: .1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Editar Asignación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
          ),

          // Formulario
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de trabajadores con soporte para grupos
                  SelectedWorkersList(
                    selectedWorkers: _selectedWorkers,
                    selectedGroups: _selectedGroups,
                    availableWorkers: workersProvider.getWorkersAvailable(),
                    onWorkersChanged: (workers) {
                      setState(() {
                        _selectedWorkers = workers;
                      });
                    },
                    onGroupsChanged: (groups) {
                      setState(() {
                        _selectedGroups = groups;
                        // Al cambiar grupos, procesar las fechas y horas
                        _processGroupSchedules();
                      });
                    },
                    inEditMode: true, // Indicar que estamos en modo edición
                    deletedWorkers: widget.assignment.deletedWorkers,
                    onDeletedWorkersChanged: (deletedWorkers) {
                      setState(() {
                        widget.assignment.deletedWorkers = deletedWorkers;
                      });
                    },
                    // Agregar esta línea para sincronizar _workerGroups con selectedGroups
                    initialGroups: _selectedGroups,
                    assignmentId: widget.assignment.id,
                  ),

                  const SizedBox(height: 20),

                  // Campo de área (NO editable)
                  buildNonEditableField(
                    label: 'Área',
                    value: widget.assignment.area,
                    icon: Icons.location_on_outlined,
                  ),

                  // Campo de motonave (editable solo si es área de buque)
                  if (_isShipArea)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextFormField(
                        controller: _motorshipController,
                        decoration: InputDecoration(
                          labelText: 'Nombre de Motonave',
                          prefixIcon: const Icon(Icons.directions_boat),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                  // Campos de fecha y hora de inicio (editables)
                  DateField(
                    label: 'Fecha de inicio',
                    hint: 'DD/MM/AAAA',
                    icon: Icons.calendar_today_outlined,
                    controller: _startDateController,
                    onDateChanged: _handleDateChanged,
                    key: ValueKey('date_field_$_dateUpdateCounter'),
                  ),

                  TimeField(
                    label: 'Hora de inicio',
                    hint: 'HH:MM',
                    icon: Icons.schedule_outlined,
                    controller: _startTimeController,
                    dateController: _startDateController,
                    key: ValueKey(
                        'time_field_${_dateUpdateCounter}_$_timeUpdateCounter'),
                  ),

                  // Divider para campos opcionales
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "FINALIZACIÓN (OPCIONAL)",
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                  ),

                  // Campos opcionales de fecha y hora de finalización (editables)
                  DateField(
                    label: 'Fecha de finalización',
                    hint: 'DD/MM/AAAA',
                    icon: Icons.event_outlined,
                    controller: _endDateController,
                    onDateChanged: _handleEndDateChanged,
                    key: ValueKey('end_date_field_$_endDateUpdateCounter'),
                    isOptional: true,
                  ),

                  TimeField(
                    label: 'Hora de finalización',
                    hint: 'HH:MM',
                    icon: Icons.access_time_outlined,
                    controller: _endTimeController,
                    dateController: _endDateController,
                    key: ValueKey(
                        'end_time_field_${_endDateUpdateCounter}_$_endTimeUpdateCounter'),
                    isOptional: true,
                  ),

                  // // Campo de tarea/servicio (NO editable)
                  // buildNonEditableField(
                  //   label: 'Servicio',
                  //   value: widget.assignment.task,
                  //   icon: Icons.assignment_outlined,
                  // ),

                  // Campo de zona (NO editable)
                  buildNonEditableField(
                    label: 'Zona',
                    value: 'Zona ${widget.assignment.zone}',
                    icon: Icons.grid_view_outlined,
                  ),

                  // Campo de cliente (NO editable)
                  buildNonEditableField(
                    label: 'Cliente',
                    value: client.name,
                    icon: Icons.person_outline,
                  ),
                ],
              ),
            ),
          ),

          // Botones de acción
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: 2,
                    intensity: 0.7,
                    color: const Color(0xFF718096),
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                  ),
                  onPressed: widget.onCancel,
                  child: const Text(
                    'Cancelar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: 2,
                    intensity: 0.7,
                    color: const Color(0xFF3182CE),
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                  ),
                  onPressed: () => _saveChanges(context),
                  child: const Text(
                    'Guardar Cambios',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _processGroupSchedules() {
    if (_selectedGroups.isEmpty) {
      // Si no hay grupos, dejar los campos editables
      return;
    }

    // Estructura para almacenar fechas y horas completas
    DateTime? earliestStartDateTime;
    DateTime? latestEndDateTime;

    // Procesar cada grupo para encontrar los horarios extremos
    for (var group in _selectedGroups) {
      // Procesar fecha y hora de inicio juntas si ambas existen
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

      // Procesar fecha y hora de fin juntas si ambas existen
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
    }

    // Actualizar los controladores con los valores encontrados
    setState(() {
      // Actualizar fecha y hora de inicio si se encontraron
      if (earliestStartDateTime != null) {
        _startDateController.text =
            DateFormat('dd/MM/yyyy').format(earliestStartDateTime);

        final hour = earliestStartDateTime.hour.toString().padLeft(2, '0');
        final minute = earliestStartDateTime.minute.toString().padLeft(2, '0');
        _startTimeController.text = '$hour:$minute';
      }

      // Actualizar fecha y hora de fin si se encontraron
      if (latestEndDateTime != null) {
        _endDateController.text =
            DateFormat('dd/MM/yyyy').format(latestEndDateTime);

        final hour = latestEndDateTime.hour.toString().padLeft(2, '0');
        final minute = latestEndDateTime.minute.toString().padLeft(2, '0');
        _endTimeController.text = '$hour:$minute';
      }
    });
  }

  void _saveChanges(BuildContext context) {
    try {
      // Validaciones
      if (_selectedWorkers.isEmpty) {
        _showValidationError('Por favor, selecciona al menos un trabajador');
        return;
      }

      if (_startDateController.text.isEmpty) {
        _showValidationError('Por favor, selecciona una fecha de inicio');
        return;
      }

      if (_startTimeController.text.isEmpty) {
        _showValidationError('Por favor, selecciona una hora de inicio');
        return;
      }

      // Validación para motonave en área de buque
      if (_isShipArea && _motorshipController.text.isEmpty) {
        _showValidationError('Por favor, ingresa el nombre de la motonave');
        return;
      }

      // Obtener providers
      final workersProvider =
          Provider.of<WorkersProvider>(context, listen: false);
      final assignmentsProvider =
          Provider.of<OperationsProvider>(context, listen: false);

      // Procesar fecha y hora
      final startDate =
          DateFormat('dd/MM/yyyy').parse(_startDateController.text);

      // Procesar fecha y hora de fin
      DateTime? endDate;
      if (_endDateController.text.isNotEmpty) {
        endDate = DateFormat('dd/MM/yyyy').parse(_endDateController.text);
      }

      // Identificar trabajadores agregados y removidos para actualizar su estado
      final List<Worker> addedWorkers = [];
      final List<Worker> removedWorkers = [];

      // // Encontrar trabajadores que se añadieron (están en selectedWorkers pero no en assignment.workers)
      // for (var worker in _selectedWorkers) {
      //   if (!widget.assignment.workers.any((w) => w.id == worker.id)) {
      //     addedWorkers.add(worker);
      //   }
      // }

      // // Encontrar trabajadores que se quitaron (están en assignment.workers pero no en selectedWorkers)
      // for (var worker in widget.assignment.workers) {
      //   if (!_selectedWorkers.any((w) => w.id == worker.id)) {
      //     removedWorkers.add(worker);
      //   }
      // }

      List<int> individualWorkerIds = [];
      List<Map<String, dynamic>> groupsToConnect = [];

      // Separar trabajadores individuales de los grupos
      for (var worker in addedWorkers) {
        // Verificar si el trabajador pertenece a algún grupo
        bool isInGroup = false;

        for (var group in _selectedGroups) {
          if (group.workers.contains(worker.id)) {
            isInGroup = true;
            break;
          }
        }

        // Si no está en ningún grupo, añadirlo como individual
        if (!isInGroup) {
          individualWorkerIds.add(worker.id);
        }
      }

      // Procesar los grupos nuevos para el API
      for (var group in _selectedGroups) {
        // Verificar si es un grupo nuevo (no estaba en la operación original)
        bool isNewGroup = true;
        for (var originalGroup in widget.assignment.groups) {
          if (originalGroup.id == group.id) {
            isNewGroup = false;
            break;
          }
        }

        if (isNewGroup) {
          // Filtrar trabajadores que ya están añadidos individualmente
          List<int> groupWorkerIds = group.workers
              .where((id) => !individualWorkerIds.contains(id))
              .toList();

          if (groupWorkerIds.isNotEmpty) {
            groupsToConnect.add({
              "workerIds": groupWorkerIds,
              "dateStart": group.startDate,
              "dateEnd": group.endDate,
              "timeStart": group.startTime,
              "timeEnd": group.endTime
            });
          }
        }
      }

      // Actualizar estados de los trabajadores
      for (var worker in addedWorkers) {
        workersProvider.assignWorkerObject(worker, context);
      }

      // TODO VERIFICAR ESTO EN EL BACKEND
      // for (var worker in removedWorkers) {
      //   workersProvider.releaseWorkerObject(worker, context);
      // }

      // Crear la operación actualizada con los valores editables
      final updatedAssignment = Operation(
        id: widget.assignment.id,
        // workers: _selectedWorkers,
        area: widget.assignment.area, // No editable
        // task: widget.assignment.task, // No editable
        date: startDate, // Editable
        time: _startTimeController.text, // Editable
        zone: widget.assignment.zone, // No editable
        status: widget.assignment.status, // No editable por este formulario
        endDate: endDate, // Editable
        endTime: _endTimeController.text.isNotEmpty
            ? _endTimeController.text
            : null, // Editable
        motorship: _isShipArea
            ? _motorshipController.text
            : null, // Editable si es área de buque
        userId: widget.assignment.userId, // No editable
        areaId: widget.assignment.areaId, // No editable
        // taskId: widget.assignment.taskId, // No editable
        clientId: widget.assignment.clientId, // No editable
        deletedWorkers:
            widget.assignment.deletedWorkers, // Include deleted workers
        inChagers: widget.assignment.inChagers,
        groups: _selectedGroups, // Añadir los grupos seleccionados
        id_clientProgramming:
            widget.assignment.id_clientProgramming, // No editable
      );
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Si hay trabajadores para conectar, llamar a la nueva función
      if (individualWorkerIds.isNotEmpty || groupsToConnect.isNotEmpty) {
        assignmentsProvider
            .connectWorkersToAssignment(individualWorkerIds, groupsToConnect,
                context, widget.assignment.id!)
            .then((success) {
          if (!success) {
            showErrorToast(
                context, "Hubo un error al conectar nuevos trabajadores");
          }
        });
      }

      // Llamar al callback con la operación actualizada
      widget.onSave(updatedAssignment);
    } catch (e) {
      debugPrint('Error al guardar cambios: $e');
      _showValidationError('Ha ocurrido un error al guardar los cambios');
    }
  }

  void _showValidationError(String message) {
    showErrorToast(context, message);
  }
}

// Función global para mostrar el formulario de edición como modal bottom sheet
Future<void> showEditAssignmentForm(
  BuildContext context,
  Operation assignment,
) async {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final assignmentsProvider =
          Provider.of<OperationsProvider>(context, listen: false);

      return EditOperationForm(
        assignment: assignment,
        onSave: (updatedAssignment) async {
          // Cerrar el formulario primero
          Navigator.pop(context);

          // Mostrar indicador de carga
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          try {
            // Actualizar la operación
            final success = await assignmentsProvider.updateAssignment(
              updatedAssignment,
              context,
            );

            // Cerrar indicador de carga
            Navigator.pop(context);

            if (success) {
              showSuccessToast(context, 'Asignación actualizada correctamente');
            } else {
              showErrorToast(context, 'No se pudo actualizar la operación');
            }
          } catch (e) {
            // Cerrar indicador de carga si hay error
            Navigator.pop(context);

            showErrorToast(
                context, 'Ha ocurrido un error al actualizar la operación');
          }
        },
        onCancel: () {
          Navigator.pop(context);
        },
      );
    },
  );
}
