import 'dart:io';
import 'package:flutter/material.dart' hide Border;
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart' hide Border;
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/painting.dart' show Border, BorderSide;

class ExportOptions extends StatefulWidget {
  final String periodName;
  final DateTime startDate;
  final DateTime endDate;
  final String area;
  final int? zone;
  final String? motorship;
  final String? status;
  final Function(String) onExport;

  const ExportOptions({
    Key? key,
    required this.periodName,
    required this.startDate,
    required this.endDate,
    required this.area,
    required this.onExport,
    this.zone,
    this.motorship,
    this.status,
  }) : super(key: key);

  @override
  State<ExportOptions> createState() => _ExportOptionsState();
}

class _ExportOptionsState extends State<ExportOptions> {
  late List<Assignment> _filteredAssignments;

  @override
  void initState() {
    super.initState();
    // Inicializar la lista filtrada cuando se carga el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _filteredAssignments = _getFilteredAssignments();
    });
  }

  // Método para filtrar las asignaciones según los criterios del reporte
  List<Assignment> _getFilteredAssignments() {
    final assignmentsProvider =
        Provider.of<AssignmentsProvider>(context, listen: false);

    return assignmentsProvider.assignments.where((assignment) {
      // Filtrar por área si no es "Todas"
      if (widget.area != 'Todas' && assignment.area != widget.area) {
        return false;
      }

      // Filtrar por fecha
      final assignmentDate = assignment.date;
      if (assignmentDate.isBefore(widget.startDate) ||
          assignmentDate.isAfter(widget.endDate.add(const Duration(days: 1)))) {
        return false;
      }

      // Filtrar por zona
      if (widget.zone != null) {
        if (assignment.zone == null ||
            assignment.zone != widget.zone.toString()) {
          return false;
        }
      }

      // Filtrar por motonave
      if (widget.motorship != null && widget.motorship!.isNotEmpty) {
        if (assignment.motorship == null ||
            assignment.motorship != widget.motorship) {
          return false;
        }
      }

      // Filtrar por estado
      if (widget.status != null && widget.status!.isNotEmpty) {
        String normalizedStatus = _getHumanReadableStatus(assignment.status);
        if (normalizedStatus != widget.status) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _simulateExport(String type) {
    // Mostrar un diálogo de "cargando"
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Row(
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF3182CE),
                ),
                const SizedBox(width: 24),
                Text(
                  "Preparando $type...",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Simular una operación que toma tiempo
    Future.delayed(const Duration(milliseconds: 1500), () {
      Navigator.pop(context); // Cerrar diálogo de carga

      // Compartir el informe según el tipo seleccionado
      switch (type) {
        case 'Excel':
          _exportToExcel();
          break;
      }
    });
  }

  // Método para obtener información formateada de los assignments
  Future<void> _exportToExcel() async {
    try {
      // Notificar que estamos generando el Excel
      widget.onExport('Generando Excel...');

      // Obtener asignaciones filtradas
      final filteredAssignments = _getFilteredAssignments();

      // Ordenar asignaciones por fecha para mejor organización
      filteredAssignments.sort((a, b) => a.date.compareTo(b.date));

      // Crear un archivo Excel
      final excel = Excel.createExcel();
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Crear nuestra hoja personalizada
      final Sheet sheet = excel['Reporte de Operaciones'];

      // Añadir título con formato
      final titleCell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
      titleCell.value = _getReportTitle();
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        fontColorHex: '#1A365D',
      );

      // Determinar número total de columnas (ahora son 11)
      final int totalColumns = 11;

      // Combinar celdas para el título
      sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
          CellIndex.indexByColumnRow(
              columnIndex: totalColumns - 1, rowIndex: 0));

      // Fecha actual al inicio
      int rowIndex = 1;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = 'Fecha:';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = DateFormat('dd/MM/yyyy').format(DateTime.now());
      rowIndex++;

      // RESUMEN
      rowIndex++;
      final summaryTitleCell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      summaryTitleCell.value = 'RESUMEN';
      summaryTitleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        fontColorHex: '#1A365D',
        backgroundColorHex: '#EDF2F7',
      );
      sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
      rowIndex++;

      // Estadísticas detalladas con normalización de estados
      int completedCount = filteredAssignments
          .where((a) => a.status.toUpperCase() == 'COMPLETED')
          .length;
      int inProgressCount = filteredAssignments
          .where((a) => a.status.toUpperCase() == 'INPROGRESS')
          .length;
      int pendingCount = filteredAssignments
          .where((a) => a.status.toUpperCase() == 'PENDING')
          .length;
      int canceledCount = filteredAssignments
          .where((a) => a.status.toUpperCase() == 'CANCELED')
          .length;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = 'Total de operaciones:';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = filteredAssignments.length;
      rowIndex++;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = 'Completadas:';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = completedCount;
      rowIndex++;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = 'En curso:';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = inProgressCount;
      rowIndex++;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = 'Pendientes:';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = pendingCount;
      rowIndex++;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = 'Canceladas:';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = canceledCount;
      rowIndex++;

      // Añadir metadatos adicionales después del resumen
      rowIndex++;
      if (widget.area != 'Todas') {
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = 'Área:';
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = widget.area;
        rowIndex++;
      }

      // Mostrar filtros adicionales en el reporte si están aplicados
      if (widget.zone != null) {
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = 'Zona:';
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = widget.zone.toString();
        rowIndex++;
      }

      if (widget.motorship != null && widget.motorship!.isNotEmpty) {
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = 'Motonave:';
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = widget.motorship;
        rowIndex++;
      }

      if (widget.status != null && widget.status!.isNotEmpty) {
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = 'Estado:';
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = widget.status;
        rowIndex++;
      }

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = 'Período:';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = _getDateRange();
      rowIndex++;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = 'Generado:';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      rowIndex++;

      // Fila vacía antes de los datos
      rowIndex++;

      // Variable para controlar la agrupación visual
      int currentOperationOrder = 0;
      int? lastOperationId;

      // Añadir encabezados con orden mejorado
      final headerRow = rowIndex;
      List<String> headers = [
        'Fecha Inicial',
        'Hora Inicial',
        'Nombre Completo',
        'Documento',
        'Área',
        'Zona',
        'Motonave',
        'Tarea',
        'Fecha Finalización',
        'Hora Finalización',
        'Estado',
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: headerRow));
        cell.value = headers[i];
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: '#2C5282',
          fontColorHex: '#FFFFFF',
          horizontalAlign: HorizontalAlign.Center,
        );
      }
      rowIndex++;

      // Añadir datos - UNA FILA POR CADA TRABAJADOR con agrupación visual por color
      for (int assignmentIndex = 0;
          assignmentIndex < filteredAssignments.length;
          assignmentIndex++) {
        var data = filteredAssignments[assignmentIndex];

        // Determinar si es una nueva operación
        bool isNewOperation = lastOperationId != data.id;
        if (isNewOperation) {
          lastOperationId = data.id;
          // Solo incrementamos el contador de operación cuando cambia la operación
          // para alternar colores entre diferentes operaciones
          currentOperationOrder++;
        }

        // Color de fondo para filas de la misma operación - usamos el mismo color para toda la operación
        final backgroundColor =
            currentOperationOrder % 2 == 0 ? '#F7FAFC' : '#EDF2F7';

        // Si no hay trabajadores, crear una fila con "Sin asignar"
        if (data.workers.isEmpty) {
          _addRowWithData(
            sheet: sheet,
            rowIndex: rowIndex,
            data: data,
            workerName: 'Sin asignar',
            workerDocument: '-',
            headers: headers,
            backgroundColor: backgroundColor,
          );
          rowIndex++;
        } else {
          // Crear una fila individual para CADA trabajador
          for (var worker in data.workers) {
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

            // Añadir fila con datos en el nuevo orden
            _addRowWithData(
              sheet: sheet,
              rowIndex: rowIndex,
              data: data,
              workerName: workerName,
              workerDocument: workerDocument,
              headers: headers,
              backgroundColor: backgroundColor,
            );

            rowIndex++;
          }
        }
      }

      // Ajustar ancho de columnas para mejor visualización
      sheet.setColWidth(0, 15); // Fecha Inicial
      sheet.setColWidth(1, 12); // Hora Inicial
      sheet.setColWidth(2, 25); // Nombre Completo
      sheet.setColWidth(3, 15); // Documento
      sheet.setColWidth(4, 15); // Área
      sheet.setColWidth(5, 15); // Zona
      sheet.setColWidth(6, 20); // Motonave
      sheet.setColWidth(7, 30); // Tarea
      sheet.setColWidth(8, 15); // Fecha Finalización
      sheet.setColWidth(9, 12); // Hora Finalización
      sheet.setColWidth(10, 15); // Estado

      // Guardar el archivo Excel
      final output = await getTemporaryDirectory();
      final String fileName =
          'reporte_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(excel.encode()!);

      // Compartir el archivo
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: _getReportTitle(),
        text: 'Adjunto el reporte de operaciones en formato Excel.',
      );

      widget.onExport('Excel exportado correctamente');
    } catch (e) {
      _showErrorSnackbar(e);
      widget.onExport('Error al exportar Excel');
    }
  }

  // Método auxiliar para agregar una fila de datos al Excel
  void _addRowWithData({
    required Sheet sheet,
    required int rowIndex,
    required Assignment data,
    required String workerName,
    required String workerDocument,
    required List<String> headers,
    required String backgroundColor,
  }) {
    int colIndex = 0;

    // Fecha Inicial
    sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
      ..value = DateFormat('dd/MM/yyyy').format(data.date)
      ..cellStyle = CellStyle(backgroundColorHex: backgroundColor);

    // Hora Inicial
    sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
      ..value = data.time
      ..cellStyle = CellStyle(backgroundColorHex: backgroundColor);

    // Nombre Completo
    sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
      ..value = workerName
      ..cellStyle = CellStyle(
        textWrapping: TextWrapping.WrapText,
        backgroundColorHex: backgroundColor,
      );

    // Documento
    sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
      ..value = workerDocument
      ..cellStyle = CellStyle(backgroundColorHex: backgroundColor);

    // Área
    sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
      ..value = data.area
      ..cellStyle = CellStyle(backgroundColorHex: backgroundColor);

    // Zona
    sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
      ..value = data.zone ?? 'N/A'
      ..cellStyle = CellStyle(
        textWrapping: TextWrapping.WrapText,
        backgroundColorHex: backgroundColor,
      );

    // Motonave
    sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
      ..value = data.motorship ?? 'N/A'
      ..cellStyle = CellStyle(
        textWrapping: TextWrapping.WrapText,
        backgroundColorHex: backgroundColor,
      );

    // Tarea
    sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
      ..value = data.task
      ..cellStyle = CellStyle(
        textWrapping: TextWrapping.WrapText,
        backgroundColorHex: backgroundColor,
      );

    // Fecha Finalización
    sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
      ..value = data.endDate != null
          ? DateFormat('dd/MM/yyyy').format(data.endDate!)
          : ''
      ..cellStyle = CellStyle(backgroundColorHex: backgroundColor);

    // Hora Finalización
    sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
      ..value = data.endTime ?? ''
      ..cellStyle = CellStyle(backgroundColorHex: backgroundColor);

    // Estado
    sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
      ..value = _getHumanReadableStatus(data.status)
      ..cellStyle = CellStyle(backgroundColorHex: backgroundColor);
  }

  // Método auxiliar para generar el título del reporte con todos los filtros
  String _getReportTitle() {
    String reportTitle = 'Reporte de Operaciones';

    // Añadir área al título si está filtrado
    if (widget.area != 'Todas') {
      reportTitle += ' - ${widget.area}';
    }

    // Añadir zona al título si está filtrado
    if (widget.zone != null) {
      reportTitle += ' - Zona ${widget.zone}';
    }

    // Añadir motonave al título si está filtrado
    if (widget.motorship != null && widget.motorship!.isNotEmpty) {
      reportTitle += ' - ${widget.motorship}';
    }

    // Añadir estado al título si está filtrado
    if (widget.status != null && widget.status!.isNotEmpty) {
      reportTitle += ' - ${widget.status}';
    }

    return reportTitle;
  }

  void _showErrorSnackbar(dynamic error) {
    showErrorToast(
        context, 'Error al exportar: ${error.toString().substring(0, 50)}');
  }

  // Método auxiliar para obtener el rango de fechas formateado
  String _getDateRange() {
    return widget.periodName == "Personalizado"
        ? "${DateFormat('dd/MM/yyyy').format(widget.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.endDate)}"
        : widget.periodName;
  }

  // Método para convertir estados codificados a texto legible
  String _getHumanReadableStatus(String status) {
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
    // Actualizar la lista filtrada cuando cambia el build
    _filteredAssignments = _getFilteredAssignments();
    String dateRange = _getDateRange();
    String reportTitle = _getReportTitle();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF7FAFC),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exportar Informe',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Título:', reportTitle),
                    const SizedBox(height: 8),
                    _buildInfoRow('Período:', dateRange),
                    if (widget.area != 'Todas') ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Área:', widget.area),
                    ],
                    if (widget.zone != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Zona:', widget.zone.toString()),
                    ],
                    if (widget.motorship != null &&
                        widget.motorship!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Motonave:', widget.motorship!),
                    ],
                    if (widget.status != null && widget.status!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Estado:', widget.status!),
                    ],
                    const SizedBox(height: 8),
                    _buildInfoRow(
                        'Registros:', _filteredAssignments.length.toString()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildExportButton(
                icon: Icons.table_chart_outlined,
                label: 'Excel',
                color: const Color(0xFF38A169),
                onPressed: () => _simulateExport('Excel'),
              ),
              _buildExportButton(
                icon: Icons.share_outlined,
                label: 'Compartir',
                color: const Color(0xFF805AD5),
                onPressed: () => _simulateExport('Excel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF718096),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2D3748),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: NeumorphicButton(
          style: NeumorphicStyle(
            depth: 2,
            intensity: 0.7,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
            color: Colors.white,
          ),
          onPressed: onPressed,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
