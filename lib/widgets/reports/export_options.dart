import 'dart:io';
import 'package:flutter/material.dart' hide Border;
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart' hide Border;
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/painting.dart' show Border, BorderSide;

class ExportOptions extends StatelessWidget {
  final String periodName;
  final DateTime startDate;
  final DateTime endDate;
  final String area;
  final Function(String) onExport;

  // Supervisor ficticio para casos donde no hay uno real
  final User _defaultSupervisor = User(
      id: "default",
      name: "Supervisor Genérico",
      dni: "00000000",
      phone: "000000000");

  ExportOptions({
    Key? key,
    required this.periodName,
    required this.startDate,
    required this.endDate,
    required this.area,
    required this.onExport,
  }) : super(key: key);

  // Método para filtrar las asignaciones según los criterios del reporte
  List<Assignment> _getFilteredAssignments(BuildContext context) {
    final assignmentsProvider =
        Provider.of<AssignmentsProvider>(context, listen: false);

    return assignmentsProvider.assignments.where((assignment) {
      // Filtrar por área si no es "Todas"
      if (area != 'Todas' && assignment.area != area) {
        return false;
      }

      // Filtrar por fecha
      final assignmentDate = assignment.date;
      if (assignmentDate.isBefore(startDate) ||
          assignmentDate.isAfter(endDate.add(const Duration(days: 1)))) {
        return false;
      }

      return true;
    }).toList();
  }

