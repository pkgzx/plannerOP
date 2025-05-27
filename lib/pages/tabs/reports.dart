import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/store/operations.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/reports/charts/areaChart.dart';
import 'package:plannerop/widgets/reports/reportFilter.dart';
import 'package:plannerop/widgets/reports/reportDataTable.dart';
import 'package:plannerop/widgets/reports/exportOptions.dart';
import 'package:plannerop/widgets/reports/charts/shipPersonnelChart.dart';
import 'package:plannerop/widgets/reports/charts/zoneDistributionChart.dart';
import 'package:plannerop/widgets/reports/charts/workerStatusChart.dart';
import 'package:plannerop/widgets/reports/charts/serviceTrendChart.dart';
import 'package:provider/provider.dart';

class ReportesTab extends StatefulWidget {
  const ReportesTab({Key? key}) : super(key: key);

  @override
  State<ReportesTab> createState() => _ReportesTabState();
}

class _ReportesTabState extends State<ReportesTab> {
  // Filtros actuales
  String _selectedPeriod = "Hoy";
  String _selectedArea = "Todas";
  int? _selectedZone; // Filtro de zona
  String? _selectedMotorship; // Filtro de motonave
  String? _selectedStatus; // Filtro de estado
  DateTime _startDate = DateTime.now() // llevar a las 00:00
      .subtract(Duration(hours: DateTime.now().hour))
      .subtract(Duration(minutes: DateTime.now().minute));
  DateTime _endDate = DateTime.now()
      .add(Duration(days: 1))
      .subtract(Duration(hours: DateTime.now().hour))
      .subtract(Duration(minutes: DateTime.now().minute))
      .subtract(Duration(seconds: DateTime.now().second));
  // llevar a las 23:59

  bool _isFiltering = false;
  bool _isExporting = false;
  bool _showCharts = true; // Estado para alternar entre gráficos y tabla
  String _selectedChart =
      "Distribución por Áreas"; // Gráfico seleccionado por defecto

  // Opciones para los filtros
  final List<String> _periods = ["Hoy", "Mes", "Personalizado"];

  final List<String> _statuses = [
    "Completada",
    "En curso",
    "Pendiente",
    "Cancelada"
  ];

  List<String> _areas = [];
  List<int> _zones =
      List.generate(10, (index) => index + 1); // Zonas del 1 al 10
  List<String> _motorships = [];

