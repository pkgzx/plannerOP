import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:provider/provider.dart';

class ShipPersonnelChart extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String area;
  final int? zone;
  final String? motorship;
  final String? status;

  const ShipPersonnelChart({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.area,
    this.zone,
    this.motorship,
    this.status,
  }) : super(key: key);

  @override
  State<ShipPersonnelChart> createState() => _ShipPersonnelChartState();
}

class _ShipPersonnelChartState extends State<ShipPersonnelChart> {
  late List<ShipData> _shipData;
  int _selectedIndex = -1;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(ShipPersonnelChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate ||
        oldWidget.area != widget.area) {
      _loadData();
    }
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Aquí obtendremos los datos de las asignaciones en el siguiente build
    // y processAssignmentData se llamará con esos datos
  }

  // Procesar asignaciones para obtener datos de personal por buque
  List<ShipData> processAssignmentData(List<Assignment> assignments) {
    try {
      // Filtrar asignaciones por todos los criterios
      final filteredAssignments = assignments.where((assignment) {
        // Filtrar por fecha
        if (!assignment.date
                .isAfter(widget.startDate.subtract(const Duration(days: 1))) ||
            !assignment.date
                .isBefore(widget.endDate.add(const Duration(days: 1)))) {
          return false;
        }

        // Filtrar por área
        if (widget.area != "Todas" && assignment.area != widget.area) {
          return false;
        }

        // Filtrar por zona
        if (widget.zone != null && assignment.zone != widget.zone.toString()) {
          return false;
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

      // Agrupar por motorship (placa de la motonave)
      final Map<String, List<Assignment>> shipAssignments = {};

      for (var assignment in filteredAssignments) {
        if (assignment.motorship != null && assignment.motorship!.isNotEmpty) {
          final motorshipKey = assignment.motorship!;

          if (!shipAssignments.containsKey(motorshipKey)) {
            shipAssignments[motorshipKey] = [];
          }

          shipAssignments[motorshipKey]!.add(assignment);
        }
      }

      // Convertir a ShipData con colores asignados - PALETA MEJORADA
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
        const Color(0xFF2C7A7B), // Verde azulado
        const Color(0xFF8B5CF6), // Violeta
      ];

      final result = <ShipData>[];
      int colorIndex = 0;

      // Ordenar por cantidad de personal (de mayor a menor)
      final sortedEntries = shipAssignments.entries.toList()
        ..sort((a, b) {
          final totalWorkersA = a.value.fold<int>(
              0, (sum, assignment) => sum + assignment.workers.length);
          final totalWorkersB = b.value.fold<int>(
              0, (sum, assignment) => sum + assignment.workers.length);
          return totalWorkersB.compareTo(totalWorkersA);
        });

      // Crear ShipData para cada buque
      for (var entry in sortedEntries) {
        final shipName = entry.key;
        final assignments = entry.value;

        // Contar el total de trabajadores asignados (sin duplicados)
        final Set<int> uniqueWorkerIds = {};
        for (var assignment in assignments) {
          for (var worker in assignment.workers) {
            uniqueWorkerIds.add(worker.id);
          }
        }

        final totalAssignments = assignments.length;
        final totalPersonnel = uniqueWorkerIds.length;

        result.add(ShipData(
          shipName,
          totalPersonnel,
          colorPalette[colorIndex % colorPalette.length],
          totalAssignments: totalAssignments,
          dateRange:
              '${DateFormat('dd/MM/yyyy').format(widget.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.endDate)}',
        ));

        colorIndex++;
      }

      // Limitar a los 6 buques con más personal si hay muchos
      if (result.length > 6) {
        result.removeRange(6, result.length);
      }

      return result;
    } catch (e) {
      debugPrint('Error al procesar datos de asignaciones: $e');
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
          _shipData = processAssignmentData(assignments);
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
                'Personal por Buque',
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
            else if (_shipData.isEmpty)
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
              // Gráfico de barras
              Expanded(
                child: _buildChart(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildChart() {
    return ListView(
      children: [
        SizedBox(
          height: 300,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Eje Y (valores numéricos)
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _buildYAxisLabels(),
              ),
              // Barras del gráfico
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_shipData.length, (index) {
                    final data = _shipData[index];
                    final isSelected = _selectedIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = isSelected ? -1 : index;
                        });
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Información sobre la barra al seleccionar
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                    color: data.color.withOpacity(0.5)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    data.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Personal: ${data.personnel}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: data.color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Operaciones: ${data.totalAssignments}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Periodo: ${data.dateRange}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Valor numérico sobre la barra
                          Text(
                            '${data.personnel}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? data.color : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Barra
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 40,
                            height: _calculateBarHeight(data.personnel),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? data.color
                                  : data.color.withOpacity(0.7),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: data.color.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),

                          // Etiqueta de la barra
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 60,
                            child: Text(
                              data.name.length > 10
                                  ? '${data.name.substring(0, 7)}...'
                                  : data.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[800],
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Calcular la altura apropiada para las barras
  double _calculateBarHeight(int value) {
    // Encontrar el valor máximo para escalar apropiadamente
    final maxValue = _shipData.fold<int>(
        0, (max, data) => data.personnel > max ? data.personnel : max);

    // Asegurar un mínimo para evitar divisiones por cero
    final safeMaxValue = maxValue > 0 ? maxValue : 1;

    // Escalar el valor (altura máxima de 250)
    return (value / safeMaxValue) * 250;
  }

  // Generar etiquetas para el eje Y basadas en los datos reales
  List<Widget> _buildYAxisLabels() {
    final maxValue = _shipData.isEmpty
        ? 30
        : _shipData.fold<int>(
            0, (max, data) => data.personnel > max ? data.personnel : max);

    final step = maxValue ~/ 5 + (maxValue % 5 > 0 ? 1 : 0);
    final steps = 5;

    return List.generate(steps + 1, (index) {
      final value = (steps - index) * step;
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Text(
          '$value',
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      );
    });
  }
}

class ShipData {
  final String name;
  final int personnel;
  final Color color;
  final int totalAssignments;
  final String dateRange;

  ShipData(this.name, this.personnel, this.color,
      {this.totalAssignments = 0, this.dateRange = ''});
}
