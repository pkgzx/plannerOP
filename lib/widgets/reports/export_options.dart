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
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
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

  Future<void> _exportToExcel() async {
    try {
      // Notificar que estamos generando el Excel
      widget.onExport('Generando Excel...');

      // Obtener asignaciones filtradas
      final filteredAssignments = _getFilteredAssignments();

      if (filteredAssignments.isEmpty) {
        widget.onExport('No hay datos para exportar');
        return;
      }

      // Ordenar asignaciones por fecha para mejor organización
      filteredAssignments.sort((a, b) => a.date.compareTo(b.date));

      // Crear un nuevo documento Excel con Syncfusion
      final xlsio.Workbook workbook = xlsio.Workbook();

      // Obtener la primera hoja
      final xlsio.Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'Reporte de Operaciones';

      // Estilos reutilizables
      final xlsio.Style titleStyle = workbook.styles.add('titleStyle');
      titleStyle.bold = true;
      titleStyle.fontSize = 14;
      titleStyle.fontColor = '#2D3748';

      final xlsio.Style headerStyle = workbook.styles.add('headerStyle');
      headerStyle.bold = true;
      headerStyle.backColor = '#2D3748';
      headerStyle.fontColor = '#FFFFFF';
      headerStyle.hAlign = xlsio.HAlignType.center;

      final xlsio.Style summaryHeaderStyle =
          workbook.styles.add('summaryHeaderStyle');
      summaryHeaderStyle.bold = true;
      summaryHeaderStyle.fontSize = 12;
      summaryHeaderStyle.backColor = '#E2E8F0';

      final xlsio.Style evenRowStyle = workbook.styles.add('evenRowStyle');
      evenRowStyle.backColor = '#F7FAFC';

      final xlsio.Style oddRowStyle = workbook.styles.add('oddRowStyle');
      oddRowStyle.backColor = '#EDF2F7';

      // 1. TÍTULO DEL REPORTE
      sheet.getRangeByName('A1').setText(_getReportTitle());
      sheet.getRangeByName('A1').cellStyle = titleStyle;

      // Combinar celdas para el título (11 columnas)
      sheet.getRangeByName('A1:K1').merge();

      // 2. FECHA DEL REPORTE
      int rowIndex = 2;
      sheet.getRangeByName('A$rowIndex').setText('Fecha:');
      sheet
          .getRangeByName('B$rowIndex')
          .setText(DateFormat('dd/MM/yyyy').format(DateTime.now()));
      rowIndex++;

      // 3. SECCIÓN DE RESUMEN
      rowIndex++;
      sheet.getRangeByName('A$rowIndex').setText('RESUMEN');
      sheet.getRangeByName('A$rowIndex').cellStyle = summaryHeaderStyle;

      // Combinar celdas para el título de resumen
      sheet.getRangeByName('A$rowIndex:C$rowIndex').merge();
      rowIndex++;

      // 4. ESTADÍSTICAS
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

      // Total de operaciones
      sheet.getRangeByName('A$rowIndex').setText('Total de operaciones:');
      sheet
          .getRangeByName('B$rowIndex')
          .setNumber(filteredAssignments.length.toDouble());
      rowIndex++;

      // Completadas
      sheet.getRangeByName('A$rowIndex').setText('Completadas:');
      sheet.getRangeByName('B$rowIndex').setNumber(completedCount.toDouble());
      rowIndex++;

      // En curso
      sheet.getRangeByName('A$rowIndex').setText('En curso:');
      sheet.getRangeByName('B$rowIndex').setNumber(inProgressCount.toDouble());
      rowIndex++;

      // Pendientes
      sheet.getRangeByName('A$rowIndex').setText('Pendientes:');
      sheet.getRangeByName('B$rowIndex').setNumber(pendingCount.toDouble());
      rowIndex++;

      // Canceladas
      sheet.getRangeByName('A$rowIndex').setText('Canceladas:');
      sheet.getRangeByName('B$rowIndex').setNumber(canceledCount.toDouble());
      rowIndex++;

      // 5. INFORMACIÓN DE FILTROS
      rowIndex++;

      // Área
      if (widget.area != 'Todas') {
        sheet.getRangeByName('A$rowIndex').setText('Área:');
        sheet.getRangeByName('B$rowIndex').setText(widget.area);
        rowIndex++;
      }

      // Zona
      if (widget.zone != null) {
        sheet.getRangeByName('A$rowIndex').setText('Zona:');
        sheet.getRangeByName('B$rowIndex').setText(widget.zone.toString());
        rowIndex++;
      }

      // Motonave
      if (widget.motorship != null && widget.motorship!.isNotEmpty) {
        sheet.getRangeByName('A$rowIndex').setText('Motonave:');
        sheet.getRangeByName('B$rowIndex').setText(widget.motorship!);
        rowIndex++;
      }

      // Estado
      if (widget.status != null && widget.status!.isNotEmpty) {
        sheet.getRangeByName('A$rowIndex').setText('Estado:');
        sheet.getRangeByName('B$rowIndex').setText(widget.status!);
        rowIndex++;
      }

      // Período
      sheet.getRangeByName('A$rowIndex').setText('Período:');
      sheet.getRangeByName('B$rowIndex').setText(_getDateRange());
      rowIndex++;

      // Generado
      sheet.getRangeByName('A$rowIndex').setText('Generado:');
      sheet
          .getRangeByName('B$rowIndex')
          .setText(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()));
      rowIndex++;

      // 6. ENCABEZADOS DE LA TABLA
      rowIndex++;
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

      // Escribir los encabezados
      for (int i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(headerRow, i + 1).setText(headers[i]);
        sheet.getRangeByIndex(headerRow, i + 1).cellStyle = headerStyle;
      }
      rowIndex++;

      // 7. DATOS - UNA FILA POR CADA TRABAJADOR
      int currentOperationOrder = 0;
      int? lastOperationId;

      for (int assignmentIndex = 0;
          assignmentIndex < filteredAssignments.length;
          assignmentIndex++) {
        var data = filteredAssignments[assignmentIndex];

        // Determinar si es una nueva operación para alternar colores
        bool isNewOperation = lastOperationId != data.id;
        if (isNewOperation) {
          lastOperationId = data.id;
          currentOperationOrder++;
        }

        // Determinar estilo según orden de operación (par/impar)
        final xlsio.Style rowStyle =
            currentOperationOrder % 2 == 0 ? evenRowStyle : oddRowStyle;

        // Si no hay trabajadores, crear una fila con "Sin asignar"
        if (data.workers.isEmpty) {
          _addDataRow(
            sheet: sheet,
            rowIndex: rowIndex,
            data: data,
            workerName: 'Sin asignar',
            workerDocument: '-',
            rowStyle: rowStyle,
          );
          rowIndex++;
        } else {
          // Crear una fila para cada trabajador
          for (var worker in data.workers) {
            String workerName = '';
            String workerDocument = '';

            // Determinar tipo de trabajador
            if (worker is Map<String, dynamic>) {
            } else if (worker is Worker) {
              workerName = worker.name;
              workerDocument = worker.document;
            }

            _addDataRow(
              sheet: sheet,
              rowIndex: rowIndex,
              data: data,
              workerName: workerName,
              workerDocument: workerDocument,
              rowStyle: rowStyle,
            );

            rowIndex++;
          }
        }
      }

      // 8. AJUSTAR ANCHOS DE COLUMNA
      sheet.setColumnWidthInPixels(
          1, 100); // Fecha Inicial (doble del ancho predeterminado)
      sheet.setColumnWidthInPixels(2, 80);
      sheet.setColumnWidthInPixels(3, 180);
      sheet.setColumnWidthInPixels(4, 100);
      sheet.setColumnWidthInPixels(5, 100);
      sheet.setColumnWidthInPixels(6, 100);
      sheet.setColumnWidthInPixels(7, 130);
      sheet.setColumnWidthInPixels(8, 220);
      sheet.setColumnWidthInPixels(9, 100);
      sheet.setColumnWidthInPixels(10, 80);
      sheet.setColumnWidthInPixels(11, 100);

      // 9. GUARDAR Y COMPARTIR
      final output = await getTemporaryDirectory();
      final String fileName =
          'reporte_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final String filePath = '${output.path}/$fileName';

      // Guardar archivo
      final List<int> bytes = workbook.saveAsStream();
      final File file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      // Liberar recursos
      workbook.dispose();

      // Compartir el archivo
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: _getReportTitle(),
        text: 'Adjunto el reporte de operaciones en formato Excel.',
      );

      widget.onExport('Excel exportado correctamente');
    } catch (e) {
      debugPrint('Error detallado al exportar Excel: $e');
      _showErrorSnackbar(e);
      widget.onExport('Error al exportar Excel');
    }
  }

