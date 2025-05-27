import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:math' as math;
import 'package:plannerop/core/model/task.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/store/operations.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/store/task.dart';

class ServiceTrendChart extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String area;
  final int? zone;
  final String? motorship;
  final String? status;

  const ServiceTrendChart({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.area,
    this.zone,
    this.motorship,
    this.status,
  }) : super(key: key);

  @override
  State<ServiceTrendChart> createState() => _ServiceTrendChartState();
}

class _ServiceTrendChartState extends State<ServiceTrendChart> {
  late List<ServiceWorkerData> _servicesData;
  int _selectedIndex = -1;
  int _selectedServiceIndex = -1;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(ServiceTrendChart oldWidget) {
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

  List<ServiceWorkerData> processAssignmentData(
      List<Operation> assignments, List<Task> tasks) {
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
      // Agrupar por servicio (tarea)
      final Map<String, List<Operation>> serviceAssignments = {};
      // for (var assignment in filteredAssignments) {
      //   final task = assignment.task;
      //   if (!serviceAssignments.containsKey(task)) {
      //     serviceAssignments[task] = [];
      //   }
      //   serviceAssignments[task]!.add(assignment);
      // }

      // Convertir a ServiceWorkerData
      final result = <ServiceWorkerData>[];
      serviceAssignments.forEach((service, assignments) {
        // Contar personal total (sin duplicados)
        final Set<int> uniqueWorkerIds = {};

        final List<Map<String, dynamic>> workersDetails = [];

        // for (var assignment in assignments) {
        //   for (var worker in assignment.workers) {
        //     uniqueWorkerIds.add(worker.id);
        //     workersDetails.add({
        //       'id': worker.id,
        //       'name': worker.name,
        //       'code': worker.code,
        //       'phone': worker.phone,
        //     });
        //   }
        // }

        // Crear objeto con los datos del servicio
        result.add(
          ServiceWorkerData(
            serviceName: service,
            workerCount: uniqueWorkerIds.length,
            dateRange:
                '${intl.DateFormat('dd/MM/yyyy').format(widget.startDate)} - ${intl.DateFormat('dd/MM/yyyy').format(widget.endDate)}',
            assignments: assignments.length,
            workers: workersDetails,
            assignmentList: assignments,
          ),
        );
      });

      // Ordenar por cantidad de trabajadores (de mayor a menor)
      result.sort((a, b) => b.workerCount.compareTo(a.workerCount));

      // Si no hay datos, verificar si hay tareas disponibles
      if (result.isEmpty && tasks.isNotEmpty) {
        debugPrint(
            'No se encontraron asignaciones para servicios en el período');
      }

      return result;
    } catch (e) {
      debugPrint('Error al procesar datos de servicios: $e');
      setState(() {
        _errorMessage = 'Error al procesar datos: $e';
      });
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<OperationsProvider, WorkersProvider, TasksProvider>(
      builder: (context, assignmentsProvider, workersProvider, tasksProvider,
          child) {
        // Verificar el estado de los providers
        debugPrint(
            'AssignmentsProvider isLoading: ${assignmentsProvider.isLoading}');
        debugPrint('TasksProvider isLoading: ${tasksProvider.isLoading}');

        debugPrint('Tasks count: ${tasksProvider.tasks.length}');

        // Verificar si necesitamos cargar datos
        if (_isLoading) {
          // Si estamos esperando y hay datos disponibles, procesar
          if (!assignmentsProvider.isLoading &&
              assignmentsProvider.assignments.isNotEmpty) {
            debugPrint('Procesando datos de asignaciones disponibles');
            _servicesData = processAssignmentData(
                assignmentsProvider.assignments, tasksProvider.tasks);

            _isLoading = false;
          }
          // Si no hay tareas, intentar cargarlas primero
          else if (tasksProvider.tasks.isEmpty && !tasksProvider.isLoading) {
            debugPrint('Solicitando carga de tareas');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              tasksProvider.loadTasksIfNeeded(context);
            });
          }
          // Si no hay asignaciones, intentar cargarlas
          else if (assignmentsProvider.assignments.isEmpty &&
              !assignmentsProvider.isLoading) {
            debugPrint('Solicitando carga de asignaciones');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              assignmentsProvider.loadAssignments(context);
            });
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: _buildContent(assignmentsProvider, tasksProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(
      OperationsProvider assignmentsProvider, TasksProvider tasksProvider) {
    if (_isLoading ||
        assignmentsProvider.isLoading ||
        tasksProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Colors.red[700]),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Al final de _buildContent, justo antes de return _buildChart():
    if (_servicesData.isNotEmpty) {
      debugPrint('Renderizando gráfico con ${_servicesData.length} servicios');
      return Stack(
        children: [
          _buildChart(),
        ],
      );
    }

    return _buildChart();
  }

  Widget _buildChart() {
    return Column(
      children: [
        // Selector de servicios con filtro de búsqueda integrado
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildServiceSelector(),
        ),

        // Leyenda para indicar escala de tamaños
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Tamaño: cantidad de trabajadores',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const Text(' < ',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const Text(' < ',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),

        // Gráfico de burbujas - Ocupa el resto del espacio disponible
        Expanded(
          child: _buildBubbleChart(),
        ),
      ],
    );
  }

  Widget _buildServiceSelector() {
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
            value: _selectedServiceIndex,
            icon: const Icon(Icons.keyboard_arrow_down),
            hint: const Text('Seleccionar servicio...'),
            iconSize: 24,
            elevation: 16,
            style: const TextStyle(
              color: Color(0xFF2D3748),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            borderRadius: BorderRadius.circular(12),
            items: _buildServiceDropdownItems(),
            onChanged: (int? index) {
              setState(() {
                _selectedServiceIndex = index ?? -1;
                // Actualizar índice para detalle de servicio
                if (index != null &&
                    index >= 0 &&
                    index < _servicesData.length) {
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

// Método para construir los elementos del dropdown
  List<DropdownMenuItem<int>> _buildServiceDropdownItems() {
    // Empezar con la opción "Todos los servicios"
    final items = <DropdownMenuItem<int>>[
      const DropdownMenuItem<int>(
        value: -1,
        child: Row(
          children: [
            Icon(Icons.view_module_outlined,
                size: 18, color: Color(0xFF4299E1)),
            SizedBox(width: 8),
            Text(
              'Todos los servicios',
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

    // Si hay datos, agregar cada servicio
    if (_servicesData.isNotEmpty) {
      for (int i = 0; i < _servicesData.length; i++) {
        final data = _servicesData[i];
        final color = _getColorForService(i);

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
                // Nombre del servicio y contador
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          data.serviceName,
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
                          '${data.workerCount}',
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

// Modificar el método _buildBubbleChart para usar el índice de servicio seleccionado
  // Reemplazar el método _buildBubbleChart con este nuevo método de gráfico de barras
  Widget _buildBubbleChart() {
    // Filtrar servicios según la selección del dropdown
    List<ServiceWorkerData> filteredServices;

    if (_selectedServiceIndex == -1) {
      // Si está seleccionado "Todos los servicios", mostrar todos
      filteredServices = _servicesData;
    } else if (_selectedServiceIndex >= 0 &&
        _selectedServiceIndex < _servicesData.length) {
      // Si hay un servicio específico seleccionado, mostrar solo ese
      filteredServices = [_servicesData[_selectedServiceIndex]];
    } else {
      // Fallback a todos los servicios si hay algún error
      filteredServices = _servicesData;
    }

    if (filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center_outlined,
                size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay servicios disponibles para mostrar',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Calcular el valor máximo para escalar las barras correctamente
    final maxValue = math.max(
        1,
        filteredServices.fold<int>(
            0, (max, data) => math.max(max, data.workerCount)));

    return LayoutBuilder(builder: (context, constraints) {
      final double availableWidth = constraints.maxWidth;

      // Calcular el valor máximo para escalar las barras correctamente
      final maxValue = math.max(
          1,
          filteredServices.fold<int>(
              0, (max, data) => math.max(max, data.workerCount)));

      return Stack(
        children: [
          // El gráfico principal en un contenedor de desplazamiento
          _buildHorizontalBarChart(filteredServices, maxValue),

          // Popup de detalles (visible solo cuando hay selección)
          if (_selectedIndex != -1 && _selectedIndex < _servicesData.length)
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: _buildServiceDetailPopup(_servicesData[_selectedIndex]),
            ),
        ],
      );
    });
  }

  // Nuevo método para construir el gráfico de barras horizontales
  Widget _buildHorizontalBarChart(
      List<ServiceWorkerData> services, int maxValue) {
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
            children: List.generate(services.length, (index) {
              final data = services[index];
              final originalIndex = _servicesData.indexOf(data);
              final isSelected = originalIndex == _selectedIndex;
              final serviceColor = _getColorForService(originalIndex);

              // Calcular el ancho de la barra según el valor
              final double barWidthPercentage = data.workerCount / maxValue;

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
                        ? Border.all(color: serviceColor.withOpacity(0.3))
                        : null,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del servicio y contador
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: serviceColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data.serviceName,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 14,
                                color: isSelected
                                    ? serviceColor
                                    : Colors.grey[800],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: serviceColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 14,
                                  color: serviceColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${data.workerCount}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: serviceColor,
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
                                color: serviceColor.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: serviceColor.withOpacity(0.3),
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
                                        '${data.workerCount}',
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
                                'Operaciones: ${data.assignments}',
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

// Reemplaza el método _buildServiceDetailPopup con esta versión mejorada
  Widget _buildServiceDetailPopup(ServiceWorkerData data) {
    final Color serviceColor = _getColorForService(_selectedIndex);

    return Card(
      elevation: 10,
      margin: EdgeInsets.zero, // Eliminar márgenes internos de la Card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: serviceColor, width: 2),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 200, // Reducir la altura para hacerla más compacta
        width: double.infinity, // Asegurar que ocupe todo el ancho disponible
        padding: const EdgeInsets.all(12), // Reducir el padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono del servicio
                Container(
                  padding: const EdgeInsets.all(8), // Reducir tamaño
                  decoration: BoxDecoration(
                    color: serviceColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.business_center_rounded,
                    color: serviceColor,
                    size: 16, // Reducir tamaño
                  ),
                ),
                const SizedBox(width: 8), // Reducir spacing
                // Información del servicio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.serviceName,
                        style: TextStyle(
                          fontSize: 14, // Reducir tamaño
                          fontWeight: FontWeight.bold,
                          color: serviceColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Periodo: ${data.dateRange}',
                        style: TextStyle(
                          fontSize: 10, // Reducir tamaño
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
            const Divider(height: 12, thickness: 1), // Divisor más delgado
            // Área de información con layout mejorado
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Información del servicio - ocupando más espacio
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        // Trabajadores
                        Expanded(
                          child: _buildInfoItemCard(
                            '',
                            '${data.workerCount}',
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
                            '${data.assignments}',
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
                        // Botón más compacto
                        SizedBox(
                          height: 26, // Reducir altura
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.people, size: 12),
                            label: const Text('Ver trabajadores'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF319795),
                              padding: EdgeInsets.zero, // Eliminar padding
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
                        // Botón más compacto
                        SizedBox(
                          height: 26, // Reducir altura
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.assignment, size: 12),
                            label: const Text('Ver operaciones'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDD6B20),
                              side: const BorderSide(color: Color(0xFFDD6B20)),
                              padding: EdgeInsets.zero, // Eliminar padding
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

  // Versión modificada de InfoItemCard para usar en el gráfico de barras
  Widget _buildInfoItemCard(
      String label, String value, IconData icon, Color bgColor, Color iconColor,
      {bool isWide = false, bool isSmall = false}) {
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

  Color _getColorForService(int index) {
    // Lista de colores diferenciables
    final colors = [
      const Color(0xFF3182CE), // Azul
      const Color(0xFF38B2AC), // Verde azulado
      const Color(0xFFED8936), // Naranja
      const Color(0xFF805AD5), // Púrpura
      const Color(0xFFE53E3E), // Rojo
      const Color(0xFF38A169), // Verde
      const Color(0xFFD69E2E), // Amarillo
      const Color(0xFF975A16), // Marrón
      const Color(0xFF2C7A7B), // Verde azulado oscuro
      const Color(0xFF702459), // Rosa oscuro
    ];

    // Retornar color según índice (se repiten si hay más servicios que colores)
    return colors[index % colors.length];
  }

// Método para mostrar el diálogo con los detalles
  void _showDetailDialog({
    required BuildContext context,
    required bool isWorkers,
    required ServiceWorkerData data,
    required String title,
  }) {
    debugPrint('Mostrando diálogo de detalles para $title');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isWorkers ? Icons.people : Icons.assignment,
                size: 20,
                color: _getColorForService(_selectedIndex),
              ),
              const SizedBox(width: 8),
              Text(
                '$title de ${data.serviceName}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getColorForService(_selectedIndex),
                ),
              ),
            ],
          ),
          content: Container(
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

// Construye la lista de trabajadores
  Widget _buildWorkersList(ServiceWorkerData data) {
    return ListView.builder(
      itemCount: data.workers.length,
      itemBuilder: (context, index) {
        final worker = data.workers[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                _getColorForService(_selectedIndex).withOpacity(0.2),
            child: Text(
              worker['name'].substring(0, 1),
              style: TextStyle(
                color: _getColorForService(_selectedIndex),
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

// Construye la lista de asignaciones/operaciones
  Widget _buildAssignmentsList(ServiceWorkerData data) {
    return ListView.builder(
      itemCount: data.assignmentList.length,
      itemBuilder: (context, index) {
        final assignment = data.assignmentList[index];
        return ListTile(
          leading: Icon(
            Icons.assignment,
            color: _getColorForService(_selectedIndex),
          ),
          title: Text('Operación #${assignment.id}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Fecha: ${intl.DateFormat('dd/MM/yyyy').format(assignment.date)}'),
              Text('Estado: ${_getStatusText(assignment.status)}'),
              if (assignment.motorship != null)
                Text('Motonave: ${assignment.motorship}'),
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

class ServiceWorkerData {
  final String serviceName;
  final int workerCount;
  final String dateRange;
  final int assignments;
  final List<Map<String, dynamic>> workers; // Lista detallada de trabajadores
  final List<Operation> assignmentList;

  ServiceWorkerData({
    required this.serviceName,
    required this.workerCount,
    this.dateRange = '',
    this.assignments = 0,
    this.workers = const [],
    this.assignmentList = const [],
  });
}

class BubbleChartGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 1;

    // Dibujar líneas horizontales
    const int hLines = 6;
    for (int i = 1; i < hLines; i++) {
      final y = i * (size.height / hLines);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Dibujar líneas verticales
    const int vLines = 6;
    for (int i = 1; i < vLines; i++) {
      final x = i * (size.width / vLines);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
