import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/store/workerGroup.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:provider/provider.dart';
import 'worker_selection_dialog.dart';
import 'package:intl/intl.dart';

class SelectedWorkersList extends StatefulWidget {
  // Lista de trabajadores seleccionados
  final List<Worker> selectedWorkers;
  final List<WorkerGroup> selectedGroups;

  // Función de callback cuando cambia la selección
  final Function(List<Worker>) onWorkersChanged;

  // Todos los trabajadores disponibles (para el diálogo de selección)
  final List<Worker> availableWorkers;

  const SelectedWorkersList({
    Key? key,
    required this.selectedWorkers,
    required this.selectedGroups,
    required this.onWorkersChanged,
    required this.availableWorkers,
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
    final availableWorkers = workersProvider.getWorkersAvailable();

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
        // Calcular la duración de esta asignación
        final double assignmentHours = _calculateAssignmentDuration(assignment);

        debugPrint(
            'Assignment ${assignment.id} duration: $assignmentHours hours');

        // Asignar estas horas a cada trabajador de la asignación
        for (var worker in assignment.workers) {
          if (hoursMap.containsKey(worker.id)) {
            hoursMap[worker.id] = (hoursMap[worker.id] ?? 0) + assignmentHours;
          } else {
            hoursMap[worker.id] = assignmentHours;
          }
        }
      }
    }

    debugPrint('Total hours calculated: ${hoursMap.length}');

    // Filtrar trabajadores disponibles que tengan menos de 12 horas trabajadas
    final filteredWorkers = availableWorkers.where((worker) {
      // Si el trabajador no está en el mapa o tiene menos de 12 horas, está disponible
      return !hoursMap.containsKey(worker.id) ||
          (hoursMap[worker.id] ?? 0) < 12.0;
    }).toList();

    debugPrint('Filtered workers: ${filteredWorkers.length}');

    final Set<int> selectedWorkerIds =
        widget.selectedWorkers.map((w) => w.id).toSet();

    // Trabajadores que no están seleccionados ni en grupos
    final availableForSelection = filteredWorkers.where((worker) {
      return !_isWorkerInAnyGroup(worker) &&
          !selectedWorkerIds.contains(worker.id);
    }).toList();