  // Opciones de gráficos
  final List<Map<String, dynamic>> _chartOptions = [
    {
      'title': 'Distribución por Áreas',
      'icon': Icons.pie_chart,
    },
    {
      'title': 'Personal por Buque',
      'icon': Icons.directions_boat_filled_outlined,
    },
    {
      'title': 'Distribución por Zonas',
      'icon': Icons.pie_chart_outline_rounded,
    },
    {
      'title': 'Estado de Trabajadores',
      'icon': Icons.people_outline_rounded,
    },
    {
      'title': 'Tendencia de Servicios',
      'icon': Icons.trending_up_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Cargar datos para los filtros cuando se inicia el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFilterData();
    });
  }

  // Método para cargar datos de filtro
  void _loadFilterData() {
    final assignmentsProvider =
        Provider.of<OperationsProvider>(context, listen: false);
    final List<Operation> assignments = assignmentsProvider.assignments;

    // Extraer áreas únicas
    final areasSet = assignments.map((a) => a.area).toSet();
    final areasList = ['Todas', ...areasSet];

    // Extraer motonaves únicas
    final motorshipsSet = assignments
        .where((a) => a.motorship != null && a.motorship!.isNotEmpty)
        .map((a) => a.motorship!)
        .toSet();
    final motorshipsList = motorshipsSet.toList()..sort();

    setState(() {
      _areas = areasList;
      _motorships = motorshipsList;
    });
  }

  // Método para aplicar filtros
  void _applyFilter({
    String? period,
    String? area,
    int? zone,
    String? motorship,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    setState(() {
      if (period != null) _selectedPeriod = period;
      if (area != null) _selectedArea = area;
      _selectedZone = zone;
      _selectedMotorship = motorship;
      _selectedStatus = status;
      if (startDate != null) _startDate = startDate;
      if (endDate != null) _endDate = endDate;
      _isFiltering = false;
    });
  }

  // Mostrar panel de filtro
  void _toggleFilterPanel() {
    setState(() {
      _isFiltering = !_isFiltering;
      if (_isFiltering) _isExporting = false;
    });
  }

  // Mostrar panel de exportación
  void _toggleExportPanel() {
    setState(() {
      _isExporting = !_isExporting;
      if (_isExporting) _isFiltering = false;
    });
  }

  // Alternar entre vista de gráficos y tabla
  void _toggleView() {
    setState(() {
      _showCharts = !_showCharts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: const Color(0xFF4299E1),
        centerTitle: false,
        title: const Text(
          'Reportes de Operaciones',
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
                zones: _zones,
                motorships: _motorships,
                statuses: _statuses,
                selectedPeriod: _selectedPeriod,
                selectedArea: _selectedArea,
                selectedZone: _selectedZone,
                selectedMotorship: _selectedMotorship,
                selectedStatus: _selectedStatus,
                startDate: _startDate,
                endDate: _endDate,
                onApply: _applyFilter,
                isChartsView: _showCharts,
              ),

            if (_isExporting)
              ExportOptions(
                periodName: _selectedPeriod,
                startDate: _startDate.subtract(Duration(days: 1)),
                endDate: _endDate,
                area: _selectedArea,
                zone: _selectedZone,
                motorship: _selectedMotorship,
                status: _selectedStatus,
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
                      startDate: DateTime(_startDate.year, _startDate.month,
                              _startDate.day, 0, 0, 0)
                          .subtract(Duration(days: 1)),
                      endDate: DateTime(_endDate.year, _endDate.month,
                          _endDate.day, 23, 59, 59),
                      area: _selectedArea,
                      zone: _selectedZone,
                      motorship: _selectedMotorship,
                      status: _selectedStatus,
                    ),
            ),
          ],
        ),
      ),
      // Mostrar el botón flotante solo cuando estamos en la vista de tabla (no gráficos)
      floatingActionButton: !_showCharts
          ? FloatingActionButton.extended(
              onPressed: _toggleExportPanel,
              backgroundColor: const Color(0xFF4299E1),
              icon: const Icon(Icons.file_download),
              label: const Text('Exportar'),
              foregroundColor: Colors.white,
            )
          : null,
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
              // selectedItemBuilder: (context) {
              //   return _chartOptions.map((item) {
              //     return Row(
              //       children: [
              //         Icon(_getSelectedChartIcon(),
              //             color: const Color(0xFF4299E1), size: 20),
              //         const SizedBox(width: 12),
              //         Text(_selectedChart),
              //       ],
              //     );
              //   }).toList();
              // },
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

  // Widget para mostrar el gráfico seleccionado con todos los filtros
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
                zone: _selectedZone,
                motorship: _selectedMotorship,
                status: _selectedStatus,
              ),
            ),
          ),
        );
      case 'Distribución por Áreas':
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
              child: AreaDistributionChart(
                startDate: _startDate,
                endDate: _endDate,
                area: _selectedArea,
                zone: _selectedZone,
                status: _selectedStatus,
                motorship: _selectedMotorship,
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
                zone: _selectedZone,
                motorship: _selectedMotorship,
                status: _selectedStatus,
              ),
            ),
          ),
        );
      case 'Estado de Trabajadores':
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
                zone: _selectedZone,
                motorship: _selectedMotorship,
                status: _selectedStatus,
              ),
            ),
          ),
        );
      default:
        return const Center(child: Text('Gráfico no disponible'));
    }
  }

  // Mostrar filtros activos en formato chip
  Widget _buildActiveFilters() {
    String dateRange;
    if (_selectedPeriod == "Personalizado") {
      dateRange =
          "${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}";
    } else {
      dateRange = _selectedPeriod;
    }

    List<String> activeFilters = [];

    // Añadir filtros activos
    activeFilters.add("Periodo: $dateRange");
    if (_selectedArea != 'Todas') activeFilters.add("Área: $_selectedArea");
    if (_selectedZone != null) activeFilters.add("Zona: $_selectedZone");
    if (_selectedMotorship != null) {
      activeFilters.add("Motonave: $_selectedMotorship");
    }
    if (_selectedStatus != null) activeFilters.add("Estado: $_selectedStatus");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: const Color(0xFFF7FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt_outlined,
                  size: 16, color: Color(0xFF718096)),
              const SizedBox(width: 8),
              const Text(
                "Filtros activos:",
                style: TextStyle(
                  color: Color(0xFF4A5568),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
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
          // Mostrar filtros activos como chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activeFilters
                .map((filter) => Chip(
                      label: Text(filter, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
