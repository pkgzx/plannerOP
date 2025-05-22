import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/task.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/task.dart';
import 'package:plannerop/utils/group.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/assingments/components/serviceSelector.dart';
import 'package:provider/provider.dart';
import '../worker_selection_dialog.dart';

class GroupCreationResult {
  final WorkerGroup group;
  final List<Worker> workers;

  GroupCreationResult(this.group, this.workers);
}

/// Muestra opciones para añadir trabajadores (individual o grupo)
void showWorkerAddOptions({
  required BuildContext context,
  required VoidCallback onAddIndividual,
  required VoidCallback onAddGroup,
}) {
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
                  child: Icon(Icons.person_add, color: Colors.white, size: 20),
                ),
                title: const Text('Trabajador individual'),
                subtitle: const Text('Añadir un solo trabajador'),
                onTap: () {
                  Navigator.pop(context);
                  onAddIndividual();
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
                  onAddGroup();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Crear un grupo de trabajadores
Future<GroupCreationResult?> createWorkerGroup({
  required BuildContext context,
  required List<Worker> filteredWorkers,
  required Map<int, double> workerHours,
  required List<Worker> selectedWorkers,
}) async {
  // Paso 1: Mostrar diálogo para seleccionar horarios
  final scheduleData = await _showGroupScheduleDialog(context);
  if (scheduleData == null) return null;

  final String? startTime = scheduleData['startTime'];
  final String? endTime = scheduleData['endTime'];
  final DateTime? startDate = scheduleData['startDate'];
  final DateTime? endDate = scheduleData['endDate'];
  final int selectedServiceId = scheduleData['serviceId'] ?? 0;

  // Verificar que al menos tenga un horario definido
  if (startTime == null) {
    showAlertToast(context, "Debes definir al menos el horario de inicio");
    return null;
  }

  // Paso 2: Mostrar diálogo para seleccionar trabajadores
  final workers = await showDialog<List<Worker>>(
    context: context,
    builder: (context) => WorkerSelectionDialog(
      selectedWorkers: const [],
      availableWorkers: filteredWorkers,
      workerHours: workerHours,
      title: 'Seleccionar trabajadores para el grupo',
      allSelectedWorkers: selectedWorkers,
    ),
  );

  if (workers == null || workers.isEmpty) return null;

  // Crear el grupo
  String groupName = getGroupName(startDate, endDate, startTime, endTime);

  String? startDateStr =
      startDate != null ? DateFormat('yyyy-MM-dd').format(startDate) : null;
  String? endDateStr =
      endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : null;

  final newGroup = WorkerGroup(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    startTime: startTime,
    endTime: endTime,
    startDate: startDateStr,
    endDate: endDateStr,
    workers: workers.map((worker) => worker.id).toList(),
    workersData: workers,
    name: groupName,
    serviceId: selectedServiceId,
  );

  return GroupCreationResult(newGroup, workers);
}

/// Diálogo para configurar horario del grupo
Future<Map<String, dynamic>?> _showGroupScheduleDialog(
    BuildContext context) async {
  String? startTime;
  String? endTime;
  DateTime? startDate;
  DateTime? endDate;
  int selectedServiceId = 0;

  final bool continueToSelection = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Definir horario común'),
          content: StatefulBuilder(builder: (context, setState) {
            final tasksProvider =
                Provider.of<TasksProvider>(context, listen: false);
            final List<Task> availableTasks = tasksProvider.tasks;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Define horarios comunes para este grupo de trabajadores:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // Sección de fecha y hora de inicio
                  const Text(
                    'INICIO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF718096),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Fecha de inicio
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );

                      if (picked != null) {
                        setState(() {
                          startDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fecha inicio',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF718096),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  startDate != null
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(startDate!)
                                      : 'Seleccionar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: startDate != null
                                        ? Colors.black
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Hora de inicio
                  GestureDetector(
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
                        setState(() {
                          final hour = picked.hour.toString().padLeft(2, '0');
                          final minute =
                              picked.minute.toString().padLeft(2, '0');
                          startTime = '$hour:$minute';
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
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
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sección de fecha y hora de finalización
                  const Text(
                    'FINALIZACIÓN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF718096),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // TODO CAMBIAR ESTOS POR EL COMPONENTE FECHA

                  // Fecha de finalización
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );

                      if (picked != null) {
                        setState(() {
                          endDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fecha fin',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF718096),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  endDate != null
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(endDate!)
                                      : 'Seleccionar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: endDate != null
                                        ? Colors.black
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Hora de finalización
                  GestureDetector(
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
                        setState(() {
                          final hour = picked.hour.toString().padLeft(2, '0');
                          final minute =
                              picked.minute.toString().padLeft(2, '0');
                          endTime = '$hour:$minute';
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Con esto:
                  const SizedBox(height: 12),
                  buildServiceSelector(
                    context,
                    availableTasks,
                    selectedServiceId,
                    (newSelection) {
                      setState(() {
                        selectedServiceId = newSelection;
                      });
                    },
                  ),
                ],
              ),
            );
          }),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3182CE),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ) ??
      false;

  if (!continueToSelection) return null;

  return {
    'startTime': startTime,
    'endTime': endTime,
    'startDate': startDate,
    'endDate': endDate,
    'serviceId': selectedServiceId,
  };
}
