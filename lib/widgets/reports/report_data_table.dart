import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/store/workers.dart';
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

  List<Assignment> _getFilteredData(List<Assignment> allAssignments) {
    final filtered = allAssignments.where((data) {
      // Filtrar por área
      if (widget.area != 'Todas' && data.area != widget.area) {
        return false;
      }

      // Filtrar por fecha
      final date = data.date;
      if (date.isBefore(widget.startDate) || date.isAfter(widget.endDate)) {
        return false;
      }

      // Filtrar por zona - CORREGIDO PARA MANEJAR DIFERENTES TIPOS DE DATOS
      if (widget.zone != null) {
        // Convertir la zona de la asignación a int para una comparación consistente
        int? assignmentZone;
        if (data.zone != null) {
          try {
            // Intentar convertir la zona a int, ya que podría ser string
            assignmentZone = int.tryParse(data.zone.toString());
          } catch (e) {
            assignmentZone = null;
          }
        }

        // Si no se pudo convertir o es null, no coincide con el filtro
        if (assignmentZone != widget.zone) {
          return false;
        }
      }

      debugPrint('Zona}}: ${widget.zone} - ${data.zone}');

      // Filtrar por motonave
      if (widget.motorship != null && widget.motorship!.isNotEmpty) {
        if (data.motorship == null || data.motorship != widget.motorship) {
          return false;
        }
      }

      // Filtrar por estado
      if (widget.status != null && widget.status!.isNotEmpty) {
        String normalizedStatus = _normalizeStatus(data.status);
        if (normalizedStatus != widget.status) {
          return false;
        }
      }

      // Filtrar por búsqueda
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        return data.workers.any((worker) =>
                worker.name.toString().toLowerCase().contains(searchLower)) ||
            data.task.toLowerCase().contains(searchLower) ||
            (data.motorship?.toLowerCase().contains(searchLower) ?? false) ||
            data.area.toLowerCase().contains(searchLower);
      }

      return true;
    }).toList();

    // Ordenar datos
    filtered.sort((a, b) {
      var comparison = 0;
      switch (_sortColumnIndex) {
        case 1: // Trabajador (primer trabajador si hay varios)
          final aWorkerName =
              a.workers.isNotEmpty ? a.workers[0].name.toString() : '';
          final bWorkerName =
              b.workers.isNotEmpty ? b.workers[0].name.toString() : '';
          comparison = aWorkerName.compareTo(bWorkerName);
          break;
        case 2: // Área
          comparison = a.area.compareTo(b.area);
          break;
        case 3: // Tarea
          comparison = a.task.compareTo(b.task);
          break;
        case 4: // Fecha
          comparison = a.date.compareTo(b.date);
          break;
        case 5: // Estado
          comparison = a.status.compareTo(b.status);
          break;
        case 6: // Hora de ingreso
          comparison = a.time.compareTo(b.time);
          break;
        case 7: // Hora de finalización
          final aEndTime = a.endTime ?? '';
          final bEndTime = b.endTime ?? '';
          if (aEndTime.isEmpty && bEndTime.isEmpty) {
            comparison = 0;
          } else if (aEndTime.isEmpty) {
            comparison = 1; // Vacío va después
          } else if (bEndTime.isEmpty) {
            comparison = -1; // Vacío va después
          } else {
            comparison = aEndTime.compareTo(bEndTime);
          }
          break;
        case 8: // Supervisor

          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  // Método auxiliar para normalizar estados
  String _normalizeStatus(String status) {
    debugPrint('Status: $status');

    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return 'Completada';
      case 'INPROGRESS':
        return 'En curso';
      case 'PENDING':
        return 'Pendiente';
      case 'CANCELED':
        return 'Cancelada';
      default:
        return "N/A";
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsProvider = Provider.of<AssignmentsProvider>(context);
    final usersProvider = Provider.of<WorkersProvider>(context, listen: false);

    // Obtenemos las asignaciones del provider
    final allAssignments = assignmentsProvider.assignments;

    // Aplicamos los filtros a las asignaciones
    final filteredData = _getFilteredData(allAssignments);

    return Column(
      children: [
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
              hintText: 'Buscar por ID, trabajador o tarea...',
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
            'Mostrando $count ${count == 1 ? 'asignación' : 'asignaciones'}',
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

  Widget _buildDataTable(List<Assignment> data, WorkersProvider usersProvider) {
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
            _buildDataColumn('Fecha Inicial', 0),
            _buildDataColumn('Hora Inicial', 1),
            _buildDataColumn('Nombre Completo', 2),
            _buildDataColumn('Documento', 3),
            _buildDataColumn('Área', 4),
            _buildDataColumn('Zona', 5),
            _buildDataColumn('Motonave', 6),
            _buildDataColumn('Tarea', 7),
            _buildDataColumn('Fecha Finalización', 8),
            _buildDataColumn('Hora Finalización', 9),
            _buildDataColumn('Estado', 10),
          ],
          rows: _buildExpandedRows(data),
        ),
      ),
    );
  }

  // Nuevo método para expandir las filas con un trabajador por fila como en el Excel
  List<DataRow> _buildExpandedRows(List<Assignment> data) {
    List<DataRow> rows = [];

    // Para alternar colores por operación
    int? lastOperationId;
    int currentOperationOrder = 0;

    for (var assignment in data) {
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

      // Si no hay trabajadores, crear una fila con "Sin asignar"
      if (assignment.workers.isEmpty) {
        rows.add(
          DataRow(
            color: MaterialStateProperty.all(backgroundColor),
            cells: [
              DataCell(Text(DateFormat('dd/MM/yyyy').format(assignment.date))),
              DataCell(Text(assignment.time)),
              DataCell(const Text('Sin asignar')),
              DataCell(const Text('-')),
              DataCell(Text(assignment.area)),
              DataCell(
                  Text('${assignment.zone == 0 ? 'N/A' : assignment.zone}')),
              DataCell(Text(assignment.motorship ?? 'N/A')),
              DataCell(Text(assignment.task)),
              DataCell(assignment.endDate != null
                  ? Text(DateFormat('dd/MM/yyyy').format(assignment.endDate!))
                  : const Text('')),
              DataCell(Text(assignment.endTime ?? '')),
              DataCell(_buildStatusWidget(assignment.status)),
            ],
          ),
        );
      } else {
        // Crear una fila para CADA trabajador
        for (var worker in assignment.workers) {
          String workerName = '';
          String workerDocument = '';

          // Obtener nombre y documento según el tipo de datos
          if (worker is Map<String, dynamic>) {
            workerName = worker.name ?? '';
            workerDocument = worker.document ?? '';
          } else if (worker is Worker) {
            workerName = worker.name;
            workerDocument = worker.document;
          }

          rows.add(
            DataRow(
              color: MaterialStateProperty.all(backgroundColor),
              cells: [
                DataCell(
                    Text(DateFormat('dd/MM/yyyy').format(assignment.date))),
                DataCell(Text(assignment.time)),
                DataCell(Text(workerName)),
                DataCell(Text(workerDocument)),
                DataCell(Text(assignment.area)),
                DataCell(
                    Text('${assignment.zone == 0 ? 'N/A' : assignment.zone}')),
                DataCell(Text(assignment.motorship ?? 'N/A')),
                DataCell(Text(assignment.task)),
                DataCell(assignment.endDate != null
                    ? Text(DateFormat('dd/MM/yyyy').format(assignment.endDate!))
                    : const Text('')),
                DataCell(Text(assignment.endTime ?? '')),
                DataCell(_buildStatusWidget(assignment.status)),
              ],
            ),
          );
        }
      }
    }

    return rows;
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
        _normalizeStatus(status),
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
            'No hay asignaciones disponibles',
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