    setState(() {
      _workerHours = hoursMap;
      _filteredWorkers = availableForSelection;
      _isCalculatingHours = false;
    });
  }

  // Calcular la duración de una asignación en horas
  double _calculateAssignmentDuration(Assignment assignment) {
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

    // Calcular diferencia en horas
    final difference = endDateTime.difference(startDateTime);
    return difference.inMinutes / 60.0;
  }

  // Abrir diálogo para seleccionar trabajadores
  Future<void> _openWorkerSelectionDialog() async {
    // Recalcular horas antes de abrir el diálogo
    await _calculateWorkerHours();

    final result = await showDialog<List<Worker>>(
      context: context,
      builder: (context) => WorkerSelectionDialog(
        selectedWorkers: widget.selectedWorkers,
        // Pasar solo los trabajadores filtrados por horas disponibles
        availableWorkers: _filteredWorkers,
        workerHours: _workerHours,
        title: 'Seleccionar trabajadores',
        allSelectedWorkers: widget.selectedWorkers,
      ),
    );

    if (result != null) {
      // Notificar al padre sobre el cambio
      widget.onWorkersChanged(result);
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
    // Variables para almacenar horarios seleccionados
    String? startTime;
    String? endTime;

    // 1. Primero mostrar diálogo para seleccionar horarios (opcional)
    bool continueToSelection = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Definir horario común'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Define un horario común para este grupo de trabajadores (opcional):',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(
                                  alwaysUse24HourFormat: false,
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (picked != null) {
                            final hour = picked.hour.toString().padLeft(2, '0');
                            final minute =
                                picked.minute.toString().padLeft(2, '0');
                            startTime = '$hour:$minute';

                            // Forzar actualización de UI
                            (context as Element).markNeedsBuild();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hora inicio',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF718096),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                startTime ?? 'Seleccionar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: startTime != null
                                      ? Colors.black
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context),
                                child: child!,
                              );
                            },
                          );

                          if (picked != null) {
                            final hour = picked.hour.toString().padLeft(2, '0');
                            final minute =
                                picked.minute.toString().padLeft(2, '0');
                            endTime = '$hour:$minute';

                            // Forzar actualización de UI
                            (context as Element).markNeedsBuild();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hora fin',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF718096),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                endTime ?? 'Seleccionar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: endTime != null
                                      ? Colors.black
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3182CE),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continuar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!continueToSelection) return;

    // 2. Luego, mostrar selección de trabajadores
    await _calculateWorkerHours(); // Actualizar horas antes de mostrar

    final selectedWorkers = await showDialog<List<Worker>>(
      context: context,
      builder: (context) => WorkerSelectionDialog(
        selectedWorkers: const [],
        availableWorkers: _filteredWorkers,
        workerHours: _workerHours,
        title: 'Seleccionar trabajadores para el grupo',
        allSelectedWorkers: widget.selectedWorkers,
      ),
    );

    if (selectedWorkers != null && selectedWorkers.isNotEmpty) {
      // Crear nombre de grupo basado en horarios
      String groupName = 'Grupo';
      if (startTime != null && endTime != null) {
        groupName = 'Grupo $startTime - $endTime';
      } else if (startTime != null) {
        groupName = 'Grupo inicio $startTime-N/A';
      } else if (endTime != null) {
        groupName = 'Grupo fin N/A-$endTime';
      }

      // Crear el grupo
      final newGroup = WorkerGroup(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: startTime,
        endTime: endTime,
        workers: selectedWorkers.map((worker) => worker.id).toList(),
        name: groupName,
      );

      widget.selectedGroups.add(newGroup);

      final groupsProvider =
          Provider.of<WorkerGroupsProvider>(context, listen: false);
      groupsProvider.addGroup(newGroup);

      // Actualizar la lista de trabajadores seleccionados
      final List<Worker> updatedWorkers = [
        ...widget.selectedWorkers,
        ...selectedWorkers,
      ];

      // Actualizar la lista de grupos
      setState(() {
        _workerGroups.add(newGroup);
      });

      // Notificar al padre
      widget.onWorkersChanged(updatedWorkers);

      // Mostrar confirmación
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

  void _onDeleteGroup(WorkerGroup group) {
    final groupsProvider =
        Provider.of<WorkerGroupsProvider>(context, listen: false);
    groupsProvider.removeGroup(group.id);

    // Eliminar todos los trabajadores de este grupo de la lista
    for (var id in group.workers) {
      widget.selectedWorkers.removeWhere((w) => w.id == id);
    }

    showSuccessToast(context, "Grupo eliminado con éxito");
  }

  @override
  Widget build(BuildContext context) {
    final groupsProvider = Provider.of<WorkerGroupsProvider>(context);

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
        widget.selectedWorkers.isEmpty
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
                    final workerGroup = groupsProvider.getWorkerGroup(worker);

                    // Determinar si es el primer trabajador del grupo en la lista
                    bool isFirstWorkerInGroupInList = false;
                    if (workerGroup != null) {
                      isFirstWorkerInGroupInList = true;
                      for (int i = 0; i < index; i++) {
                        final previousWorker = widget.selectedWorkers[i];
                        if (groupsProvider.areWorkersInSameGroup(
                            previousWorker, worker)) {
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
                                      _onDeleteGroup(workerGroup);
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
                                  backgroundColor: _getColorForWorker(worker),
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
                                final updatedList =
                                    List<Worker>.from(widget.selectedWorkers);
                                updatedList.removeAt(index);

                                // Si es parte de un grupo, actualizar el grupo
                                if (workerGroup != null) {
                                  setState(() {
                                    // Quitar el trabajador del grupo
                                    workerGroup.workers
                                        .removeWhere((wId) => wId == worker.id);

                                    // Si el grupo queda vacío, eliminar el grupo
                                    if (workerGroup.workers.isEmpty) {
                                      _workerGroups.remove(workerGroup);
                                    }
                                  });
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

        // Información sobre grupos
        if (_workerGroups.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '* Los trabajadores con fondo verde pertenecen a un grupo con horario común',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.green[700],
              ),
            ),
          ),
      ],
    );
  }

  // Obtener un color consistente para cada trabajador basado en su ID
  Color _getColorForWorker(Worker worker) {
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
    ];
    final int index = worker.id % colors.length;
    return colors[index];
  }
}
