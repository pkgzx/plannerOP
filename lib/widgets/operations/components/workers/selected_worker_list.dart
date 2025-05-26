import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/task.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/store/workerGroup.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/utils/worker_utils.dart';
import 'package:plannerop/widgets/operations/update/editOperationForm.dart';
import 'package:plannerop/widgets/operations/components/workers/groupDialogs.dart';
import 'package:provider/provider.dart';
import 'worker_selection_dialog.dart';
import 'package:plannerop/widgets/operations/add/addOperationDialog.dart'
    show AddOperationDialogState;

class SelectedWorkersList extends StatefulWidget {
  // Lista de trabajadores seleccionados
  final List<Worker> selectedWorkers;
  final List<WorkerGroup> selectedGroups;

  // Función de callback cuando cambia la selección
  final Function(List<Worker>) onWorkersChanged;

  final Function(List<WorkerGroup>)? onGroupsChanged;
  // Modo edición
  final bool inEditMode;

  // Lista de trabajadores eliminados en modo edición
  final List<Worker> deletedWorkers;

  // Callback para actualizar la lista de trabajadores eliminados
  final Function(List<Worker>)? onDeletedWorkersChanged;

  // Todos los trabajadores disponibles (para el diálogo de selección)
  final List<Worker> availableWorkers;

  final List<WorkerGroup>? initialGroups;
  final int? assignmentId;

  const SelectedWorkersList({
    Key? key,
    required this.selectedWorkers,
    required this.selectedGroups,
    required this.onWorkersChanged,
    required this.availableWorkers,
    required this.onGroupsChanged,
    this.inEditMode = false,
    this.deletedWorkers = const [],
    this.onDeletedWorkersChanged,
    this.initialGroups,
    this.assignmentId,
  }) : super(key: key);

  @override
  State<SelectedWorkersList> createState() => _SelectedWorkersListState();
}

class _SelectedWorkersListState extends State<SelectedWorkersList> {
  // Mapa para almacenar las horas trabajadas por cada trabajador
  Map<int, double> _workerHours = {};

  // Lista de trabajadores disponibles filtrados
  List<Worker> _filteredWorkers = [];

  // Indicador de carga
  bool _isCalculatingHours = false;

  // Lista de grupos de trabajadores
  List<WorkerGroup> _workerGroups = [];

  @override
  void initState() {
    super.initState();
    // Inicializar _workerGroups con los grupos iniciales si existen
    if (widget.initialGroups != null && widget.initialGroups!.isNotEmpty) {
      _workerGroups = List.from(widget.initialGroups!);
    }
    _calculateWorkerHours();
  }

  // Calcular horas trabajadas para todos los trabajadores
  Future<void> _calculateWorkerHours() async {
    setState(() {
      _isCalculatingHours = true;
    });

    final assignmentsProvider =
        Provider.of<AssignmentsProvider>(context, listen: false);
    final workersProvider =
        Provider.of<WorkersProvider>(context, listen: false);

    final completedAssignments = assignmentsProvider
        .completedAssignments // last 2 days
        .where((assignment) =>
            assignment.date.isAfter(DateTime.now().subtract(Duration(days: 2))))
        .toList();

    // final availableWorkers = workersProvider.getWorkersAvailable();
    final availableWorkers = workersProvider.workersWithoutRetiredAndDisabled;

    // Mapa para acumular las horas por trabajador
    Map<int, double> hoursMap = {};

    // Procesar todas las asignaciones completadas
    for (var assignment in completedAssignments) {
      // Ignorar asignaciones futuras o de hace más de un día
      if (assignment.date.isAfter(DateTime.now()) ||
          assignment.date
              .isBefore(DateTime.now().subtract(Duration(days: 1)))) {
        continue;
      }

      if (assignment.endDate != null && assignment.endTime != null) {
        // Calcular la duración de esta operación
        final double assignmentHours = _calculateAssignmentDuration(assignment);

        debugPrint(
            'Assignment ${assignment.id} duration: $assignmentHours hours');

        // // Asignar estas horas a cada trabajador de la operación
        // for (var worker in assignment.workers) {
        //   if (hoursMap.containsKey(worker.id)) {
        //     hoursMap[worker.id] = (hoursMap[worker.id] ?? 0) + assignmentHours;
        //   } else {
        //     hoursMap[worker.id] = assignmentHours;
        //   }
        // }
      }
    }

    debugPrint('Total hours calculated: ${hoursMap.length}');

    final filteredWorkers =
        availableWorkers; // Usar todos los trabajadores sin filtrar por horas

    // Filtrar trabajadores disponibles que tengan menos de 12 horas trabajadas
    // final filteredWorkers = availableWorkers.where((worker) {
    //   // Si el trabajador no está en el mapa o tiene menos de 12 horas, está disponible
    //   return !hoursMap.containsKey(worker.id) ||
    //       (hoursMap[worker.id] ?? 0) < 12.0;
    // }).toList();

    debugPrint('Filtered workers2: ${filteredWorkers.length}');

    final Set<int> selectedWorkerIds =
        widget.selectedWorkers.map((w) => w.id).toSet();

    // Trabajadores que no están seleccionados ni en grupos
    final availableForSelection = filteredWorkers.where((worker) {
      return !_isWorkerInAnyGroup(worker) &&
          !selectedWorkerIds.contains(worker.id);
    }).toList();

    /* TODO depronto mas tarde volver a habilitar lo de que no puede estar en dos operaciones*/

    setState(() {
      _workerHours = hoursMap;
      _filteredWorkers = filteredWorkers;
      _isCalculatingHours = false;
    });
  }

