import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
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
  int _selectedShipIndex = -1;
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

  // Procesar asignaciones para obtener datos de personal por buque
  List<ShipData> processAssignmentData(List<Operation> assignments) {
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
      final Map<String, List<Operation>> shipAssignments = {};

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
      ];

      final result = <ShipData>[];
      int colorIndex = 0;

      // Ordenar por cantidad de personal (de mayor a menor)
      // final sortedEntries = shipAssignments.entries.toList()
      //   ..sort((a, b) {
      //     final totalWorkersA = a.value.fold<int>(
      //         0, (sum, assignment) => sum + assignment.workers.length);
      //     final totalWorkersB = b.value.fold<int>(
      //         0, (sum, assignment) => sum + assignment.workers.length);
      //     return totalWorkersB.compareTo(totalWorkersA);
      //   });

      // // Crear ShipData para cada buque
      // for (var entry in sortedEntries) {
      //   final shipName = entry.key;
      //   final assignments = entry.value;

      //   // Contar el total de trabajadores asignados (sin duplicados)
      //   final Set<int> uniqueWorkerIds = {};
      //   final List<Map<String, dynamic>> workersDetails = [];

      //   // for (var assignment in assignments) {
      //   //   for (var worker in assignment.workers) {
      //   //     if (!uniqueWorkerIds.contains(worker.id)) {
      //   //       uniqueWorkerIds.add(worker.id);
      //   //       workersDetails.add({
      //   //         'id': worker.id,
      //   //         'name': worker.name,
      //   //         'code': worker.code,
      //   //         'phone': worker.phone,
      //   //       });
      //   //     }
      //   //   }
      //   // }

      //   final totalAssignments = assignments.length;
      //   final totalPersonnel = uniqueWorkerIds.length;

      //   result.add(ShipData(
      //     shipName,
      //     totalPersonnel,
      //     colorPalette[colorIndex % colorPalette.length],
      //     totalAssignments: totalAssignments,
      //     dateRange:
      //         '${DateFormat('dd/MM/yyyy').format(widget.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.endDate)}',
      //     workers: workersDetails,
      //     assignmentList: assignments,
      //   ));

      //   colorIndex++;
      // }

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

            // Selector de buques
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildShipSelector(),
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
              // Gráfico principal
              Expanded(
                child: _buildChart(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildShipSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<int>(
            isExpanded: true,
            value: _selectedShipIndex,
            icon: const Icon(Icons.keyboard_arrow_down),
            hint: const Text('Seleccionar buque...'),
            iconSize: 24,
            elevation: 16,
            style: const TextStyle(
              color: Color(0xFF2D3748),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            borderRadius: BorderRadius.circular(12),
            items: _buildShipDropdownItems(),
            onChanged: (int? index) {
              setState(() {
                _selectedShipIndex = index ?? -1;
                // Actualizar índice para detalle de buque
                if (index != null && index >= 0 && index < _shipData.length) {
                  _selectedIndex = index;
                } else {
                  _selectedIndex = -1; // Mostrar todos
                }
              });
            },
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<int>> _buildShipDropdownItems() {
    // Empezar con la opción "Todos los buques"
    final items = <DropdownMenuItem<int>>[
      const DropdownMenuItem<int>(
        value: -1,
        child: Row(
          children: [
            Icon(Icons.directions_boat_outlined,
                size: 18, color: Color(0xFF4299E1)),
            SizedBox(width: 8),
            Text(
              'Todos los buques',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4299E1),
              ),
            ),
          ],
        ),
      ),
      // Separador
      DropdownMenuItem<int>(
        enabled: false,
        child: Divider(color: Colors.grey.shade300, height: 1),
      ),
    ];

    // Si hay datos, agregar cada buque
    if (_shipData.isNotEmpty) {
      for (int i = 0; i < _shipData.length; i++) {
        final data = _shipData[i];
        final color = data.color;

        items.add(
          DropdownMenuItem<int>(
            value: i,
            child: Row(
              children: [
                // Indicador circular con color
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                // Nombre del buque y contador
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          data.name,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${data.personnel}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return items;
  }

  Widget _buildChart() {
    // Filtrar buques según la selección del dropdown
    List<ShipData> filteredShips;

    if (_selectedShipIndex == -1) {
      // Si está seleccionado "Todos los buques", mostrar todos
      filteredShips = _shipData;
    } else if (_selectedShipIndex >= 0 &&
        _selectedShipIndex < _shipData.length) {
      // Si hay un buque específico seleccionado, mostrar solo ese
      filteredShips = [_shipData[_selectedShipIndex]];
    } else {
      // Fallback a todos los buques si hay algún error
      filteredShips = _shipData;
    }

    // Calcular el valor máximo para escalar las barras correctamente
    final maxValue = filteredShips.isEmpty
        ? 1
        : filteredShips.fold<int>(
            0, (max, data) => data.personnel > max ? data.personnel : max);

    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          // El gráfico principal en un contenedor de desplazamiento
          _buildHorizontalBarChart(filteredShips, maxValue),

          // Popup de detalles (visible solo cuando hay selección)
          if (_selectedIndex != -1 && _selectedIndex < _shipData.length)
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: _buildShipDetailPopup(_shipData[_selectedIndex]),
            ),
        ],
      );
    });
  }

  Widget _buildHorizontalBarChart(List<ShipData> ships, int maxValue) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.only(
        // Añadir espacio en la parte superior si hay un popup visible
        top: _selectedIndex != -1 ? 160 : 0,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(ships.length, (index) {
              final data = ships[index];
              final originalIndex = _shipData.indexOf(data);
              final isSelected = originalIndex == _selectedIndex;
              final shipColor = data.color;

              // Calcular el ancho de la barra según el valor
              final double barWidthPercentage = data.personnel / maxValue;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = isSelected ? -1 : originalIndex;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? Colors.grey.shade50 : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: shipColor.withOpacity(0.3))
                        : null,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del buque y contador
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: shipColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 14,
                                color:
                                    isSelected ? shipColor : Colors.grey[800],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: shipColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 14,
                                  color: shipColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${data.personnel}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: shipColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Barra animada
                      LayoutBuilder(builder: (context, constraints) {
                        final maxBarWidth = constraints.maxWidth;
                        return Stack(
                          children: [
                            // Barra de fondo
                            Container(
                              height: 24,
                              width: maxBarWidth,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),

                            // Barra de valor con animación
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              height: 24,
                              width: maxBarWidth * barWidthPercentage,
                              decoration: BoxDecoration(
                                color: shipColor.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: shipColor.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (maxBarWidth * barWidthPercentage > 50)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Text(
                                        '${data.personnel}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),

                      // Mini información (visible si está seleccionado)
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Operaciones: ${data.totalAssignments}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildShipDetailPopup(ShipData data) {
    final Color shipColor = data.color;

    return Card(
      elevation: 10,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: shipColor, width: 2),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 200,
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono del buque
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: shipColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_boat,
                    color: shipColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                // Información del buque
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: shipColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Periodo: ${data.dateRange}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón de cerrar
                Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIndex = -1;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 12, thickness: 1),
            // Área de información
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Información del buque - ocupando más espacio
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        // Trabajadores
                        Expanded(
                          child: _buildInfoItemCard(
                            '',
                            '${data.personnel}',
                            Icons.people_outline_rounded,
                            const Color(0xFFE6FFFA),
                            const Color(0xFF319795),
                            isSmall: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Operaciones
                        Expanded(
                          child: _buildInfoItemCard(
                            '',
                            '${data.totalAssignments}',
                            Icons.assignment_outlined,
                            const Color(0xFFFEF5ED),
                            const Color(0xFFDD6B20),
                            isSmall: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botones - ocupando menos espacio
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Botón de trabajadores
                        SizedBox(
                          height: 26,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.people, size: 12),
                            label: const Text('Ver trabajadores'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF319795),
                              padding: EdgeInsets.zero,
                              textStyle: const TextStyle(fontSize: 10),
                            ),
                            onPressed: () {
                              _showDetailDialog(
                                context: context,
                                isWorkers: true,
                                data: data,
                                title: 'Trabajadores',
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Botón de operaciones
                        SizedBox(
                          height: 26,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.assignment, size: 12),
                            label: const Text('Ver operaciones'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDD6B20),
                              side: const BorderSide(color: Color(0xFFDD6B20)),
                              padding: EdgeInsets.zero,
                              textStyle: const TextStyle(fontSize: 10),
                            ),
                            onPressed: () {
                              _showDetailDialog(
                                context: context,
                                isWorkers: false,
                                data: data,
                                title: 'Operaciones',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItemCard(
      String label, String value, IconData icon, Color bgColor, Color iconColor,
      {bool isSmall = false}) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 6 : 10),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 4 : 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: isSmall ? 14 : 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog({
    required BuildContext context,
    required bool isWorkers,
    required ShipData data,
    required String title,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isWorkers ? Icons.people : Icons.assignment,
                size: 20,
                color: data.color,
              ),
              const SizedBox(width: 8),
              Text(
                '$title de ${data.name}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: data.color,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: isWorkers
                ? _buildWorkersList(data)
                : _buildAssignmentsList(data),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWorkersList(ShipData data) {
    return ListView.builder(
      itemCount: data.workers.length,
      itemBuilder: (context, index) {
        final worker = data.workers[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: data.color.withOpacity(0.2),
            child: Text(
              worker['name'].substring(0, 1),
              style: TextStyle(
                color: data.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(worker['name']),
          subtitle: Text('Código: ${worker['code']} | Tel: ${worker['phone']}'),
        );
      },
    );
  }

  Widget _buildAssignmentsList(ShipData data) {
    return ListView.builder(
      itemCount: data.assignmentList.length,
      itemBuilder: (context, index) {
        final assignment = data.assignmentList[index];
        return ListTile(
          leading: Icon(
            Icons.assignment,
            color: data.color,
          ),
          title: Text('Operación #${assignment.id}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy').format(assignment.date)}'),
              Text('Estado: ${_getStatusText(assignment.status)}'),
              // Text('Tarea: ${assignment.task}'),
            ],
          ),
          isThreeLine: true,
        );
      },
    );
  }

  String _getStatusText(String status) {
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
        return status;
    }
  }
}

class ShipData {
  final String name;
  final int personnel;
  final Color color;
  final int totalAssignments;
  final String dateRange;
  final List<Map<String, dynamic>> workers;
  final List<Operation> assignmentList;

  ShipData(
    this.name,
    this.personnel,
    this.color, {
    this.totalAssignments = 0,
    this.dateRange = '',
    this.workers = const [],
    this.assignmentList = const [],
  });
}