  void _simulateExport(BuildContext context, String type) {
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
        case 'PDF':
          _exportToPDF(context);
          break;
        case 'Excel':
          _exportToExcel(context);
          break;
        case 'Compartir':
          _shareReport(context);
          break;
      }
    });
  }

  Future<void> _shareReport(BuildContext context) async {
    try {
      // Generar resumen del reporte en texto plano
      final String reportSummary = _generateReportSummary(context);

      // Mostrar el selector de aplicaciones para compartir
      await Share.share(
        reportSummary,
        subject: _getReportTitle(),
      );

      // Notificar que se ha compartido
      onExport('Compartir');
    } catch (e) {
      _showErrorSnackbar(context, e);
    }
  }

  Future<void> _exportToPDF(BuildContext context) async {
    try {
      // Notificar que estamos generando el PDF
      onExport('Generando PDF...');

      final filteredAssignments = _getFilteredAssignments(context);

      // Crear un documento PDF con la biblioteca pdf
      final pdf = pw.Document();

      // Añadir una página con contenido en formato horizontal
      pdf.addPage(
        pw.Page(
          pageFormat:
              PdfPageFormat.a4.landscape, // Formato apaisado (horizontal)
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Título y encabezados
                pw.Header(
                  level: 0,
                  child: pw.Text(_getReportTitle(),
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Período: ${_getDateRange()}'),
                    pw.Text(
                        'Generado el: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Tabla de datos
                pw.Table(
                  border:
                      pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1), // Documento
                    1: const pw.FlexColumnWidth(2.3), // Trabajadores
                    2: const pw.FlexColumnWidth(1.3), // Área
                    3: const pw.FlexColumnWidth(2.5), // Tarea
                    4: const pw.FlexColumnWidth(0.9), // Fecha
                    5: const pw.FlexColumnWidth(0.9), // Hora
                    6: const pw.FlexColumnWidth(1.1), // Estado
                  },
                  tableWidth: pw.TableWidth.max,
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.middle,
                  children: [
                    // Encabezados de tabla
                    pw.TableRow(
                        children: [
                          _buildPDFHeaderCell('Trabajadores'),
                          _buildPDFHeaderCell('Área'),
                          _buildPDFHeaderCell('Tarea'),
                          _buildPDFHeaderCell('Fecha'),
                          _buildPDFHeaderCell('Hora'),
                          _buildPDFHeaderCell('Estado'),
                        ],
                        decoration: pw.BoxDecoration(
                            color: PdfColors.blueGrey800,
                            border: pw.Border.all(
                                color: PdfColors.grey400, width: 0.5))),
                    // Filas de datos
                    ...filteredAssignments.map((data) => pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: filteredAssignments.indexOf(data) % 2 == 0
                                ? PdfColors.grey100
                                : PdfColors.white,
                          ),
                          children: [
                            _buildPDFCell(_getWorkersInfo(data.workers)),
                            _buildPDFCell(data.area),
                            _buildPDFCell(data.task),
                            _buildPDFCell(
                                DateFormat('dd/MM/yy').format(data.date)),
                            _buildPDFCell(data.time),
                            _buildPDFCell(_getHumanReadableStatus(data.status)),
                          ],
                        )),
                  ],
                ),

                // Estadísticas
                pw.SizedBox(height: 20),
                pw.Text('Resumen',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                              'Total de asignaciones: ${filteredAssignments.length}'),
                          pw.Text(
                              'Completadas: ${filteredAssignments.where((a) => a.status == 'completed').length}'),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                              'En progreso: ${filteredAssignments.where((a) => a.status == 'in_progress').length}'),
                          pw.Text(
                              'Pendientes: ${filteredAssignments.where((a) => a.status == 'pending').length}'),
                        ],
                      ),
                    ),
                  ],
                ),

                // Nota al pie
                pw.SizedBox(height: 20),
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Este reporte fue generado automáticamente por PlannerOP',
                    style: const pw.TextStyle(
                      color: PdfColors.grey700,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Guardar el PDF en un archivo temporal
      final output = await getTemporaryDirectory();
      final String fileName =
          'reporte_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Compartir el archivo
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: _getReportTitle(),
        text: 'Adjunto el reporte de asignaciones en formato PDF.',
      );

      onExport('PDF exportado correctamente');
    } catch (e) {
      _showErrorSnackbar(context, e);
      onExport('Error al exportar PDF');
    }
  }

  // Métodos auxiliares para construir celdas PDF
  pw.Widget _buildPDFHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _buildPDFCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text),
    );
  }

  // Método para obtener información formateada de los trabajadores
  String _getWorkersInfo(List<dynamic> workers) {
    if (workers.isEmpty) {
      return 'Sin asignar';
    }

    if (workers.length == 1) {
      // Si es un Map (formato nuevo)
      if (workers[0] is Map) {
        final worker = workers[0] as Map<String, dynamic>;
        return '${worker['name']} (DNI: ${worker['document']})';
      }
      // Si es un objeto Worker (formato antiguo)
      else {
        final Worker worker = workers[0] as Worker;
        return '${worker.name} (DNI: ${worker.document})';
      }
    } else {
      // Múltiples trabajadores
      List<String> workerInfos = [];

      for (var worker in workers) {
        if (worker is Map) {
          workerInfos.add('• ${worker['name']} (${worker['document']})');
        } else {
          final Worker w = worker as Worker;
          workerInfos.add('• ${w.name} (${w.document})');
        }
      }

      return workerInfos.join('\n');
    }
  }

  Future<void> _exportToExcel(BuildContext context) async {
    try {
      // Notificar que estamos generando el Excel
      onExport('Generando Excel...');

      final filteredAssignments = _getFilteredAssignments(context);

      // Crear un archivo Excel
      final excel = Excel.createExcel();

      // Eliminar la hoja predeterminada "Sheet1"
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Crear nuestra hoja personalizada
      final Sheet sheet = excel['Reporte de Asignaciones'];

      // Añadir título y metadatos con formato
      final titleCell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
      titleCell.value = _getReportTitle();
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        fontColorHex: '#1A365D',
      );

      // Combinar celdas para el título (de A1 a G1)
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0));

      // Añadir metadatos
      int rowIndex = 1;
      if (area != 'Todas') {
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = 'Área:';
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = area;
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

      // Añadir encabezados
      final headerRow = rowIndex;
      List<String> headers = [
        'Trabajadores',
        'Área',
        'Tarea',
        'Fecha',
        'Hora',
        'Estado',
        'Supervisor'
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

      // Añadir datos
      for (var data in filteredAssignments) {
        // Trabajadores (con formato para múltiples trabajadores)
        sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = _getWorkersInfo(data.workers)
          ..cellStyle = CellStyle(
              textWrapping: TextWrapping.WrapText); // Permitir ajuste de texto

        // Área
        sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          ..value = data.area;

        // Tarea
        sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          ..value = data.task
          ..cellStyle = CellStyle(
              textWrapping: TextWrapping.WrapText); // Permitir ajuste de texto

        // Fecha
        sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          ..value = DateFormat('dd/MM/yyyy').format(data.date);

        // Hora
        sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          ..value = data.time;

        // Estado en español
        sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          ..value = _getHumanReadableStatus(data.status);

        // Supervisor
        sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          ..value = data.supervisor?.name ?? _defaultSupervisor.name;

        // Colorear filas alternas para mejor lectura
        if (rowIndex % 2 == 0) {
          for (int i = 0; i < headers.length; i++) {
            sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: i, rowIndex: rowIndex))
                .cellStyle = CellStyle(backgroundColorHex: '#F0F5FA');
          }
        }

        rowIndex++;
      }

      // Añadir estadísticas
      rowIndex += 2; // Espacio antes del resumen

      final summaryTitleCell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      summaryTitleCell.value = 'RESUMEN';
      summaryTitleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        fontColorHex: '#1A365D',
      );
      rowIndex++;

      // Estadísticas detalladas
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = 'Total de asignaciones:';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = filteredAssignments.length;
      rowIndex++;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = 'Completadas:';
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
              .value =
          filteredAssignments.where((a) => a.status == 'completed').length;
      rowIndex++;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = 'En progreso:';
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
              .value =
          filteredAssignments.where((a) => a.status == 'in_progress').length;
      rowIndex++;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = 'Pendientes:';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = filteredAssignments.where((a) => a.status == 'pending').length;

      // Ajustar ancho de columnas para mejor visualización
      sheet.setColWidth(
          0, 45); // Trabajadores (mucho más ancha para mostrar múltiples)
      sheet.setColWidth(1, 20); // Área
      sheet.setColWidth(2, 35); // Tarea
      sheet.setColWidth(3, 15); // Fecha
      sheet.setColWidth(4, 12); // Hora
      sheet.setColWidth(5, 15); // Estado
      sheet.setColWidth(6, 25); // Supervisor

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
        text: 'Adjunto el reporte de asignaciones en formato Excel.',
      );

      onExport('Excel exportado correctamente');
    } catch (e) {
      _showErrorSnackbar(context, e);
      onExport('Error al exportar Excel');
    }
  }

  void _showErrorSnackbar(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al exportar: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Método auxiliar para generar el título del reporte
  String _getReportTitle() {
    String reportTitle = 'Reporte de Operaciones';
    if (area != 'Todas') {
      reportTitle += ' - $area';
    }
    return reportTitle;
  }

  // Método auxiliar para obtener el rango de fechas formateado
  String _getDateRange() {
    return periodName == "Personalizado"
        ? "${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}"
        : periodName;
  }

  // Método auxiliar para generar el contenido básico del reporte
  String _generateReportSummary(BuildContext context) {
    final String dateRange = _getDateRange();
    final filteredAssignments = _getFilteredAssignments(context);

    final int total = filteredAssignments.length;
    final int completed =
        filteredAssignments.where((a) => a.status == 'completed').length;
    final int inProgress =
        filteredAssignments.where((a) => a.status == 'in_progress').length;
    final int pending =
        filteredAssignments.where((a) => a.status == 'pending').length;

    return '''
${_getReportTitle()}
Período: $dateRange

Este reporte incluye un resumen de las asignaciones ${area != 'Todas' ? 'para $area ' : ''}durante el período seleccionado.

Total de asignaciones: $total
Completadas: $completed
En progreso: $inProgress
Pendientes: $pending

Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}
''';
  }

  // Método para calcular las horas entre tiempo de inicio y fin
  String _calculateHours(Assignment assignment) {
    if (assignment.time.isEmpty || assignment.endTime.isEmpty) {
      return "-";
    }

    try {
      // Parsear las horas de inicio y fin
      final DateFormat format = DateFormat("HH:mm");
      final DateTime startTime = format.parse(assignment.time);
      final DateTime endTime = format.parse(assignment.endTime);

      // Calcular la diferencia en horas
      final Duration difference = endTime.difference(startTime);
      final int hours = difference.inHours;
      final int minutes = difference.inMinutes % 60;

      return '$hours:${minutes.toString().padLeft(2, '0')}';
    } catch (e) {
      return "-";
    }
  }

  // Método para convertir estados codificados a texto legible
  String _getHumanReadableStatus(String status) {
    switch (status) {
      case 'completed':
        return 'Completada';
      case 'in_progress':
        return 'En progreso';
      case 'pending':
        return 'Pendiente';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateRange = _getDateRange();
    String reportTitle = _getReportTitle();
    final filteredAssignments = _getFilteredAssignments(context);

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
                    if (area != 'Todas') ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Área:', area),
                    ],
                    const SizedBox(height: 8),
                    _buildInfoRow(
                        'Registros:', filteredAssignments.length.toString()),
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
                context: context,
                icon: Icons.picture_as_pdf_outlined,
                label: 'PDF',
                color: const Color(0xFFE53E3E),
                onPressed: () => _simulateExport(context, 'PDF'),
              ),
              _buildExportButton(
                context: context,
                icon: Icons.table_chart_outlined,
                label: 'Excel',
                color: const Color(0xFF38A169),
                onPressed: () => _simulateExport(context, 'Excel'),
              ),
              _buildExportButton(
                context: context,
                icon: Icons.share_outlined,
                label: 'Compartir',
                color: const Color(0xFF805AD5),
                onPressed: () => _simulateExport(context, 'Compartir'),
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
          width: 70,
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
    required BuildContext context,
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
