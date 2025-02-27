import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';

class ReportDataTable extends StatefulWidget {
  final String periodName;
  final DateTime startDate;
  final DateTime endDate;
  final String area;

  const ReportDataTable({
    Key? key,
    required this.periodName,
    required this.startDate,
    required this.endDate,
    required this.area,
  }) : super(key: key);

  @override
  State<ReportDataTable> createState() => _ReportDataTableState();
}

class _ReportDataTableState extends State<ReportDataTable> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortAscending = true;
  int _sortColumnIndex = 0;

  // Datos de ejemplo para la tabla con horas de ingreso y finalización
  final List<Map<String, dynamic>> _allData = [
    {
      'id': '001',
      'worker': 'Carlos Méndez',
      'area': 'CARGA GENERAL',
      'task': 'Mantenimiento preventivo',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'status': 'Completada',
      'startTime': '08:00',
      'endTime': '16:30',
      'supervisor': 'Juan Pérez',
    },
    {
      'id': '002',
      'worker': 'Ana Gutiérrez',
      'area': 'CARGA REFRIGERADA',
      'task': 'Inspección de equipos',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'status': 'Completada',
      'startTime': '09:00',
      'endTime': '15:00',
      'supervisor': 'María López',
    },
    {
      'id': '003',
      'worker': 'Roberto Sánchez',
      'area': 'CARGA GENERAL',
      'task': 'Reparación de instalación',
      'date': DateTime.now().subtract(const Duration(days: 4)),
      'status': 'Completada',
      'startTime': '07:30',
      'endTime': '16:30',
      'supervisor': 'Juan Pérez',
    },
    {
      'id': '004',
      'worker': 'Laura Torres',
      'area': 'CARGA REFRIGERADA',
      'task': 'Optimización de procesos',
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'status': 'Completada',
      'startTime': '10:00',
      'endTime': '15:30',
      'supervisor': 'Carlos Rodríguez',
    },
    {
      'id': '005',
      'worker': 'Miguel Díaz',
      'area': 'CARGA GENERAL',
      'task': 'Actualización de sistemas',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'En progreso',
      'startTime': '08:30',
      'endTime': null,
      'supervisor': 'Ana Martínez',
    },
    {
      'id': '006',
      'worker': 'Sofía Vega',
      'area': 'CARGA REFRIGERADA',
      'task': 'Auditoría de procesos',
      'date': DateTime.now().subtract(const Duration(days: 6)),
      'status': 'Completada',
      'startTime': '09:15',
      'endTime': '16:15',
      'supervisor': 'Carlos Rodríguez',
    },
    {
      'id': '007',
      'worker': 'Juan Morales',
      'area': 'CARGA GENERAL',
      'task': 'Revisión de protocolos',
      'date': DateTime.now().subtract(const Duration(days: 8)),
      'status': 'Completada',
      'startTime': '07:45',
      'endTime': '14:15',
      'supervisor': 'Juan Pérez',
    },
    {
      'id': '008',
      'worker': 'Patricia Herrera',
      'area': 'CARGA REFRIGERADA',
      'task': 'Implementación de red',
      'date': DateTime.now().subtract(const Duration(days: 9)),
      'status': 'Completada',
      'startTime': '08:00',
      'endTime': '18:00',
      'supervisor': 'María López',
    },
    {
      'id': '009',
      'worker': 'Eduardo Flores',
      'area': 'CAFÉ',
      'task': 'Clasificación de granos',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'En progreso',
      'startTime': '07:00',
      'endTime': null,
      'supervisor': 'Ana Martínez',
    },
    {
      'id': '010',
      'worker': 'Diana Rojas',
      'area': 'ADMINISTRATIVA',
      'task': 'Preparación de informes',
      'date': DateTime.now().subtract(const Duration(days: 10)),
      'status': 'Completada',
      'startTime': '09:00',
      'endTime': '17:00',
      'supervisor': 'Carlos Rodríguez',
    },
  ];

  List<Map<String, dynamic>> get _filteredData {
    final filtered = _allData.where((data) {
      // Filtrar por área si es necesario
      if (widget.area != 'Todas' && data['area'] != widget.area) {
        return false;
      }

      // Filtrar por fecha
      final date = data['date'] as DateTime;
      if (date.isBefore(widget.startDate) || date.isAfter(widget.endDate)) {
        return false;
      }

      // Filtrar por búsqueda
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        return data['worker'].toLowerCase().contains(searchLower) ||
            data['task'].toLowerCase().contains(searchLower) ||
            data['id'].toLowerCase().contains(searchLower) ||
            data['supervisor'].toLowerCase().contains(searchLower);
      }

      return true;
    }).toList();

    // Ordenar datos
    filtered.sort((a, b) {
      var comparison = 0;
      switch (_sortColumnIndex) {
        case 0: // ID
          comparison = a['id'].compareTo(b['id']);
          break;
        case 1: // Trabajador
          comparison = a['worker'].compareTo(b['worker']);
          break;
        case 2: // Área
          comparison = a['area'].compareTo(b['area']);
          break;
        case 3: // Tarea
          comparison = a['task'].compareTo(b['task']);
          break;
        case 4: // Fecha
          comparison = (a['date'] as DateTime).compareTo(b['date'] as DateTime);
          break;
        case 5: // Estado
          comparison = a['status'].compareTo(b['status']);
          break;
        case 6: // Hora de ingreso
          comparison = a['startTime'].compareTo(b['startTime']);
          break;
        case 7: // Hora de finalización (cuidado con null values)
          final aEndTime = a['endTime'];
          final bEndTime = b['endTime'];
          if (aEndTime == null && bEndTime == null) {
            comparison = 0;
          } else if (aEndTime == null) {
            comparison = 1; // Null va después
          } else if (bEndTime == null) {
            comparison = -1; // Null va después
          } else {
            comparison = aEndTime.compareTo(bEndTime);
          }
          break;
        case 8: // Supervisor
          comparison = a['supervisor'].compareTo(b['supervisor']);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de búsqueda
        Padding(
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
                  hintText: 'Buscar por ID, trabajador, supervisor o tarea...',
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
        ),

        // Resumen de resultados
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mostrando ${_filteredData.length} ${_filteredData.length == 1 ? 'asignación' : 'asignaciones'}',
                style: const TextStyle(
                  color: Color(0xFF718096),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Tabla de datos
        Expanded(
          child: _filteredData.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
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
                        _buildDataColumn('ID', 0),
                        _buildDataColumn('Trabajador', 1),
                        _buildDataColumn('Área', 2),
                        _buildDataColumn('Tarea', 3),
                        _buildDataColumn('Fecha', 4),
                        _buildDataColumn('Estado', 5),
                        _buildDataColumn('Hora Ingreso', 6),
                        _buildDataColumn('Hora Finalización', 7),
                        _buildDataColumn('Supervisor', 8),
                      ],
                      rows: _filteredData.map((data) {
                        return DataRow(
                          cells: [
                            DataCell(Text(data['id'])),
                            DataCell(Text(data['worker'])),
                            DataCell(Text(data['area'])),
                            DataCell(Text(data['task'])),
                            DataCell(Text(
                                DateFormat('dd/MM/yy').format(data['date']))),
                            DataCell(_buildStatusWidget(data['status'])),
                            DataCell(Text(data['startTime'])),
                            DataCell(data['endTime'] != null
                                ? Text(data['endTime'])
                                : const Text('-')),
                            DataCell(Text(data['supervisor'])),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
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
    switch (status) {
      case 'Completada':
        color = const Color(0xFF38A169);
        break;
      case 'En progreso':
        color = const Color(0xFF3182CE);
        break;
      case 'Pendiente':
        color = const Color(0xFFDD6B20);
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
        status,
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
