import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:plannerop/widgets/reports/report_filter.dart';
import 'package:plannerop/widgets/reports/report_summary.dart';
import 'package:plannerop/widgets/reports/report_data_table.dart';
import 'package:plannerop/widgets/reports/export_options.dart';

class ReportesTab extends StatefulWidget {
  const ReportesTab({Key? key}) : super(key: key);

  @override
  State<ReportesTab> createState() => _ReportesTabState();
}

class _ReportesTabState extends State<ReportesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = "Semana";
  String _selectedArea = "Todas";
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isFiltering = false;
  bool _isExporting = false;

  final List<String> _periods = [
    "Día",
    "Semana",
    "Mes",
    "Trimestre",
    "Personalizado"
  ];
  final List<String> _areas = [
    "Todas",
    "Zona Norte",
    "Zona Sur",
    "Zona Este",
    "Zona Oeste",
    "Zona Centro"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    if (_tabController.length != 2) {
      _tabController.dispose();
      _tabController = TabController(length: 2, vsync: this);
    }
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE0E5EC),
        centerTitle: true,
        title: const Text(
          'Reportes',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFiltering ? Icons.filter_list_off : Icons.filter_list,
              color: const Color(0xFF3182CE),
            ),
            onPressed: _toggleFilterPanel,
          ),
          IconButton(
            icon: Icon(
              _isExporting ? Icons.close : Icons.download,
              color: const Color(0xFF3182CE),
            ),
            onPressed: _toggleExportPanel,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3182CE),
          unselectedLabelColor: const Color(0xFF718096),
          indicatorColor: const Color(0xFF3182CE),
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: 'Detalles'),
          ],
        ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Exportando en formato $format'),
                      backgroundColor: const Color(0xFF3182CE),
                    ),
                  );
                  setState(() {
                    _isExporting = false;
                  });
                },
              ),

            // Filtro seleccionado
            if (!_isFiltering && !_isExporting) _buildActiveFilters(),

            // Contenido principal
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Pestaña de Resumen
                  ReportSummary(
                    periodName: _selectedPeriod,
                    startDate: _startDate,
                    endDate: _endDate,
                    area: _selectedArea,
                  ),

                  // Pestaña de Detalles
                  ReportDataTable(
                    periodName: _selectedPeriod,
                    startDate: _startDate,
                    endDate: _endDate,
                    area: _selectedArea,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: const Color(0xFFF7FAFC),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_outlined,
              size: 16, color: Color(0xFF718096)),
          const SizedBox(width: 8),
          Text(
            "Filtros: $dateRange ${_selectedArea != 'Todas' ? '• $_selectedArea' : ''}",
            style: const TextStyle(
              color: Color(0xFF4A5568),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _toggleFilterPanel,
            child: const Text(
              "Cambiar",
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