// Método auxiliar para agregar una fila de datos
  void _addDataRow({
    required xlsio.Worksheet sheet,
    required int rowIndex,
    required Assignment data,
    required String workerName,
    required String workerDocument,
    required xlsio.Style rowStyle,
  }) {
    int colIndex = 1; // Syncfusion comienza en 1, no en 0

    // Fecha Inicial
    sheet
        .getRangeByIndex(rowIndex, colIndex)
        .setText(DateFormat('dd/MM/yyyy').format(data.date));
    sheet.getRangeByIndex(rowIndex, colIndex).cellStyle = rowStyle;
    colIndex++;

    // Hora Inicial
    sheet.getRangeByIndex(rowIndex, colIndex).setText(data.time);
    sheet.getRangeByIndex(rowIndex, colIndex).cellStyle = rowStyle;
    colIndex++;

    // Nombre Completo
    sheet.getRangeByIndex(rowIndex, colIndex).setText(workerName);
    sheet.getRangeByIndex(rowIndex, colIndex).cellStyle = rowStyle;
    sheet.getRangeByIndex(rowIndex, colIndex).cellStyle.wrapText = true;
    colIndex++;

    // Documento
    sheet.getRangeByIndex(rowIndex, colIndex).setText(workerDocument);
    sheet.getRangeByIndex(rowIndex, colIndex).cellStyle = rowStyle;
    colIndex++;

    // Área
    sheet.getRangeByIndex(rowIndex, colIndex).setText(data.area);
    sheet.getRangeByIndex(rowIndex, colIndex).cellStyle = rowStyle;
    colIndex++;

    // Zona
    sheet.getRangeByIndex(rowIndex, colIndex).setText("${data.zone}" ?? 'N/A');
    sheet.getRangeByIndex(rowIndex, colIndex).cellStyle = rowStyle;
    sheet.getRangeByIndex(rowIndex, colIndex).cellStyle.wrapText = true;
    colIndex++;

    // Motonave
    sheet.getRangeByIndex(rowIndex, colIndex).setText(data.motorship ?? 'N/A');
    sheet.getRangeByIndex(rowIndex, colIndex).cellStyle = rowStyle;
    sheet.getRangeByIndex(rowIndex, colIndex).cellStyle.wrapText = true;
    colIndex++;

    // Tarea
    sheet.getRangeByIndex(rowIndex, colIndex).setText(data.task);
    sheet.getRangeByIndex(rowIndex, colIndex).cellStyle = rowStyle;
    sheet.getRangeByIndex(rowIndex, colIndex).cellStyle.wrapText = true;
    colIndex++;

    // Fecha Finalización
    String endDateText = data.endDate != null
        ? DateFormat('dd/MM/yyyy').format(data.endDate!)
        : '';
    sheet.getRangeByIndex(rowIndex, colIndex).setText(endDateText);
    sheet.getRangeByIndex(rowIndex, colIndex).cellStyle = rowStyle;
    colIndex++;

    // Hora Finalización
    sheet.getRangeByIndex(rowIndex, colIndex).setText(data.endTime ?? '');
    sheet.getRangeByIndex(rowIndex, colIndex).cellStyle = rowStyle;
    colIndex++;

    // Estado
    sheet
        .getRangeByIndex(rowIndex, colIndex)
        .setText(_getHumanReadableStatus(data.status));
    sheet.getRangeByIndex(rowIndex, colIndex).cellStyle = rowStyle;
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
