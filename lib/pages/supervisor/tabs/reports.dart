import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/reports/report_filter.dart';
import 'package:plannerop/widgets/reports/report_data_table.dart';
import 'package:plannerop/widgets/reports/export_options.dart';
import 'package:plannerop/widgets/reports/charts/ship_personnel_chart.dart';
import 'package:plannerop/widgets/reports/charts/zone_distribution_chart.dart';
import 'package:plannerop/widgets/reports/charts/worker_status_chart.dart';
import 'package:plannerop/widgets/reports/charts/service_trend_chart.dart';

class ReportesTab extends StatefulWidget {
  const ReportesTab({Key? key}) : super(key: key);

  @override
  State<ReportesTab> createState() => _ReportesTabState();
}

class _ReportesTabState extends State<ReportesTab> {
  String _selectedPeriod = "Semana";
  String _selectedArea = "Todas";
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isFiltering = false;
  bool _isExporting = false;
  bool _showCharts = true; // Estado para alternar entre gráficos y tabla
  String _selectedChart =
      "Personal por Buque"; // Gráfico seleccionado por defecto

  final List<String> _periods = [
    "Día",
    "Semana",
    "Mes",
    "Trimestre",
    "Personalizado"
  ];

  final List<String> _areas = [
    "Todas",
    "CARGA GENERAL",
    "CARGA REFRIGERADA",
    "CAFÉ",
    "ADMINISTRATIVA",
    "MANTENIMIENTO",
    "SEGURIDAD",
  ];

  final List<Map<String, dynamic>> _chartOptions = [
    {
      'title': 'Personal por Buque',
      'icon': Icons.directions_boat_filled_outlined,
    },
    {
      'title': 'Distribución por Zonas',
      'icon': Icons.pie_chart_outline_rounded,
    },
    {
      'title': 'Estado del Personal',
      'icon': Icons.people_outline_rounded,
    },
    {
      'title': 'Tendencia de Servicios',
      'icon': Icons.trending_up_rounded,
    },
  ];

  void _applyFilter({
    String? period,
    String? area,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    setState(() {
      if (period != null) _selectedPeriod = period;
      if (area != null) _selectedArea = area;
      if (startDate != null) _startDate = startDate;
      if (endDate != null) _endDate = endDate;
      _isFiltering = false;
    });
  }

  void _toggleFilterPanel() {
    setState(() {
      _isFiltering = !_isFiltering;
      if (_isFiltering) _isExporting = false;
    });
  }

  void _toggleExportPanel() {
    setState(() {
      _isExporting = !_isExporting;
      if (_isExporting) _isFiltering = false;
    });
  }

  void _toggleView() {
    setState(() {
      _showCharts = !_showCharts;
    });
  }

  // Obtener el ícono para el gráfico seleccionado
  IconData _getSelectedChartIcon() {
    final selectedOption = _chartOptions.firstWhere(
        (option) => option['title'] == _selectedChart,
        orElse: () => _chartOptions[0]);
    return selectedOption['icon'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4299E1),
        centerTitle: false,
        title: const Text(
          'Reportes de Asignaciones',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showCharts ? Icons.table_chart : Icons.bar_chart,
              color: Colors.white,
            ),
            onPressed: _toggleView,
            tooltip: _showCharts ? 'Ver tabla de datos' : 'Ver gráficos',
          ),
          IconButton(
            icon: Icon(
              _isFiltering ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: _toggleFilterPanel,
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isFiltering)
              ReportFilter(
                periods: _periods,
                areas: _areas,
                selectedPeriod: _selectedPeriod,
                selectedArea: _selectedArea,
                startDate: _startDate,
                endDate: _endDate,
                onApply: _applyFilter,
              ),

            if (_isExporting)
              ExportOptions(
                periodName: _selectedPeriod,
                startDate: _startDate,
                endDate: _endDate,
                area: _selectedArea,
                onExport: (format) {
                  showInfoToast(
                      context, "Exportando reporte en formato $format");
                  setState(() {
                    _isExporting = false;
                  });
                },
              ),

            // Filtro seleccionado
            if (!_isFiltering && !_isExporting) _buildActiveFilters(),

            // Selector de gráficos (solo visible cuando se muestran gráficos)
            if (_showCharts && !_isFiltering && !_isExporting)
              _buildChartSelector(),

            // Contenido principal - Alternando entre gráficas y tabla
            Expanded(
              child: _showCharts
                  ? _buildSelectedChart()
                  : ReportDataTable(
                      periodName: _selectedPeriod,
                      startDate: _startDate,
                      endDate: _endDate,
                      area: _selectedArea,
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleExportPanel,
        backgroundColor: const Color(0xFF4299E1),
        icon: const Icon(Icons.file_download),
        label: const Text('Exportar'),
        foregroundColor: Colors.white,
      ),
    );
  }

  // Widget para selector de gráficos
  Widget _buildChartSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              spreadRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: ButtonTheme(
            alignedDropdown: true,
            child: DropdownButton<String>(
              value: _selectedChart,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF4299E1)),
              elevation: 2,
              style: const TextStyle(
                color: Color(0xFF2D3748),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              selectedItemBuilder: (context) {
                return _chartOptions.map((item) {
                  return Row(
                    children: [
                      Icon(_getSelectedChartIcon(),
                          color: const Color(0xFF4299E1), size: 20),
                      const SizedBox(width: 12),
                      Text(_selectedChart),
                    ],
                  );
                }).toList();
              },
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedChart = newValue;
                  });
                }
              },
              items: _chartOptions
                  .map<DropdownMenuItem<String>>((Map<String, dynamic> item) {
                return DropdownMenuItem<String>(
                  value: item['title'],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(item['icon'],
                            color: const Color(0xFF4299E1), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item['title'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // Widget para mostrar el gráfico seleccionado
  Widget _buildSelectedChart() {
    switch (_selectedChart) {
      case 'Personal por Buque':
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Neumorphic(
            style: NeumorphicStyle(
              depth: 3,
              intensity: 0.6,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ShipPersonnelChart(
                startDate: _startDate,
                endDate: _endDate,
                area: _selectedArea,
              ),
            ),
          ),
        );
      case 'Distribución por Zonas':
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Neumorphic(
            style: NeumorphicStyle(
              depth: 3,
              intensity: 0.6,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ZoneDistributionChart(
                startDate: _startDate,
                endDate: _endDate,
                area: _selectedArea,
              ),
            ),
          ),
        );
      case 'Estado del Personal':
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Neumorphic(
            style: NeumorphicStyle(
              depth: 3,
              intensity: 0.6,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: WorkerStatusChart(
                startDate: _startDate,
                endDate: _endDate,
                area: _selectedArea,
              ),
            ),
          ),
        );
      case 'Tendencia de Servicios':
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Neumorphic(
            style: NeumorphicStyle(
              depth: 3,
              intensity: 0.6,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ServiceTrendChart(
                startDate: _startDate,
                endDate: _endDate,
                area: _selectedArea,
              ),
            ),
          ),
        );
      default:
        return const Center(child: Text('Gráfico no disponible'));
    }
  }

  Widget _buildActiveFilters() {
    String dateRange;
    if (_selectedPeriod == "Personalizado") {
      dateRange =
          "${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}";
    } else {
      dateRange = _selectedPeriod;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: const Color(0xFFF7FAFC),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_outlined,
              size: 16, color: Color(0xFF718096)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Periodo: $dateRange ${_selectedArea != 'Todas' ? '• Área: $_selectedArea' : ''}",
              style: const TextStyle(
                color: Color(0xFF4A5568),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _toggleFilterPanel,
            child: const Text(
              "Cambiar filtros",
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
