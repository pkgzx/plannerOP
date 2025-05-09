import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/store/feedings.dart';
import 'package:plannerop/widgets/assingments/components/showCompletionDialog.dart';
import 'package:provider/provider.dart';

Map<String, List<Worker>> groupWorkersByGroup(Assignment assignment) {
  final Map<String, List<Worker>> workersByGroup = {};
  final Set<int> finishedWorkerIds =
      assignment.workersFinished.map((w) => w.id).toSet();

  for (var group in assignment.groups) {
    workersByGroup[group.id] = assignment.workers
        .where((worker) =>
            group.workers.contains(worker.id) &&
            !finishedWorkerIds.contains(worker.id))
        .toList();
  }

  return workersByGroup;
}

Widget buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A5568),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildInChargerItem(User charger) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.shade400,
            radius: 18,
            child: Text(
              charger.name.toString().substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        charger.name.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ],
                ),
                if (charger.cargo.isNotEmpty)
                  Text(
                    charger.cargo.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF718096),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildWorkersSection(Assignment assignment, BuildContext context,
    {required Function setState,
    Map<int, bool> alimentacionStatus = const {},
    List<String> foods = const [],
    Function(int, bool)? onAlimentacionChanged}) {
  // Obtener los grupos de la asignación
  final groups = assignment.groups;
  final assignmentsProvider =
      Provider.of<AssignmentsProvider>(context, listen: false);

  // Obtener el FeedingProvider
  final feedingProvider = Provider.of<FeedingProvider>(context);

  // Fecha y hora actual para comparar
  final DateTime now = DateTime.now();

  bool hasFoodRights = foods.isNotEmpty && !foods.contains('Sin alimentación');
  String currentFoodType = hasFoodRights ? foods[0] : '';

  // Agrupar los workers por su grupo
  Map<String, List<Worker>> workersByGroup = {};
  List<Worker> ungroupedWorkers = [];

  // Conjunto para seguir los IDs de trabajadores que ya están en grupos o finalizados
  Set<int> groupedWorkerIds = {};
  Set<int> finishedWorkerIds =
      assignment.workersFinished.map((w) => w.id).toSet();

  // Asignar colores únicos a cada grupo
  Map<String, Color> groupColors = {};
  List<Color> groupColorOptions = [
    const Color(0xFFE6FFFA), // Verde claro
    const Color(0xFFEBF4FF), // Azul claro
    const Color(0xFFFEF3C7), // Amarillo claro
    const Color(0xFFFEE2E2), // Rojo claro
    const Color(0xFFFAF5FF), // Púrpura claro
  ];

  int colorIndex = 0;

  // Primero: identificar todos los trabajadores en grupos
  for (var group in groups) {
    // Solo considerar los grupos que no han finalizado o que su fecha de finalización es futura
    bool isGroupFinished = false;
    if (group.endDate != null && group.endTime != null) {
      // Parsear la fecha y hora de finalización
      try {
        final endDate = DateTime.parse(group.endDate!);
        final timeParts = group.endTime!.split(':');
        final endDateTime = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        if (endDateTime.isBefore(now)) {
          isGroupFinished = true;
        }
      } catch (e) {
        debugPrint('Error al parsear fecha/hora: $e');
      }
    }

    // Verificar si todos los trabajadores del grupo están en workersFinished
    if (group.workers
        .every((workerId) => finishedWorkerIds.contains(workerId))) {
      isGroupFinished = true;
    }

    // Si el grupo no ha finalizado o queremos mostrar todos incluyendo los finalizados
    if (!isGroupFinished) {
      // Asignar un color único al grupo
      if (!groupColors.containsKey(group.id)) {
        groupColors[group.id] =
            groupColorOptions[colorIndex % groupColorOptions.length];
        colorIndex++;
      }

      // Inicializar lista para este grupo
      workersByGroup[group.id] = [];

      // Añadir IDs de trabajadores de este grupo al conjunto de agrupados
      for (var workerId in group.workers) {
        // Solo añadir si no está finalizado
        if (!finishedWorkerIds.contains(workerId)) {
          groupedWorkerIds.add(workerId);
        }
      }
    }
  }

  // Segundo: clasificar trabajadores en sus grupos correspondientes
  for (var worker in assignment.workers) {
    // Saltarse trabajadores que ya están finalizados
    if (finishedWorkerIds.contains(worker.id)) {
      continue;
    }

    bool assignedToGroup = false;

    // Buscar en qué grupo está este trabajador
    for (var group in groups) {
      // Verificar si el grupo ya ha finalizado
      bool isGroupFinished = false;
      if (group.endDate != null && group.endTime != null) {
        try {
          final endDate = DateTime.parse(group.endDate!);
          final timeParts = group.endTime!.split(':');
          final endDateTime = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );

          if (endDateTime.isBefore(now)) {
            isGroupFinished = true;
          }
        } catch (e) {
          debugPrint('Error al parsear fecha/hora: $e');
        }
      }

      // Verificar si todos los trabajadores del grupo están en workersFinished
      if (group.workers
          .every((workerId) => finishedWorkerIds.contains(workerId))) {
        isGroupFinished = true;
      }

      // Solo procesar grupos no finalizados y si el trabajador pertenece a este grupo
      if (!isGroupFinished &&
          group.workers.contains(worker.id) &&
          workersByGroup.containsKey(group.id)) {
        workersByGroup[group.id]!.add(worker);
        assignedToGroup = true;
        break; // Un trabajador solo puede estar en un grupo
      }
    }

    // Si el trabajador no está en ningún grupo ni está finalizado, añadirlo a los trabajadores sin grupo
    if (!assignedToGroup &&
        !groupedWorkerIds.contains(worker.id) &&
        !finishedWorkerIds.contains(worker.id)) {
      ungroupedWorkers.add(worker);
    }
  }

  List<Widget> sections = [];

  // Primero mostrar los grupos (solo los no finalizados)
  workersByGroup.forEach((groupId, workers) {
    if (workers.isEmpty)
      return; // Ignorar grupos sin trabajadores (todos finalizados)

    final group = groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => WorkerGroup(workers: [], name: "", id: ""),
    );

    sections.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF38A169),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.group, color: Colors.white, size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: 2,
                    intensity: 0.5,
                    color: Colors.white,
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(4)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  onPressed: () {
                    showGroupCompletionDialog(context, assignment, workers,
                        groupId, assignmentsProvider, setState);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.done_all, color: Color(0xFF38A169), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Completar grupo',
                        style: TextStyle(
                          color: Color(0xFF38A169),
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: groupColors[groupId]!,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(7),
                bottomRight: Radius.circular(7),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ...workers
                    .map((worker) => _buildWorkerItemWithCompletion(
                          worker,
                          assignment,
                          assignmentsProvider,
                          context,
                          isInGroup: true,
                          alimentacionEntregada:
                              alimentacionStatus[worker.id] ?? false,
                          onAlimentacionChanged: hasFoodRights
                              ? onAlimentacionChanged
                              : null, // Solo pasar si hay comida disponible
                          currentFoodType: currentFoodType,
                        ))
                    .toList(),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  });

  // Luego mostrar los trabajadores sin grupo si existen (y no están finalizados)
  if (ungroupedWorkers.isNotEmpty) {
    sections.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (workersByGroup
              .isNotEmpty) // Solo mostrar este título si hay grupos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                    child: Text(
                      'Trabajadores individuales',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                  ),
                ),
                // Botón para completar todos los trabajadores individuales
                if (ungroupedWorkers.length > 1)
                  NeumorphicButton(
                    style: NeumorphicStyle(
                      depth: 2,
                      intensity: 0.5,
                      color: Colors.white,
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(4)),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    onPressed: () {
                      showCompleteAllIndividualsDialog(context, assignment,
                          ungroupedWorkers, assignmentsProvider, setState);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.done_all,
                            color: Color(0xFF38A169), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Completar todos',
                          style: TextStyle(
                            color: Color(0xFF38A169),
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ...ungroupedWorkers
              .map((worker) => _buildWorkerItemWithCompletion(
                    worker,
                    assignment,
                    assignmentsProvider,
                    context,
                    isInGroup: false,
                    alimentacionEntregada: foods.isNotEmpty
                        ? feedingProvider.isMarked(
                            assignment.id ?? 0, worker.id, foods[0])
                        : false,
                    onAlimentacionChanged: hasFoodRights
                        ? onAlimentacionChanged
                        : null, // Solo pasar si hay comida disponible
                    currentFoodType: currentFoodType,
                  ))
              .toList(),
        ],
      ),
    );
  }

  return Column(children: sections);
}

