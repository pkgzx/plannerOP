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

  // Datos de ejemplo para la tabla
  final List<Map<String, dynamic>> _allData = [
    {
      'id': '001',
      'worker': 'Carlos Méndez',
      'area': 'Zona Norte',
      'task': 'Mantenimiento preventivo',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'status': 'Completada',
      'hours': 8.5,
      'efficiency': 95,
    },
    {
      'id': '002',
      'worker': 'Ana Gutiérrez',
      'area': 'Zona Centro',
      'task': 'Inspección de equipos',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'status': 'Completada',
      'hours': 6.0,
      'efficiency': 88,
    },
    {
      'id': '003',
      'worker': 'Roberto Sánchez',
      'area': 'Zona Sur',
      'task': 'Reparación de instalación',
      'date': DateTime.now().subtract(const Duration(days: 4)),
      'status': 'Completada',
      'hours': 9.0,
      'efficiency': 92,
    },
    {
      'id': '004',
      'worker': 'Laura Torres',
      'area': 'Zona Este',
      'task': 'Optimización de procesos',
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'status': 'Completada',
      'hours': 5.5,
      'efficiency': 97,
    },
    {
      'id': '005',
      'worker': 'Miguel Díaz',
      'area': 'Zona Oeste',
      'task': 'Actualización de sistemas',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'En progreso',
      'hours': 3.0,
      'efficiency': 0,
    },
    {
      'id': '006',
      'worker': 'Sofía Vega',
      'area': 'Zona Norte',
      'task': 'Auditoría de procesos',
      'date': DateTime.now().subtract(const Duration(days: 6)),
      'status': 'Completada',
      'hours': 7.0,
      'efficiency': 90,
    },
    {
      'id': '007',
      'worker': 'Juan Morales',
      'area': 'Zona Centro',
      'task': 'Revisión de protocolos',
      'date': DateTime.now().subtract(const Duration(days: 8)),
      'status': 'Completada',
      'hours': 6.5,
      'efficiency': 85,
    },
    {
      'id': '008',
      'worker': 'Patricia Herrera',
      'area': 'Zona Sur',
      'task': 'Implementación de red',
      'date': DateTime.now().subtract(const Duration(days: 9)),
      'status': 'Completada',
      'hours': 10.0,
      'efficiency': 91,
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
            data['id'].toLowerCase().contains(searchLower);
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
        case 6: // Horas
          comparison = a['hours'].compareTo(b['hours']);
          break;
        case 7: // Eficiencia
          comparison = a['efficiency'].compareTo(b['efficiency']);
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
        ),

        // Resumen de resultados
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mostrando ${_filteredData.length} ${_filteredData.length == 1 ? 'resultado' : 'resultados'}',
                style: const TextStyle(
                  color: Color(0xFF718096),
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Lógica para exportar resultados
                },
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Exportar'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF3182CE),
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
                        _buildDataColumn('Horas', 6),
                        _buildDataColumn('Eficiencia', 7),
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
                            DataCell(Text('${data['hours']}h')),
                            DataCell(
                                _buildEfficiencyWidget(data['efficiency'])),
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

  Widget _buildEfficiencyWidget(int efficiency) {
    Color color;

    if (efficiency == 0) {
      return const Text('-');
    } else if (efficiency >= 90) {
      color = const Color(0xFF38A169);
    } else if (efficiency >= 80) {
      color = const Color(0xFF3182CE);
    } else {
      color = const Color(0xFFDD6B20);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: efficiency / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$efficiency%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Color(0xFFCBD5E0),
          ),
          const SizedBox(height: 16),
          const Text(
            'No se encontraron resultados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF718096),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta cambiar los filtros o términos de búsqueda',
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
              'Limpiar filtros',
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
