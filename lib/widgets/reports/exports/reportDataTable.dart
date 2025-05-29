import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/store/operations.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/store/task.dart';
import 'package:plannerop/store/clients.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/utils/charts/translate.dart';
import 'package:provider/provider.dart';

class ReportDataTable extends StatefulWidget {
  final String periodName;
  final DateTime startDate;
  final DateTime endDate;
  final String area;
  final int? zone;
  final String? motorship;
  final String? status;

  const ReportDataTable({
    Key? key,
    required this.periodName,
    required this.startDate,
    required this.endDate,
    required this.area,
    this.zone,
    this.motorship,
    this.status,
  }) : super(key: key);

  @override
  State<ReportDataTable> createState() => _ReportDataTableState();
}

class _ReportDataTableState extends State<ReportDataTable> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortAscending = true;
  int _sortColumnIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Operation> _getFilteredData(List<Operation> allAssignments) {
    debugPrint('=== INICIO FILTRADO DE DATOS ===');
    debugPrint('Total operaciones recibidas: ${allAssignments.length}');
    debugPrint('Filtros aplicados:');
    debugPrint('  - Área: ${widget.area}');
    debugPrint('  - Zona: ${widget.zone}');
    debugPrint('  - Motonave: ${widget.motorship}');
    debugPrint('  - Estado: ${widget.status}');
    debugPrint('  - Fecha inicio: ${widget.startDate}');
    debugPrint('  - Fecha fin: ${widget.endDate}');
    debugPrint('  - Búsqueda: $_searchQuery');

    // Mostrar algunas operaciones de ejemplo
    if (allAssignments.isNotEmpty) {
      debugPrint('Ejemplo de operaciones disponibles:');
      for (int i = 0;
          i < (allAssignments.length > 3 ? 3 : allAssignments.length);
          i++) {
        final op = allAssignments[i];
        debugPrint(
            '  Op ${op.id}: Área="${op.area}", Fecha=${op.date}, Estado=${op.status}');
      }
    }

    final filtered = allAssignments.where((data) {
      // Debug para cada operación
      debugPrint('Evaluando operación ${data.id}:');

      // Filtrar por área
      if (widget.area != 'Todas' && data.area != widget.area) {
        debugPrint('  ❌ Filtrada por área: "${data.area}" != "${widget.area}"');
        return false;
      }
      debugPrint('  ✅ Área OK: "${data.area}"');

      // Filtrar por fecha
      final date = data.date;
      if (date.isBefore(widget.startDate) || date.isAfter(widget.endDate)) {
        debugPrint(
            '  ❌ Filtrada por fecha: $date no está entre ${widget.startDate} y ${widget.endDate}');
        return false;
      }
      debugPrint('  ✅ Fecha OK: $date');

      // Filtrar por zona
      if (widget.zone != null) {
        int? assignmentZone;
        if (data.zone != null) {
          try {
            assignmentZone = int.tryParse(data.zone.toString());
          } catch (e) {
            assignmentZone = null;
          }
        }

        if (assignmentZone != widget.zone) {
          debugPrint(
              '  ❌ Filtrada por zona: $assignmentZone != ${widget.zone}');
          return false;
        }
        debugPrint('  ✅ Zona OK: $assignmentZone');
      }

      // Filtrar por motonave
      if (widget.motorship != null &&
          widget.motorship!.isNotEmpty &&
          widget.motorship != "Todas") {
        if (data.motorship == null || data.motorship != widget.motorship) {
          debugPrint(
              '  ❌ Filtrada por motonave: "${data.motorship}" != "${widget.motorship}"');
          return false;
        }
        debugPrint('  ✅ Motonave OK: "${data.motorship}"');
      }

      // Filtrar por estado
      if (widget.status != null &&
          widget.status!.isNotEmpty &&
          widget.status != "Todos") {
        String normalizedStatus = normalizeStatus(data.status);
        if (normalizedStatus != widget.status) {
          debugPrint(
              '  ❌ Filtrada por estado: "$normalizedStatus" != "${widget.status}"');
          return false;
        }
        debugPrint('  ✅ Estado OK: "$normalizedStatus"');
      }

      // Filtrar por búsqueda
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        bool foundInSearch = false;

        // Buscar en ID de operación
        if (data.id.toString().contains(searchLower)) {
          foundInSearch = true;
        }

        // Buscar en área
        if (data.area.toLowerCase().contains(searchLower)) {
          foundInSearch = true;
        }

        // Buscar en motonave
        if (data.motorship != null &&
            data.motorship!.toLowerCase().contains(searchLower)) {
          foundInSearch = true;
        }

        // Buscar en nombres de trabajadores
        for (var group in data.groups) {
          if (group.workersData != null) {
            for (var worker in group.workersData!) {
              if (worker.name.toLowerCase().contains(searchLower) ||
                  worker.document.toLowerCase().contains(searchLower)) {
                foundInSearch = true;
                break;
              }
            }
          }
          if (foundInSearch) break;
        }

        if (!foundInSearch) {
          debugPrint('  ❌ Filtrada por búsqueda: no contiene "$_searchQuery"');
          return false;
        }
        debugPrint('  ✅ Búsqueda OK: contiene "$_searchQuery"');
      }

      debugPrint('  ✅ Operación ${data.id} APROBADA');
      return true;
    }).toList();

    debugPrint('=== RESULTADO FILTRADO ===');
    debugPrint('Operaciones después del filtrado: ${filtered.length}');

    if (filtered.isNotEmpty) {
      debugPrint('Operaciones filtradas:');
      for (var op in filtered) {
        debugPrint('  - Op ${op.id}: ${op.area}, ${op.groups.length} grupos');
      }
    }

    // Ordenar datos
    filtered.sort((a, b) {
      var comparison = 0;
      switch (_sortColumnIndex) {
        case 0: // ID Op
          comparison = (a.id ?? 0).compareTo(b.id ?? 0);
          break;
        case 1: // Fecha Inicial
          comparison = a.date.compareTo(b.date);
          break;
        case 2: // Hora Inicial
          comparison = a.time.compareTo(b.time);
          break;
        case 5: // Área
          comparison = a.area.compareTo(b.area);
          break;
        case 6: // Zona
          final aZone = int.tryParse(a.zone.toString()) ?? 0;
          final bZone = int.tryParse(b.zone.toString()) ?? 0;
          comparison = aZone.compareTo(bZone);
          break;
        case 7: // Motonave
          final aMotorship = a.motorship ?? '';
          final bMotorship = b.motorship ?? '';
          comparison = aMotorship.compareTo(bMotorship);
          break;
        case 10: // Fecha Finalización
          final aEndDate = a.endDate ?? DateTime(1900);
          final bEndDate = b.endDate ?? DateTime(1900);
          comparison = aEndDate.compareTo(bEndDate);
          break;
        case 11: // Hora Finalización
          final aEndTime = a.endTime ?? '';
          final bEndTime = b.endTime ?? '';
          comparison = aEndTime.compareTo(bEndTime);
          break;
        case 12: // Estado
          comparison = a.status.compareTo(b.status);
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });

    debugPrint('=== FIN FILTRADO ===');
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('=== BUILD ReportDataTable ===');
    final assignmentsProvider = Provider.of<OperationsProvider>(context);
    final usersProvider = Provider.of<WorkersProvider>(context, listen: false);

    // Obtenemos las asignaciones del provider
    final allAssignments = assignmentsProvider.assignments;
    debugPrint('Operaciones del provider: ${allAssignments.length}');

    // Aplicamos los filtros a las asignaciones
    final filteredData = _getFilteredData(allAssignments);
    debugPrint('Operaciones filtradas para mostrar: ${filteredData.length}');

    return Column(
      children: [
        // Información de depuración (temporal)
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.yellow.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🔍 DEBUG INFO:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Total en provider: ${allAssignments.length}'),
              Text('Filtradas: ${filteredData.length}'),
              Text('Área filtro: "${widget.area}"'),
              Text('Estado filtro: "${widget.status ?? 'null'}"'),
              if (allAssignments.isNotEmpty) ...[
                Text(
                    'Ejemplo áreas disponibles: ${allAssignments.take(3).map((o) => '"${o.area}"').join(', ')}'),
                Text(
                    'Ejemplo estados disponibles: ${allAssignments.take(3).map((o) => '"${o.status}"').join(', ')}'),
              ]
            ],
          ),
        ),

        // Barra de búsqueda
        _buildSearchBar(),

        // Resumen de resultados
        _buildResultsSummary(filteredData.length),

        const SizedBox(height: 10),

        // Tabla de datos
        Expanded(
          child: filteredData.isEmpty
              ? _buildEmptyState()
              : _buildDataTable(filteredData, usersProvider),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: -3,
          intensity: 0.7,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
          color: const Color(0xFFF7FAFC),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Buscar por ID, trabajador, área o motonave...',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSummary(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mostrando $count ${count == 1 ? 'operación' : 'operaciones'}',
            style: const TextStyle(
              color: Color(0xFF718096),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Período: ${widget.periodName}',
            style: const TextStyle(
              color: Color(0xFF4A5568),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<Operation> data, WorkersProvider usersProvider) {
    debugPrint('=== CONSTRUYENDO TABLA ===');
    debugPrint('Datos para tabla: ${data.length} operaciones');

    final rows = _buildExpandedRows(data);
    debugPrint('Filas generadas: ${rows.length}');

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            const Color(0xFFF7FAFC),
          ),
          columnSpacing: 24,
          horizontalMargin: 16,
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          columns: [
            _buildDataColumn('ID Op.', 0),
            _buildDataColumn('Fecha Inicial', 1),
            _buildDataColumn('Hora Inicial', 2),
            _buildDataColumn('Nombre Completo', 3),
            _buildDataColumn('Documento', 4),
            _buildDataColumn('Área', 5),
            _buildDataColumn('Zona', 6),
            _buildDataColumn('Motonave', 7),
            _buildDataColumn('Tarea', 8),
            _buildDataColumn('Turno', 9),
            _buildDataColumn('Fecha Fin', 10),
            _buildDataColumn('Hora Fin', 11),
            _buildDataColumn('Estado', 12),
          ],
          rows: rows,
        ),
      ),
    );
  }

  // Método para expandir las filas con un trabajador por fila (igual que en Excel)
  List<DataRow> _buildExpandedRows(List<Operation> data) {
    debugPrint('=== CONSTRUYENDO FILAS ===');
    List<DataRow> rows = [];

    // Para alternar colores por operación
    int? lastOperationId;
    int currentOperationOrder = 0;

    for (var assignment in data) {
      debugPrint('Procesando operación ${assignment.id}:');
      debugPrint('  - Área: ${assignment.area}');
      debugPrint('  - Grupos: ${assignment.groups.length}');

      // Determinar si es una nueva operación
      bool isNewOperation = lastOperationId != assignment.id;
      if (isNewOperation) {
        lastOperationId = assignment.id;
        currentOperationOrder++;
      }

      // Color de fondo para filas de la misma operación
      final backgroundColor = currentOperationOrder % 2 == 0
          ? const Color(0xFFF7FAFC)
          : const Color(0xFFEDF2F7);

      // Obtener información adicional
      final taskName = _getTaskName(assignment);
      final clientName = _getClientName(assignment.clientId);
      final supervisorNames = _getSupervisorNames(assignment.inChagers);

      debugPrint('  - Tarea: $taskName');
      debugPrint('  - Cliente: $clientName');
      debugPrint('  - Supervisores: $supervisorNames');

      if (assignment.groups.isEmpty) {
        debugPrint('  - Sin grupos, creando fila básica');
        // Operación sin grupos
        rows.add(
          DataRow(
            color: MaterialStateProperty.all(backgroundColor),
            cells: [
              DataCell(Text(assignment.id?.toString() ?? 'N/A')),
              DataCell(Text(DateFormat('dd/MM/yyyy').format(assignment.date))),
              DataCell(Text(assignment.time)),
              DataCell(const Text('Sin asignar')),
              DataCell(const Text('-')),
              DataCell(Text(assignment.area)),
              DataCell(
                  Text('${assignment.zone == 0 ? 'N/A' : assignment.zone}')),
              DataCell(Text(assignment.motorship ?? 'N/A')),
              DataCell(Text(taskName)),
              DataCell(const Text('N/A')),
              DataCell(Text(assignment.endDate != null
                  ? DateFormat('dd/MM/yyyy').format(assignment.endDate!)
                  : 'N/A')),
              DataCell(Text(assignment.endTime ?? 'N/A')),
              DataCell(_buildStatusWidget(assignment.status)),
            ],
          ),
        );
      } else {
        // Procesar cada grupo
        for (int groupIndex = 0;
            groupIndex < assignment.groups.length;
            groupIndex++) {
          final group = assignment.groups[groupIndex];
          final shiftName = 'Turno ${groupIndex + 1}';

          debugPrint(
              '  - Grupo $groupIndex: ${group.workers.length} trabajadores');

          if (group.workers.isEmpty) {
            debugPrint('    - Grupo sin trabajadores');
            // Grupo sin trabajadores
            rows.add(
              DataRow(
                color: MaterialStateProperty.all(backgroundColor),
                cells: [
                  DataCell(Text(assignment.id?.toString() ?? 'N/A')),
                  DataCell(
                      Text(DateFormat('dd/MM/yyyy').format(assignment.date))),
                  DataCell(Text(group.startTime ?? assignment.time)),
                  DataCell(const Text('Sin asignar')),
                  DataCell(const Text('-')),
                  DataCell(Text(assignment.area)),
                  DataCell(Text(
                      '${assignment.zone == 0 ? 'N/A' : assignment.zone}')),
                  DataCell(Text(assignment.motorship ?? 'N/A')),
                  DataCell(Text(taskName)),
                  DataCell(Text(shiftName)),
                  DataCell(Text(_getEndDate(assignment, group))),
                  DataCell(Text(_getEndTime(assignment, group))),
                  DataCell(_buildStatusWidget(assignment.status)),
                ],
              ),
            );
          } else {
            // Procesar cada trabajador del grupo
            for (final workerId in group.workers) {
              String workerName = 'Trabajador #$workerId';
              String workerDni = '-';

              // Buscar datos del trabajador
              if (group.workersData != null && group.workersData!.isNotEmpty) {
                final workerData = group.workersData!
                    .where((w) => w.id == workerId)
                    .firstOrNull;

                if (workerData != null) {
                  workerName = workerData.name;
                  workerDni = workerData.document.isNotEmpty
                      ? workerData.document
                      : workerData.code;
                }
              } else {
                // Buscar en el provider de trabajadores
                final workersProvider =
                    Provider.of<WorkersProvider>(context, listen: false);
                final worker = workersProvider.getWorkerById(workerId);
                if (worker != null) {
                  workerName = worker.name;
                  workerDni = worker.document.isNotEmpty
                      ? worker.document
                      : worker.code;
                }
              }

              debugPrint('    - Trabajador: $workerName ($workerDni)');

              rows.add(
                DataRow(
                  color: MaterialStateProperty.all(backgroundColor),
                  cells: [
                    DataCell(Text(assignment.id?.toString() ?? 'N/A')),
                    DataCell(
                        Text(DateFormat('dd/MM/yyyy').format(assignment.date))),
                    DataCell(Text(group.startTime ?? assignment.time)),
                    DataCell(Text(workerName)),
                    DataCell(Text(workerDni)),
                    DataCell(Text(assignment.area)),
                    DataCell(Text(
                        '${assignment.zone == 0 ? 'N/A' : assignment.zone}')),
                    DataCell(Text(assignment.motorship ?? 'N/A')),
                    DataCell(Text(taskName)),
                    DataCell(Text(shiftName)),
                    DataCell(Text(_getEndDate(assignment, group))),
                    DataCell(Text(_getEndTime(assignment, group))),
                    DataCell(_buildStatusWidget(assignment.status)),
                  ],
                ),
              );
            }
          }
        }
      }
    }

    debugPrint('Total filas creadas: ${rows.length}');
    return rows;
  }

  // Métodos auxiliares para obtener información adicional
  String _getTaskName(Operation assignment) {
    try {
      final tasksProvider = Provider.of<TasksProvider>(context, listen: false);
      if (assignment.groups.isNotEmpty) {
        final firstGroup = assignment.groups.first;
        if (firstGroup.serviceId > 0) {
          return tasksProvider.getTaskNameByIdService(firstGroup.serviceId);
        }
      }
      return 'Tarea no especificada';
    } catch (e) {
      return 'Tarea desconocida';
    }
  }

  String _getClientName(int clientId) {
    try {
      final clientsProvider =
          Provider.of<ClientsProvider>(context, listen: false);
      final client = clientsProvider.getClientById(clientId);
      return client.name;
    } catch (e) {
      return 'Cliente desconocido';
    }
  }

  String _getSupervisorNames(List<int> chargerIds) {
    try {
      final chargersProvider =
          Provider.of<ChargersOpProvider>(context, listen: false);
      final supervisorNames = <String>[];
      for (final chargerId in chargerIds) {
        final charger = chargersProvider.chargers
            .where((c) => c.id == chargerId)
            .firstOrNull;
        if (charger != null) {
          supervisorNames.add(charger.name);
        }
      }
      return supervisorNames.isNotEmpty
          ? supervisorNames.join(', ')
          : 'Sin supervisor';
    } catch (e) {
      return 'Supervisor desconocido';
    }
  }

  String _getEndDate(Operation assignment, group) {
    if (group.endDate != null && group.endDate!.isNotEmpty) {
      try {
        final endDate = DateTime.parse(group.endDate!);
        return DateFormat('dd/MM/yyyy').format(endDate);
      } catch (e) {
        // Si falla el parsing del grupo, usar la fecha de la operación
      }
    }

    if (assignment.endDate != null) {
      return DateFormat('dd/MM/yyyy').format(assignment.endDate!);
    }

    return 'N/A';
  }

  String _getEndTime(Operation assignment, group) {
    return group.endTime ?? assignment.endTime ?? 'N/A';
  }

  DataColumn _buildDataColumn(String label, int columnIndex) {
    return DataColumn(
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onSort: (columnIndex, ascending) {
        setState(() {
          _sortColumnIndex = columnIndex;
          _sortAscending = ascending;
        });
      },
    );
  }

  Widget _buildStatusWidget(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        color = const Color(0xFF38A169);
        break;
      case 'INPROGRESS':
        color = const Color(0xFF3182CE);
        break;
      case 'PENDING':
        color = const Color(0xFFDD6B20);
        break;
      case 'CANCELED':
        color = const Color(0xFFE53E3E);
        break;
      default:
        color = const Color(0xFF718096);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        normalizeStatus(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Color(0xFFCBD5E0),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay operaciones disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF718096),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta cambiar los filtros o el período de fechas',
            style: TextStyle(
              color: const Color(0xFF718096).withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          NeumorphicButton(
            style: NeumorphicStyle(
              depth: 2,
              intensity: 0.7,
              color: const Color(0xFFF7FAFC),
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
            child: const Text(
              'Limpiar búsqueda',
              style: TextStyle(
                color: Color(0xFF3182CE),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Función helper para normalizar estados (agregar al final del archivo)
String normalizeStatus(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
      return 'Completada';
    case 'INPROGRESS':
      return 'En Curso';
    case 'PENDING':
      return 'Pendiente';
    case 'CANCELED':
      return 'Cancelada';
    default:
      return status;
  }
}