// Actualizar _buildWorkerItemWithCompletion para sincronizarse con franjas horarias específicas
Widget _buildWorkerItemWithCompletion(Worker worker, Assignment assignment,
    AssignmentsProvider assignmentsProvider, BuildContext context,
    {bool isDeleted = false,
    bool isInGroup = false,
    bool? alimentacionEntregada, // Parámetro para controlar estado
    Function(int, bool)? onAlimentacionChanged, // Callback
    String? currentFoodType // Nuevo parámetro: tipo actual de comida
    }) {
  // Usar el valor proporcionado o defaultear a false
  final bool _alimentacionEntregada = alimentacionEntregada ?? false;
  final FeedingProvider feedingsProvider =
      Provider.of<FeedingProvider>(context, listen: false);

  // Si no hay tipo de comida válido o está fuera de horario, no mostrar botón
  bool showFoodButton = currentFoodType != null &&
      currentFoodType.isNotEmpty &&
      currentFoodType != 'Sin alimentación' &&
      currentFoodType != 'Sin alimentación actual';

  // Verificar y mostrar sola la alimentacion si esta dentro de la franja horaria

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: isDeleted
          ? BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade100),
            )
          : BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFFE2E8F0)),
              // Añadir un sutil color de fondo cuando la alimentación está entregada
              color: _alimentacionEntregada
                  ? Colors.green.shade50.withOpacity(0.5)
                  : Colors.white,
            ),
      child: Column(
        children: [
          // Primera fila: información del trabajador y botón de completar
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isDeleted
                    ? Colors.grey
                    : Colors.primaries[
                        worker.name.hashCode % Colors.primaries.length],
                radius: 18,
                child: isDeleted
                    ? const Icon(Icons.person_off_outlined,
                        color: Colors.white, size: 16)
                    : Text(
                        worker.name.toString().substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            worker.name.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDeleted
                                  ? Colors.red.shade700
                                  : const Color(0xFF2D3748),
                              decoration:
                                  isDeleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (isDeleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Eliminado',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (worker.area.isNotEmpty)
                      Text(
                        worker.area.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDeleted
                              ? Colors.red.shade300
                              : const Color(0xFF718096),
                        ),
                      ),
                  ],
                ),
              ),
              // Solo mostrar el botón de completar para trabajadores individuales (no en grupo)
              if (!isDeleted && !isInGroup)
                NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: 1,
                    intensity: 0.5,
                    color: Colors.white,
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(4)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  onPressed: () {
                    showIndividualCompletionDialog(
                        context, assignment, worker, assignmentsProvider);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: Color(0xFF38A169), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Completar',
                        style: TextStyle(
                          color: Color(0xFF38A169),
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Botón para marcar alimentación - SOLO se muestra si hay comida aplicable
          if (!isDeleted && showFoodButton && onAlimentacionChanged != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: GestureDetector(
                onTap: () {
                  // Llamar al callback con el nuevo valor invertido
                  onAlimentacionChanged(worker.id, !_alimentacionEntregada);
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: _alimentacionEntregada
                        ? Colors.green.shade100
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _alimentacionEntregada
                          ? Colors.green.shade400
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getIconForFoodType(
                            currentFoodType!, _alimentacionEntregada),
                        color: _alimentacionEntregada
                            ? Colors.green
                            : Colors.grey.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _alimentacionEntregada
                            ? '$currentFoodType entregado'
                            : 'Marcar $currentFoodType',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _alimentacionEntregada
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _alimentacionEntregada
                              ? Colors.green
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// Helper para obtener el icono adecuado según el tipo de comida
IconData _getIconForFoodType(String foodType, bool isMarked) {
  switch (foodType) {
    case 'Desayuno':
      return isMarked ? Icons.free_breakfast : Icons.free_breakfast_outlined;
    case 'Almuerzo':
      return isMarked ? Icons.restaurant : Icons.restaurant_outlined;
    case 'Cena':
      return isMarked ? Icons.dinner_dining : Icons.dinner_dining_outlined;
    case 'Media noche':
      return isMarked ? Icons.nightlight_round : Icons.nightlight_outlined;
    default:
      return isMarked ? Icons.restaurant : Icons.restaurant_outlined;
  }
}

Widget buildFilterBar(
  List<String> areas,
  List<User> supervisors,
  bool _showFilters,
  String? _selectedArea,
  int? _selectedSupervisorId,
  BuildContext context,
  Function setState,
) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            Text(
              'Filtros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            Spacer(),
            NeumorphicButton(
              style: NeumorphicStyle(
                depth: 2,
                intensity: 0.7,
                boxShape: NeumorphicBoxShape.circle(),
                color: _showFilters
                    ? const Color(0xFF3182CE)
                    : const Color(0xFFE2E8F0),
              ),
              padding: const EdgeInsets.all(8),
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
              child: Icon(
                Icons.filter_list,
                size: 18,
                color: _showFilters ? Colors.white : const Color(0xFF718096),
              ),
            ),
          ],
        ),
        if (_showFilters) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Área',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: _selectedArea,
                  hint: Text('Todas las áreas'),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todas las áreas'),
                    ),
                    ...areas.map((area) => DropdownMenuItem<String>(
                          value: area,
                          child: Text(area),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedArea = value;
                    });
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Supervisor',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: _selectedSupervisorId,
                  hint: Text('Todos los supervisores'),
                  isExpanded: true,
                  // Personalizar cómo se muestra el elemento seleccionado
                  selectedItemBuilder: (BuildContext context) {
                    return supervisors.map<Widget>((User supervisor) {
                      return Container(
                        alignment: Alignment.centerLeft,
                        constraints: BoxConstraints(minWidth: 100),
                        child: Text(
                          supervisor.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: Color(0xFF2D3748),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList()
                      ..insert(0,
                          Text('Todos los supervisores')); // Para el caso null
                  },
                  // Limitar altura máxima del menú desplegable
                  menuMaxHeight: 300,
                  // Separación entre elementos
                  itemHeight: 60,
                  items: [
                    DropdownMenuItem<int>(
                      value: null,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFEDF2F7),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text('Todos los supervisores'),
                      ),
                    ),
                    ...supervisors.map((supervisor) => DropdownMenuItem<int>(
                          value: supervisor.id,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Color(0xFFEDF2F7),
                                  width: 1,
                                ),
                              ),
                            ),
                            // En el menú desplegado podemos mostrar el nombre completo
                            child: Text(supervisor.name),
                          ),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSupervisorId = value;
                    });
                  },
                ),
              ),
            ],
          ),
          if (_selectedArea != null || _selectedSupervisorId != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: NeumorphicButton(
                style: NeumorphicStyle(
                  depth: 2,
                  intensity: 0.7,
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onPressed: () {
                  setState(() {
                    _selectedArea = null;
                    _selectedSupervisorId = null;
                  });
                },
                child: Text(
                  'Limpiar filtros',
                  style: TextStyle(
                    color: Color(0xFF718096),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    ),
  );
}
