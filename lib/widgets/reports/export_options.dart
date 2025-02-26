import 'dart:io';
import 'package:flutter/material.dart' hide Border;
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart' hide Border;
import 'package:intl/intl.dart';
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

// Datos de ejemplo para los informes
  final List<Map<String, dynamic>> _sampleData = [
    {
      'id': '001',
      'worker': 'Carlos Méndez',
      'area': 'Zona Norte',
      'task': 'Mantenimiento preventivo',
      'date': DateTime.parse("2022-03-01"),
      'status': 'Completada',
      'hours': 8.5,
      'efficiency': 95,
    },
    {
      'id': '002',
      'worker': 'Ana Gutiérrez',
      'area': 'Zona Centro',
      'task': 'Inspección de equipos',
      'date': DateTime.parse("2022-03-02"),
      'status': 'Completada',
      'hours': 6.0,
      'efficiency': 88,
    },
    {
      'id': '003',
      'worker': 'Roberto Sánchez',
      'area': 'Zona Sur',
      'task': 'Reparación de instalación',
      'date': DateTime.parse("2022-03-03"),
      'status': 'En progreso',
      'hours': 4.0,
      'efficiency': 0,
    },
  ];

  ExportOptions({
    Key? key,
    required this.periodName,
    required this.startDate,
    required this.endDate,
    required this.area,
    required this.onExport,
  }) : super(key: key);

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
    Future.delayed(const Duration(seconds: 2), () {
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
      final String reportSummary = _generateReportSummary();

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
      // Crear un documento PDF con la biblioteca pdf
      final pdf = pw.Document();

      // Añadir una página con contenido
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Título y encabezados
                pw.Header(
                  level: 0,
                  child: pw.Text(_getReportTitle()),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Período: ${_getDateRange()}'),
                pw.SizedBox(height: 6),
                pw.Text(
                    'Generado el: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
                pw.SizedBox(height: 20),

                // Tabla de datos
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(30),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(3),
                    4: const pw.FixedColumnWidth(70),
                    5: const pw.FixedColumnWidth(70),
                    6: const pw.FixedColumnWidth(50),
                  },
                  children: [
                    // Encabezados de tabla
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('ID',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Trabajador',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Área',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Tarea',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Fecha',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Estado',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Horas',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    // Filas de datos
                    ..._sampleData.map((data) => pw.TableRow(
                          children: [
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(data['id'].toString())),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(data['worker'])),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(data['area'])),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(data['task'])),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(DateFormat('dd/MM/yy')
                                    .format(data['date']))),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(data['status'])),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text('${data['hours']}h')),
                          ],
                        )),
                  ],
                ),

                // Nota al pie
                pw.SizedBox(height: 20),
                pw.Text(
                    'Este reporte fue generado automáticamente por PlanneroP.'),
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

      onExport('PDF');
    } catch (e) {
      _showErrorSnackbar(context, e);
    }
  }

  Future<void> _exportToExcel(BuildContext context) async {
    try {
      // Crear un archivo Excel
      final excel = Excel.createExcel();
      final Sheet sheet = excel['Reporte de Asignaciones'];

      // Añadir título y metadatos
      sheet.appendRow(['Reporte de Asignaciones']);
      if (area != 'Todas') {
        sheet.appendRow(['Área: $area']);
      }
      sheet.appendRow(['Período: ${_getDateRange()}']);
      sheet.appendRow([
        'Generado el: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'
      ]);
      sheet.appendRow([]); // Fila vacía

      // Añadir encabezados
      sheet.appendRow([
        'ID',
        'Trabajador',
        'Área',
        'Tarea',
        'Fecha',
        'Estado',
        'Horas',
        'Eficiencia'
      ]);

      // Dar formato a encabezados
      for (int i = 0; i < 8; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 5))
            .cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: '#E2E8F0',
        );
      }

      // Añadir datos
      int rowIndex = 6;
      for (var data in _sampleData) {
        sheet.appendRow([
          data['id'],
          data['worker'],
          data['area'],
          data['task'],
          DateFormat('dd/MM/yy')
              .format(data['date']), // Corregido: data['date'] ya es DateTime
          data['status'],
          '${data['hours']}h',
          data['efficiency'] == 0 ? '-' : '${data['efficiency']}%',
        ]);
        rowIndex++;
      }

      // Ajustar ancho de columnas
      sheet.setColWidth(0, 10); // ID
      sheet.setColWidth(1, 25); // Trabajador
      sheet.setColWidth(2, 15); // Área
      sheet.setColWidth(3, 30); // Tarea
      sheet.setColWidth(4, 15); // Fecha
      sheet.setColWidth(5, 15); // Estado
      sheet.setColWidth(6, 10); // Horas
      sheet.setColWidth(7, 15); // Eficiencia

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

      onExport('Excel');
    } catch (e) {
      _showErrorSnackbar(context, e);
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
    String reportTitle = 'Reporte de Asignaciones';
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
  String _generateReportSummary() {
    final String dateRange = _getDateRange();

    return '''
${_getReportTitle()}
Período: $dateRange

Este reporte incluye un resumen de las asignaciones ${area != 'Todas' ? 'para $area ' : ''}durante el período seleccionado.

Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}
''';
  }

  @override
  Widget build(BuildContext context) {
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
                    if (area != 'Todas') ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Área:', area),
                    ],
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
