import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/widgets/reports/report_filter.dart';
import 'package:plannerop/widgets/reports/report_data_table.dart';
import 'package:plannerop/widgets/reports/export_options.dart';

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
              _isFiltering ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: _toggleFilterPanel,
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Exportando en formato $format'),
                      backgroundColor: const Color(0xFF4299E1),
                    ),
                  );
                  setState(() {
                    _isExporting = false;
                  });
                },
              ),

            // Filtro seleccionado
            if (!_isFiltering && !_isExporting) _buildActiveFilters(),

            // Contenido principal - Tabla de datos simplificada
            Expanded(
              child: ReportDataTable(
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
