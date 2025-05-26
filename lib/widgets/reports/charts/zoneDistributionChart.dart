import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/core/model/operation.dart';

class ZoneDistributionChart extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String area;
  final int? zone;
  final String? motorship;
  final String? status;

  const ZoneDistributionChart({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.area,
    required this.zone,
    required this.motorship,
    required this.status,
  }) : super(key: key);

  @override
  State<ZoneDistributionChart> createState() => _ZoneDistributionChartState();
}

class _ZoneDistributionChartState extends State<ZoneDistributionChart> {
  late List<ZoneData> _zoneData;
  int _selectedIndex = -1;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(ZoneDistributionChart oldWidget) {
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

  List<ZoneData> processAssignmentData(List<Operation> assignments) {
    try {
      final filteredAssignments = assignments.where((assignment) {
        // Filtrar por fecha
        if (!assignment.date
                .isAfter(widget.startDate.subtract(const Duration(days: 1))) ||
            !assignment.date
                .isBefore(widget.endDate.add(const Duration(days: 1)))) {
          return false;
        }

        // Filtrar por área
        if (widget.area != 'Todas' && assignment.area != widget.area) {
          return false;
        }

        // Filtrar por zona específica si se ha seleccionado
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

        // Filtrar por motonave
        if (widget.motorship != null && widget.motorship!.isNotEmpty) {
          if (assignment.motorship == null ||
              assignment.motorship != widget.motorship) {
            return false;
          }
        }

        // Filtrar por estado
        if (widget.status != null && widget.status!.isNotEmpty) {
          // Normalizar el estado para comparación
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
      // Agrupar por zona
      final Map<int, List<Operation>> zoneAssignments = {};
      for (var assignment in filteredAssignments) {
        final zone = assignment.zone;
        if (!zoneAssignments.containsKey(zone)) {
          zoneAssignments[zone] = [];
        }
        zoneAssignments[zone]!.add(assignment);
      }

      // Colores para cada zona
      final List<Color> zoneColors = [
        const Color(0xFF4299E1), // Azul
        const Color(0xFF48BB78), // Verde
        const Color(0xFFED8936), // Naranja
        const Color(0xFF9F7AEA), // Púrpura
        const Color(0xFF38B2AC), // Turquesa
        const Color(0xFFECC94B), // Amarillo
        const Color(0xFFE53E3E), // Rojo
        const Color(0xFF805AD5), // Púrpura oscuro
        const Color(0xFF3182CE), // Azul oscuro
        const Color(0xFF2F855A), // Verde oscuro
      ];

      // Convertir a ZoneData
      final result = <ZoneData>[];
      zoneAssignments.forEach((zone, assignments) {
        // Contar personal total (sin duplicados)
        final Set<int> uniqueWorkerIds = {};
        int totalAssignments = assignments.length;
        String zoneDescription = 'Zona $zone';

        // Información adicional para mostrar en el detalle
        Map<String, int> taskCounts = {};
        Map<String, int> statusCounts = {};

        for (var assignment in assignments) {
          // Contar trabajadores únicos
          // for (var worker in assignment.workers) {
          //   uniqueWorkerIds.add(worker.id);
          // }

          // // Contar por tipo de tarea
          // if (taskCounts.containsKey(assignment.task)) {
          //   taskCounts[assignment.task] =
          //       (taskCounts[assignment.task] ?? 0) + 1;
          // } else {
          //   taskCounts[assignment.task] = 1;
          // }

          // Contar por estado
          if (statusCounts.containsKey(assignment.status)) {
            statusCounts[assignment.status] =
                (statusCounts[assignment.status] ?? 0) + 1;
          } else {
            statusCounts[assignment.status] = 1;
          }

          // Intentar determinar descripción más específica de la zona
          if (assignment.motorship != null &&
              assignment.motorship!.isNotEmpty) {
            zoneDescription = 'Zona $zone (${assignment.motorship})';
          }
          zoneDescription = 'Zona $zone';
        }

        result.add(ZoneData(
          zoneDescription,
          uniqueWorkerIds.length,
          zoneColors[(zone - 1) % zoneColors.length],
          totalAssignments: totalAssignments,
          taskCounts: taskCounts,
          statusCounts: statusCounts,
          zoneNumber: zone,
          dateRange:
              '${DateFormat('dd/MM/yyyy').format(widget.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.endDate)}',
        ));
      });

      // Ordenar por cantidad de personal (de mayor a menor)
      result.sort((a, b) => b.personnel.compareTo(a.personnel));

      // Si no hay datos, devolver lista vacía
      if (result.isEmpty) {
        debugPrint('No se encontraron datos de asignaciones por zona');
      }

      return result;
    } catch (e) {
      debugPrint('Error al procesar datos de zona: $e');
      setState(() {
        _errorMessage = 'Error al procesar datos: $e';
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

        // Procesar datos si estamos cargando y hay datos disponibles
        if (_isLoading && assignments.isNotEmpty) {
          _zoneData = processAssignmentData(assignments);
          _isLoading = false;
        }

        // Si no hay datos, intentar cargar asignaciones
        if (_isLoading &&
            assignments.isEmpty &&
            !assignmentsProvider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            assignmentsProvider.loadAssignments(context);
          });
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Distribución por Zona',
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
            else if (_zoneData.isEmpty)
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
              Expanded(
                child: _buildChartWithLegend(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildChartWithLegend() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: _buildChart(),
        ),
        const SizedBox(height: 16),
        Expanded(
          flex: 2,
          child: _buildLegend(),
        ),
      ],
    );
  }

  Widget _buildChart() {
    double total = _zoneData.fold(0, (sum, item) => sum + item.personnel);

    return Center(
      child: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          children: [
            // Gráfico circular
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: CustomPaint(
                key: ValueKey<int>(_selectedIndex),
                size: const Size(240, 240),
                painter: PieChartPainter(_zoneData, total, _selectedIndex),
              ),
            ),

            // Círculo central
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_selectedIndex == -1) ...[
                      Text(
                        '${total.toInt()}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Personal',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ] else ...[
                      Text(
                        '${_zoneData[_selectedIndex].personnel}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _zoneData[_selectedIndex].color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(((_zoneData[_selectedIndex].personnel / total) * 100).round())}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: _zoneData[_selectedIndex].color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Información detallada si hay selección
          if (_selectedIndex != -1)
            _buildSelectedZoneDetail(_zoneData[_selectedIndex]),

          // Leyenda normal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: _zoneData.asMap().entries.map((entry) {
                final index = entry.key;
                final zone = entry.value;
                final isSelected = _selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = isSelected ? -1 : index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? zone.color.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: zone.color,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: zone.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${zone.name.length > 12 ? '${zone.name.substring(0, 10)}...' : zone.name}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? zone.color : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedZoneDetail(ZoneData zoneData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: zoneData.color.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            zoneData.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: zoneData.color,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Personal:', '${zoneData.personnel}'),
          _buildInfoRow('Operaciones:', '${zoneData.totalAssignments}'),
          const SizedBox(height: 4),

          // Mostrar las principales tareas si hay datos
          if (zoneData.taskCounts.isNotEmpty) ...[
            const Divider(),
            const Text(
              'Tareas principales:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            ...zoneData.taskCounts.entries
                .take(3)
                .map((e) => _buildInfoRow(e.key, '${e.value}')),
          ],

          const SizedBox(height: 4),
          Text(
            'Periodo: ${zoneData.dateRange}',
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }
}

class ZoneData {
  final String name;
  final int personnel;
  final Color color;
  final int totalAssignments;
  final Map<String, int> taskCounts;
  final Map<String, int> statusCounts;
  final int zoneNumber;
  final String dateRange;

  ZoneData(
    this.name,
    this.personnel,
    this.color, {
    this.totalAssignments = 0,
    this.taskCounts = const {},
    this.statusCounts = const {},
    this.zoneNumber = 0,
    this.dateRange = '',
  });
}

class PieChartPainter extends CustomPainter {
  final List<ZoneData> data;
  final double total;
  final int selectedIndex;

  PieChartPainter(this.data, this.total, this.selectedIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Si no hay datos, dibujamos un círculo vacío
    if (data.isEmpty || total <= 0) {
      final paint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
      return;
    }

    double startAngle = -0.5 * math.pi; // Comenzar desde arriba

    // Recorrido de los datos para dibujar el gráfico circular
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final isSelected = i == selectedIndex;

      // Aseguramos que cada sección tenga al menos un ángulo mínimo visible
      final rawSweepAngle = (item.personnel / total) * 2 * math.pi;
      final sweepAngle = rawSweepAngle < 0.1 ? 0.1 : rawSweepAngle;

      // Calcular radio para elementos seleccionados
      final sectionRadius = isSelected ? radius * 1.05 : radius;

      // Configurar el estilo de pintura - usamos colores más brillantes
      final paint = Paint()
        ..color = item.color.withOpacity(isSelected ? 1.0 : 0.85)
        ..style = PaintingStyle.fill;

      // Crear el path para la sección
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + sectionRadius * math.cos(startAngle),
          center.dy + sectionRadius * math.sin(startAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: sectionRadius),
          startAngle,
          sweepAngle,
          false,
        )
        ..close();

      // Dibujar la sección
      canvas.drawPath(path, paint);

      // Aquí mantenemos el resto del código para mostrar etiquetas
      // pero con un ajuste para secciones pequeñas...

      // Dibujar borde entre secciones
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawPath(path, borderPaint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) =>
      oldDelegate.total != total ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.data != data;
}