  // Calcular la duración de una operación en horas
  double _calculateAssignmentDuration(Operation assignment) {
    if (assignment.endDate == null || assignment.endTime == null) {
      return 0.0;
    }

    // Obtener hora de inicio
    final startTimeParts = assignment.time.split(':');
    final startDateTime = DateTime(
      assignment.date.year,
      assignment.date.month,
      assignment.date.day,
      int.parse(startTimeParts[0]),
      int.parse(startTimeParts[1]),
    );

    // Obtener hora de fin
    final endTimeParts = assignment.endTime!.split(':');
    final endDateTime = DateTime(
      assignment.endDate!.year,
      assignment.endDate!.month,
      assignment.endDate!.day,
      int.parse(endTimeParts[0]),
      int.parse(endTimeParts[1]),
    );

    debugPrint("Start: $startDateTime, End: $endDateTime");

    // Calcular diferencia en horas
    final difference = endDateTime.difference(startDateTime);
    final fmtDiff = difference.inMinutes / 60.0;
    final unsignedDiif = fmtDiff.abs();
    return unsignedDiif > 0 ? unsignedDiif : 0.0;
  }

  // Abrir diálogo para seleccionar trabajadores
  Future<void> _openWorkerSelectionDialog() async {
    // Recalcular horas antes de abrir el diálogo
    await _calculateWorkerHours();

    final result = await showDialog<List<Worker>>(
      context: context,
      builder: (context) => WorkerSelectionDialog(
        selectedWorkers: widget.selectedWorkers,
        availableWorkers: _filteredWorkers,
        workerHours: _workerHours,
        title: 'Seleccionar trabajadores',
        allSelectedWorkers: widget.selectedWorkers,
      ),
    );

    if (result != null) {
      // Notificar al padre directamente sobre el cambio
      widget.onWorkersChanged(result);

      // Importante: NO llamar a onGroupsChanged aquí para evitar
      // que se procesen los horarios de grupo para trabajadores individuales

      // También forzar el reseteo de los bloqueos de horario en el diálogo principal
      final addAssignmentDialog =
          context.findAncestorStateOfType<AddOperationDialogState>();

      if (addAssignmentDialog != null) {
        addAssignmentDialog.resetGroupScheduleLocks();
      }

      // DEBUG - verificación
      debugPrint(
          'Trabajadores seleccionados individualmente. Horarios desbloqueados.');
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Añadir trabajadores',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF3182CE),
                    child:
                        Icon(Icons.person_add, color: Colors.white, size: 20),
                  ),
                  title: const Text('Trabajador individual'),
                  subtitle: const Text('Añadir un solo trabajador'),
                  onTap: () {
                    Navigator.pop(context);
                    _openWorkerSelectionDialog();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF38A169),
                    child: Icon(Icons.group_add, color: Colors.white, size: 20),
                  ),
                  title: const Text('Grupo con horario común'),
                  subtitle:
                      const Text('Definir horario y seleccionar trabajadores'),
                  onTap: () {
                    Navigator.pop(context);
                    _createNewGroup();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isWorkerInAnyGroup(Worker worker) {
    return _workerGroups
        .any((group) => group.workers.any((wId) => wId == worker.id));
  }

  Future<void> _createNewGroup() async {
    await _calculateWorkerHours();

    final result = await createWorkerGroup(
        context: context,
        filteredWorkers: _filteredWorkers,
        workerHours: _workerHours,
        selectedWorkers: widget.selectedWorkers);

    if (result != null) {
      final newGroup = result.group;
      final selectedWorkers = result.workers;

      // Añadir el grupo a la lista de grupos
      widget.selectedGroups.add(newGroup);

      // SOLUCIÓN: Añadir los trabajadores del grupo a la lista principal si no existen ya
      // Crear un mapa para verificación rápida de existencia
      final Map<int, bool> existingWorkerIds = {
        for (var worker in widget.selectedWorkers) worker.id: true
      };

      // Lista para acumular nuevos trabajadores que deben añadirse
      List<Worker> workersToAdd = [];

      // Para cada trabajador seleccionado en el grupo
      for (var worker in selectedWorkers) {
        // Si no está ya en la lista principal, añadirlo
        if (!existingWorkerIds.containsKey(worker.id)) {
          workersToAdd.add(worker);
        }
      }

      // Si hay nuevos trabajadores para añadir
      if (workersToAdd.isNotEmpty) {
        // Crear una lista actualizada con todos los trabajadores
        final List<Worker> updatedSelectedWorkers = [
          ...widget.selectedWorkers,
          ...workersToAdd
        ];

        // Notificar el cambio de la lista principal
        widget.onWorkersChanged(updatedSelectedWorkers);
      }

      // Registrar el grupo en el provider global
      final groupsProvider =
          Provider.of<WorkerGroupsProvider>(context, listen: false);
      groupsProvider.addGroup(newGroup);

      // Actualizar la lista local de grupos
      setState(() {
        _workerGroups.add(newGroup);
      });

      // Notificar cambios en grupos
      if (widget.onGroupsChanged != null) {
        widget.onGroupsChanged!(widget.selectedGroups);
      }

      showSuccessToast(context, "Grupo creado con éxito");
    }
  }

  // Obtener un texto descriptivo de las horas trabajadas
  String _getHoursText(int workerId) {
    final hours = _workerHours[workerId] ?? 0.0;
    return '${hours.toStringAsFixed(1)} horas trabajadas';
  }

  // Verificar si un trabajador está disponible (menos de 12 horas)
  bool _isWorkerAvailable(int workerId) {
    final hours = _workerHours[workerId] ?? 0.0;
    return hours < 12.0;
  }

// Modificar el método _onDeleteGroup
  void _onDeleteGroup(WorkerGroup group, int assignmentId) {
    // Guardar los trabajadores del grupo que se va a eliminar
    final workersToRemove = group.workers.toList();

    // Eliminar el grupo del provider local
    final groupsProvider =
        Provider.of<WorkerGroupsProvider>(context, listen: false);
    groupsProvider.removeGroup(group.id);

    // Eliminar el grupo de la lista local
    setState(() {
      _workerGroups.removeWhere((g) => g.id == group.id);
      widget.selectedGroups.removeWhere((g) => g.id == group.id);
    });

    // En modo edición, registrar los trabajadores eliminados
    if (widget.inEditMode) {
      List<Worker> updatedDeletedWorkers = List.from(widget.deletedWorkers);

      for (var workerId in workersToRemove) {
        final workerToRemove = widget.selectedWorkers
            .firstWhere((w) => w.id == workerId, orElse: () => null as Worker);

        if (workerToRemove != null &&
            !updatedDeletedWorkers.any((w) => w.id == workerToRemove.id)) {
          updatedDeletedWorkers.add(workerToRemove);
        }
      }

      if (widget.onDeletedWorkersChanged != null) {
        widget.onDeletedWorkersChanged!(updatedDeletedWorkers);
      }
    }

    // Eliminar trabajadores de este grupo si no están en otros grupos
    List<Worker> workersToKeep = [];

    for (Worker worker in widget.selectedWorkers) {
      // Si el trabajador no está en el grupo eliminado o está en otro grupo, mantenerlo
      if (!workersToRemove.contains(worker.id) ||
          widget.selectedGroups.any((g) => g.workers.contains(worker.id))) {
        workersToKeep.add(worker);
      }
    }

    // Sincronizar con el backend si estamos en modo edición
    if (widget.inEditMode) {
      // Obtener el provider de asignaciones
      final assignmentsProvider =
          Provider.of<AssignmentsProvider>(context, listen: false);

      // Buscar el ID de la operación actual
      // (Necesitamos acceder a este ID desde algún lugar)
      // Esto podría venir como prop adicional al widget o desde un ancestro
      BuildContext? editFormContext =
          context.findAncestorStateOfType<EditOperationFormState>()?.context;

      if (editFormContext != null) {
        // Mostrar un indicador de carga
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        // Aquí llamamos al servicio de backend para eliminar el grupo
        try {
          // Esta función debe implementarse en el AssignmentService
          // y exponerse a través del provider
          assignmentsProvider
              .removeGroupFromAssignment(group.workers, context, assignmentId)
              .then((_) {
            // Cerrar el indicador de carga
            Navigator.of(context, rootNavigator: true).pop();
            // Mostrar mensaje de éxito
            showSuccessToast(context, "Grupo eliminado correctamente");
          }).catchError((error) {
            // Cerrar el indicador de carga
            Navigator.of(context, rootNavigator: true).pop();
            // Mostrar mensaje de error
            showErrorToast(context, "Error al eliminar el grupo: $error");
          });
        } catch (e) {
          // Cerrar el indicador de carga
          Navigator.of(context, rootNavigator: true).pop();
          // Mostrar mensaje de error
          showErrorToast(context, "Error al eliminar el grupo: $e");
        }
      }
    }

    // Buscar en AddAssignmentDialog para notificar sobre el cambio de grupos
    final addAssignmentDialog =
        context.findAncestorStateOfType<AddOperationDialogState>();
    if (addAssignmentDialog != null) {
      // Actualizar los grupos en el diálogo y recalcular horarios
      addAssignmentDialog.updateSelectedGroups(widget.selectedGroups);
    } else {
      debugPrint('No se encontró el estado de AddAssignmentDialog');
    }

    // Notificar al padre sobre el cambio en trabajadores
    widget.onWorkersChanged(workersToKeep);

    if (widget.onGroupsChanged != null) {
      widget.onGroupsChanged!(widget.selectedGroups);
    }

    // Mostrar confirmación
    showSuccessToast(context, "Grupo eliminado");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título y botón para agregar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Trabajadores Asignados',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF4A5568),
              ),
            ),
            NeumorphicButton(
              style: NeumorphicStyle(
                depth: 2,
                intensity: 0.6,
                boxShape:
                    NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                color: const Color(0xFF3182CE),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onPressed: _isCalculatingHours ? null : _showAddOptions,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isCalculatingHours
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white,
                        ),
                  const SizedBox(width: 6),
                  Text(
                    _isCalculatingHours ? "Calculando..." : "Añadir",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Lista de trabajadores seleccionados
        widget.selectedWorkers.isEmpty || widget.selectedGroups.isEmpty
            ? Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF7FAFC),
                ),
                child: const Center(
                  child: Text(
                    'No hay trabajadores seleccionados',
                    style: TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.selectedWorkers.length,
                  itemBuilder: (context, index) {
                    final worker = widget.selectedWorkers[index];
                    final isAvailable = _isWorkerAvailable(worker.id);
                    // IMPORTANTE: Obtener el grupo directamente de widget.selectedGroups
                    WorkerGroup? workerGroup;
                    for (var group in widget.selectedGroups) {
                      if (group.workers.contains(worker.id)) {
                        workerGroup = group;
                        break;
                      }
                    }

                    // Determinar si es el primer trabajador del grupo en la lista
                    bool isFirstWorkerInGroupInList = false;
                    if (workerGroup != null) {
                      isFirstWorkerInGroupInList = true;
                      for (int i = 0; i < index; i++) {
                        final previousWorker = widget.selectedWorkers[i];
                        if (workerGroup.workers.contains(previousWorker.id)) {
                          isFirstWorkerInGroupInList = false;
                          break;
                        }
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      elevation: 0,
                      color: workerGroup != null
                          ? Color(
                              0xFFE6FFFA) // Color para trabajadores en grupo (verde suave)
                          : const Color(0xFFF7FAFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: isAvailable
                            ? workerGroup != null
                                ? BorderSide(
                                    color: Color(0xFF38A169), width: 0.5)
                                : BorderSide.none
                            : const BorderSide(color: Colors.red, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Si tiene grupo, mostrar un banner con el nombre del grupo
                          if (workerGroup != null && isFirstWorkerInGroupInList)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color(0xFF38A169),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time,
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      workerGroup.name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete,
                                        color: Colors.red, size: 20),
                                    onPressed: () {
                                      _onDeleteGroup(workerGroup!,
                                          widget.assignmentId ?? 0);
                                      setState(() {
                                        _workerGroups.remove(workerGroup);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),

                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            dense: true,
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundColor: getColorForWorker(worker),
                                  radius: 16,
                                  child: Text(
                                    worker.name.isNotEmpty
                                        ? worker.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                if (!isAvailable)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 1),
                                      ),
                                      child: const Icon(
                                        Icons.warning,
                                        color: Colors.white,
                                        size: 8,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              worker.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: isAvailable
                                    ? const Color(0xFF2D3748)
                                    : Colors.red[700],
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  worker.area,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF718096),
                                  ),
                                ),
                                Text(
                                  _getHoursText(worker.id),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isAvailable
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              onPressed: () {
                                // Si estamos en modo edición y tenemos un ID de operación, usar el disconnect API
                                if (widget.inEditMode &&
                                    widget.assignmentId != null) {
                                  // Obtener el provider para la llamada al backend
                                  final assignmentsProvider =
                                      Provider.of<AssignmentsProvider>(context,
                                          listen: false);

                                  // Llamar al mismo método que se usa para grupos, pero solo con este trabajador
                                  assignmentsProvider.removeGroupFromAssignment(
                                      [
                                        worker.id
                                      ], // Lista con solo este trabajador
                                      context,
                                      widget.assignmentId ?? 0);

                                  // Mostrar un toast de confirmación
                                  showSuccessToast(
                                      context, "Trabajador eliminado");
                                }

                                final updatedList =
                                    List<Worker>.from(widget.selectedWorkers);
                                final removedWorker =
                                    updatedList.removeAt(index);

                                // Si es parte de un grupo, actualizar el grupo
                                if (workerGroup != null) {
                                  setState(() {
                                    // Quitar el trabajador del grupo
                                    workerGroup!.workers
                                        .removeWhere((wId) => wId == worker.id);

                                    // Si el grupo queda vacío, eliminar el grupo
                                    if (workerGroup.workers.isEmpty) {
                                      widget.selectedGroups.removeWhere(
                                          (g) => g.id == workerGroup!.id);
                                      _workerGroups.remove(workerGroup);

                                      // Notificar cambio en grupos para recalcular horarios
                                      if (widget.onGroupsChanged != null) {
                                        widget.onGroupsChanged!(
                                            widget.selectedGroups);
                                      }
                                    }
                                  });
                                }

                                // En modo edición, agregar el trabajador eliminado a la lista de eliminados
                                if (widget.inEditMode &&
                                    widget.onDeletedWorkersChanged != null) {
                                  List<Worker> updatedDeletedWorkers =
                                      List.from(widget.deletedWorkers);

                                  // Solo agregar si no está ya en la lista
                                  if (!updatedDeletedWorkers
                                      .any((w) => w.id == removedWorker.id)) {
                                    updatedDeletedWorkers.add(removedWorker);
                                    widget.onDeletedWorkersChanged!(
                                        updatedDeletedWorkers);
                                  }
                                }

                                widget.onWorkersChanged(updatedList);
                              },
                              tooltip: 'Eliminar',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

        // Información adicional sobre horas
        if (widget.selectedWorkers.isNotEmpty && _workerHours.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '* Los trabajadores deben tener menos de 12 horas acumuladas en el día',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }
}
