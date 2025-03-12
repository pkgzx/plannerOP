import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:provider/provider.dart';
import 'worker_selection_dialog.dart';
import 'package:intl/intl.dart';

class SelectedWorkersList extends StatefulWidget {
  // Lista de trabajadores seleccionados
  final List<Worker> selectedWorkers;

  // Función de callback cuando cambia la selección
  final Function(List<Worker>) onWorkersChanged;

  // Todos los trabajadores disponibles (para el diálogo de selección)
  final List<Worker> availableWorkers;

  const SelectedWorkersList({
    Key? key,
    required this.selectedWorkers,
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
    final completedAssignments = assignmentsProvider.completedAssignments;

    // Mapa para acumular las horas por trabajador
    Map<int, double> hoursMap = {};

    // Procesar todas las asignaciones completadas
    for (var assignment in completedAssignments) {
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

    // Filtrar trabajadores disponibles que tengan menos de 8 horas trabajadas
    final filteredWorkers = widget.availableWorkers.where((worker) {
      // Si el trabajador no está en el mapa o tiene menos de 8 horas, está disponible
      return !hoursMap.containsKey(worker.id) ||
          (hoursMap[worker.id] ?? 0) < 12.0;
    }).toList();

    setState(() {
      _workerHours = hoursMap;
      _filteredWorkers = filteredWorkers;
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
      ),
    );

    if (result != null) {
      // Notificar al padre sobre el cambio
      widget.onWorkersChanged(result);
    }
  }

  // Obtener un texto descriptivo de las horas trabajadas
  String _getHoursText(int workerId) {
    final hours = _workerHours[workerId] ?? 0.0;
    return '${hours.toStringAsFixed(1)} horas trabajadas';
  }

  // Verificar si un trabajador está disponible (menos de 8 horas)
  bool _isWorkerAvailable(int workerId) {
    final hours = _workerHours[workerId] ?? 0.0;
    return hours < 8.0;
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
              onPressed:
                  _isCalculatingHours ? null : _openWorkerSelectionDialog,
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
                          Icons.person_add,
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

                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      elevation: 0,
                      color: const Color(0xFFF7FAFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: isAvailable
                            ? BorderSide.none
                            : const BorderSide(color: Colors.red, width: 0.5),
                      ),
                      child: ListTile(
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
                            widget.onWorkersChanged(updatedList);
                          },
                          tooltip: 'Eliminar',
                        ),
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
              '* Los trabajadores deben tener menos de 8 horas acumuladas en el día',
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

    // Convertir el ID a un número para seleccionar un color
    int colorIndex = worker.id.hashCode % colors.length;
    return colors[colorIndex.abs()];
  }
}
