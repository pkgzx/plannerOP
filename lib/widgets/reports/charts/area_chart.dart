import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/store/areas.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class AreaDistributionChart extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String area;
  final int? zone;
  final String? motorship;
  final String? status;

  const AreaDistributionChart({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.area,
    this.zone,
    this.motorship,
    this.status,
  }) : super(key: key);

  @override
  State<AreaDistributionChart> createState() => _AreaDistributionChartState();
}

class _AreaDistributionChartState extends State<AreaDistributionChart> {
  late List<AreaData> _areaData;
  int _selectedIndex = -1;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(AreaDistributionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update this to check ALL filter parameters
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate ||
        oldWidget.area != widget.area ||
        oldWidget.zone != widget.zone ||
        oldWidget.motorship != widget.motorship ||
        oldWidget.status != widget.status) {
      _loadData();
    }
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
  }

  // Procesar asignaciones para obtener datos por área
  List<AreaData> processAssignmentData(List<Assignment> assignments) {
    try {
      // Filtrar asignaciones por fecha
      var filteredAssignments = assignments.where((assignment) {
        // Filtrar por fecha
        if (!assignment.date
                .isAfter(widget.startDate.subtract(const Duration(days: 1))) ||
            !assignment.date
                .isBefore(widget.endDate.add(const Duration(days: 1)))) {
          return false;
        }

        // Filtrar por área específica si no es "Todas"
        if (widget.area != "Todas" && assignment.area != widget.area) {
          return false;
        }

        // Filtrar por zona
        if (widget.zone != null) {
          int? assignmentZone;
          try {
            assignmentZone = int.tryParse(assignment.zone.toString());
          } catch (e) {
            assignmentZone = null;
          }

          if (assignmentZone != widget.zone) {
            return false;
          }
        }

        // Filtrar por motonave específica
        if (widget.motorship != null && widget.motorship!.isNotEmpty) {
          if (assignment.motorship == null ||
              assignment.motorship != widget.motorship) {
            return false;
          }
        }

        // Filtrar por estado
        if (widget.status != null && widget.status!.isNotEmpty) {
          String normalizedStatus;
          switch (assignment.status.toUpperCase()) {
            case 'COMPLETED':
              normalizedStatus = 'Completada';
              break;
            case 'INPROGRESS':
              normalizedStatus = 'En curso';
              break;
            case 'PENDING':
              normalizedStatus = 'Pendiente';
              break;
            case 'CANCELED':
              normalizedStatus = 'Cancelada';
              break;
            default:
              normalizedStatus = assignment.status;
          }

          if (normalizedStatus != widget.status) {
            return false;
          }
        }

        return true;
      }).toList();

      debugPrint('filter: ${widget.status}');
      // si es el caso filtrar por estado
      if (widget.status != null && widget.status!.isNotEmpty) {
        filteredAssignments = filteredAssignments.where((assignment) {
          String normalizedStatus;
          switch (assignment.status.toUpperCase()) {
            case 'COMPLETED':
              normalizedStatus = 'Completada';
              break;
            case 'INPROGRESS':
              normalizedStatus = 'En curso';
              break;
            case 'PENDING':
              normalizedStatus = 'Pendiente';
              break;
            case 'CANCELED':
              normalizedStatus = 'Cancelada';
              break;
            default:
              normalizedStatus = assignment.status;
          }

          return normalizedStatus == widget.status;
        }).toList();
      }

      // Agrupar por área
      final Map<String, List<Assignment>> areaAssignments = {};

      for (var assignment in filteredAssignments) {
        final areaName = assignment.area;

        if (!areaAssignments.containsKey(areaName)) {
          areaAssignments[areaName] = [];
        }

        areaAssignments[areaName]!.add(assignment);
      }

      // Asignar colores a cada área
      final List<Color> colorPalette = [
        const Color(0xFF3182CE), // Azul
        const Color(0xFF38A169), // Verde
        const Color(0xFFED8936), // Naranja
        const Color(0xFF805AD5), // Púrpura
        const Color(0xFFE53E3E), // Rojo
        const Color(0xFF4A5568), // Gris azulado
        const Color(0xFFD69E2E), // Amarillo
        const Color(0xFF00B5D8), // Cian
        const Color(0xFFDD6B20), // Naranja oscuro
        const Color(0xFFD53F8C), // Rosa
      ];

      final result = <AreaData>[];
      int colorIndex = 0;

      // Ordenar por cantidad de personal (de mayor a menor)
      final sortedEntries = areaAssignments.entries.toList()
        ..sort((a, b) {
          final totalWorkersA = a.value.fold<int>(
              0, (sum, assignment) => sum + assignment.workers.length);
          final totalWorkersB = b.value.fold<int>(
              0, (sum, assignment) => sum + assignment.workers.length);
          return totalWorkersB.compareTo(totalWorkersA);
        });

      // Crear AreaData para cada área
      for (var entry in sortedEntries) {
        final areaName = entry.key;
        final assignments = entry.value;

        // Contar personal único por área
        final Set<int> uniqueWorkerIds = {};
        for (var assignment in assignments) {
          for (var worker in assignment.workers) {
            uniqueWorkerIds.add(worker.id);
          }
        }

        final totalAssignments = assignments.length;
        final totalPersonnel = uniqueWorkerIds.length;

        // Calcular porcentaje del total
        double percentage = 0;
        if (filteredAssignments.isNotEmpty) {
          final totalWorkers = filteredAssignments.fold<Set<int>>(<int>{},
              (workers, assignment) {
            assignment.workers.forEach((worker) {
              workers.add(worker.id);
            });
            return workers;
          }).length;

          percentage = totalWorkers > 0 ? totalPersonnel / totalWorkers : 0;
        }

        result.add(AreaData(
          name: areaName,
          personnel: totalPersonnel,
          color: colorPalette[colorIndex % colorPalette.length],
          assignments: totalAssignments,
          dateRange:
              '${DateFormat('dd/MM/yyyy').format(widget.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.endDate)}',
          percentage: percentage,
        ));

        colorIndex++;
      }

      return result;
    } catch (e) {
      debugPrint('Error al procesar datos para el gráfico de áreas: $e');
      setState(() {
        _errorMessage = 'Error al procesar los datos: $e';
        _isLoading = false;
      });
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssignmentsProvider>(
      builder: (context, assignmentsProvider, child) {
        // Obtener asignaciones del provider
        final assignments = assignmentsProvider.assignments;

        // Procesar asignaciones si estamos cargando y hay datos disponibles
        if (_isLoading && assignments.isNotEmpty) {
          _areaData = processAssignmentData(assignments);
          _isLoading = false;
        }

        // Si no hay datos, intentar cargar asignaciones
        if (_isLoading &&
            assignments.isEmpty &&
            !assignmentsProvider.isLoading) {
          // Solo disparar la carga si no está ya cargando
          WidgetsBinding.instance.addPostFrameCallback((_) {
            assignmentsProvider.loadAssignments(context);
          });
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Distribución por Áreas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),

            // Estado de carga o error
            if (_isLoading || assignmentsProvider.isLoading)
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
            else if (_areaData.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No hay datos disponibles para el periodo seleccionado',
                    style: TextStyle(color: Color(0xFF718096)),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              // Visualización pie/donut chart
              Expanded(
                child: _buildDonutChart(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDonutChart() {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableSize =
                  math.min(constraints.maxWidth, constraints.maxHeight) * 0.8;

              return Center(
                child: SizedBox(
                  width: availableSize,
                  height: availableSize,
                  child: Stack(
                    children: [
                      // Donut chart
                      CustomPaint(
                        size: Size(availableSize, availableSize),
                        painter: DonutChartPainter(
                          _areaData,
                          _selectedIndex,
                        ),
                      ),

                      // Centro del donut con info si hay selección
                      Center(
                        child: Container(
                          width: availableSize * 0.6,
                          height: availableSize * 0.6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                spreadRadius: 2,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _selectedIndex != -1
                                ? _buildSelectedInfo()
                                : const Text(
                                    'Toque un área\npara ver detalles',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF718096),
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Leyenda
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _areaData.isNotEmpty
              ? ListView(
                  scrollDirection: Axis.horizontal,
                  children: _areaData.map((data) {
                    final isSelected =
                        _areaData.indexOf(data) == _selectedIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex =
                              isSelected ? -1 : _areaData.indexOf(data);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? data.color.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? data.color : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: data.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  '${data.personnel} trabajadores',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                )
              : const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildSelectedInfo() {
    if (_selectedIndex < 0 || _selectedIndex >= _areaData.length) {
      return const SizedBox();
    }

    final data = _areaData[_selectedIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          data.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: data.color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${data.personnel}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        Text(
          'trabajadores',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: data.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${(data.percentage * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              color: data.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<AreaData> areas;
  final int selectedIndex;

  DonutChartPainter(this.areas, this.selectedIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double donutWidth = radius * 0.3;
    final double outerRadius = radius;
    final double innerRadius = radius - donutWidth;

    double totalPersonnel = 0;
    for (var area in areas) {
      totalPersonnel += area.personnel;
    }

    // Comenzar desde arriba (pi * 1.5)
    double startAngle = -math.pi / 2;

    for (int i = 0; i < areas.length; i++) {
      final area = areas[i];
      final isSelected = i == selectedIndex;

      double sweepAngle = 2 * math.pi * (area.personnel / totalPersonnel);

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = isSelected ? area.color : area.color.withOpacity(0.7);

      // Sombra si está seleccionado
      if (isSelected) {
        canvas.drawShadow(
          Path()
            ..addArc(
              Rect.fromCircle(center: center, radius: outerRadius),
              startAngle,
              sweepAngle,
            )
            ..arcTo(
              Rect.fromCircle(center: center, radius: innerRadius),
              startAngle + sweepAngle,
              -sweepAngle,
              false,
            )
            ..close(),
          Colors.black.withOpacity(0.3),
          4,
          true,
        );
      }

      // Dibujar arco exterior
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Dibujar arco interior (para crear el efecto donut)
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle,
        sweepAngle,
        true,
        Paint()..color = Colors.white,
      );

      // Actualizar ángulo inicial para el siguiente arco
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return oldDelegate.areas != areas ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class AreaData {
  final String name;
  final int personnel;
  final Color color;
  final int assignments;
  final String dateRange;
  final double percentage;

  AreaData({
    required this.name,
    required this.personnel,
    required this.color,
    this.assignments = 0,
    this.dateRange = '',
    this.percentage = 0,
  });
}
