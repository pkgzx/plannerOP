import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/core/model/worker.dart';

class WorkerStatusChart extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String area;

  const WorkerStatusChart({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.area,
  }) : super(key: key);

  @override
  State<WorkerStatusChart> createState() => _WorkerStatusChartState();
}

class _WorkerStatusChartState extends State<WorkerStatusChart> {
  late List<WorkerStatusData> _statusData;
  int _selectedIndex = -1;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(WorkerStatusChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.area != widget.area) {
      _loadData();
    }
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
  }

  List<WorkerStatusData> processWorkersData(List<Worker> workers) {
    try {
      // Filtrar trabajadores por área si es necesario
      final filteredWorkers = widget.area == 'Todas'
          ? workers
          : workers.where((worker) => worker.area == widget.area).toList();

      // Contar trabajadores por estado
      final Map<String, int> statusCount = {
        'Disponible': 0,
        'Asignado': 0,
        'Incapacitado': 0,
        'Retirado': 0,
      };

      for (var worker in filteredWorkers) {
        switch (worker.status) {
          case WorkerStatus.available:
            statusCount['Disponible'] = (statusCount['Disponible'] ?? 0) + 1;
            break;
          case WorkerStatus.assigned:
            statusCount['Asignado'] = (statusCount['Asignado'] ?? 0) + 1;
            break;
          case WorkerStatus.incapacitated:
            statusCount['Incapacitado'] =
                (statusCount['Incapacitado'] ?? 0) + 1;
            break;
          case WorkerStatus.deactivated:
            statusCount['Retirado'] = (statusCount['Retirado'] ?? 0) + 1;
            break;
          default:
            break;
        }
      }

      // Convertir a WorkerStatusData con colores asignados
      final List<WorkerStatusData> result = [
        WorkerStatusData('Disponible', statusCount['Disponible'] ?? 0,
            const Color(0xFF48BB78)),
        WorkerStatusData(
            'Asignado', statusCount['Asignado'] ?? 0, const Color(0xFF4299E1)),
        WorkerStatusData('Incapacitado', statusCount['Incapacitado'] ?? 0,
            const Color(0xFFF56565)),
        WorkerStatusData(
            'Retirado', statusCount['Retirado'] ?? 0, const Color(0xFF718096)),
      ];

      return result;
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al procesar datos: $e';
      });
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkersProvider>(
      builder: (context, workersProvider, child) {
        // Obtener trabajadores del provider
        final workers = workersProvider.workers;

        // Procesar datos si estamos cargando y hay datos disponibles
        if (_isLoading && workers.isNotEmpty) {
          _statusData = processWorkersData(workers);
          _isLoading = false;
        }

        // Si no hay datos, intentar cargar trabajadores
        if (_isLoading && workers.isEmpty && !workersProvider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            workersProvider.fetchWorkersIfNeeded(context);
          });
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Estado de Trabajadores',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),

            // Estado de carga o error
            if (_isLoading || workersProvider.isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_statusData.isEmpty || workers.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No hay datos disponibles para el filtro seleccionado',
                    style: TextStyle(color: Color(0xFF718096)),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: _buildChart(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildChart() {
    return Column(
      children: [
        // Gráfica de pastel
        Expanded(
          flex: 3,
          child: CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: StatusPieChartPainter(_statusData, _selectedIndex),
          ),
        ),

        // Leyenda
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: List.generate(_statusData.length, (index) {
              final status = _statusData[index];
              final isSelected = _selectedIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = isSelected ? -1 : index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: status.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${status.status}: ${status.count}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? status.color : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class WorkerStatusData {
  final String status;
  final int count;
  final Color color;

  WorkerStatusData(this.status, this.count, this.color);
}

class StatusPieChartPainter extends CustomPainter {
  final List<WorkerStatusData> data;
  final int selectedIndex;

  StatusPieChartPainter(this.data, this.selectedIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 * 0.8;

    // Calcular el total para los porcentajes
    final total = data.fold<int>(0, (sum, item) => sum + item.count);
    if (total == 0) return; // No dibujar si no hay datos

    // Ángulos iniciales y finales para cada sección
    double startAngle = -pi / 2; // Empezar desde arriba

    // Dibujar cada sección del pastel
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final isSelected = selectedIndex == i;

      // Calcular el ángulo para esta sección
      final sweepAngle = (item.count / total) * 2 * pi;

      // Ajustar el radio si esta sección está seleccionada
      final sectionRadius = isSelected ? radius * 1.1 : radius;

      // Crear el path para esta sección
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + sectionRadius * cos(startAngle),
          center.dy + sectionRadius * sin(startAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: sectionRadius),
          startAngle,
          sweepAngle,
          false,
        )
        ..close();

      // Dibujar la sección
      final paint = Paint()
        ..color = isSelected ? item.color : item.color.withOpacity(0.7)
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);

      // Si está seleccionado, dibujar un borde
      if (isSelected) {
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawPath(path, borderPaint);

        // También dibujar etiqueta de porcentaje
        final percentage = (item.count / total * 100).toStringAsFixed(1);
        final textSpan = TextSpan(
          text: '$percentage%',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.5),
              ),
            ],
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();

        // Posición del texto (en el centro del arco)
        final middleAngle = startAngle + sweepAngle / 2;
        final textRadius = sectionRadius * 0.7;
        final textPosition = Offset(
          center.dx + textRadius * cos(middleAngle),
          center.dy + textRadius * sin(middleAngle),
        );

        textPainter.paint(
          canvas,
          textPosition - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }

      // Actualizar el ángulo de inicio para la siguiente sección
      startAngle += sweepAngle;
    }

    // Dibujar un círculo blanco en el centro para crear efecto de dona
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, centerPaint);

    // Dibujar texto en el centro con el total
    final textSpan = TextSpan(
      text: 'Total\n$total',
      style: const TextStyle(
        color: Color(0xFF2D3748),
        fontWeight: FontWeight.bold,
        fontSize: 14,
        height: 1.2,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
