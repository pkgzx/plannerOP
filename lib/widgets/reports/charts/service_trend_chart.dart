import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:math' as math;
import 'package:plannerop/core/model/task.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/core/model/assignment.dart';
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
  }

  List<ServiceWorkerData> processAssignmentData(
      List<Assignment> assignments, List<Task> tasks) {
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
              normalizedStatus = 'En progreso';
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
      final Map<String, List<Assignment>> serviceAssignments = {};
      for (var assignment in filteredAssignments) {
        final task = assignment.task;
        if (!serviceAssignments.containsKey(task)) {
          serviceAssignments[task] = [];
        }
        serviceAssignments[task]!.add(assignment);
      }

      // Convertir a ServiceWorkerData
      final result = <ServiceWorkerData>[];
      serviceAssignments.forEach((service, assignments) {
        // Contar personal total (sin duplicados)
        final Set<int> uniqueWorkerIds = {};

        final List<Map<String, dynamic>> workersDetails = [];

        for (var assignment in assignments) {
          for (var worker in assignment.workers) {
            uniqueWorkerIds.add(worker.id);
            workersDetails.add({
              'id': worker.id,
              'name': worker.name,
              'code': worker.code,
              'phone': worker.phone,
            });
          }
        }

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
    return Consumer3<AssignmentsProvider, WorkersProvider, TasksProvider>(
      builder: (context, assignmentsProvider, workersProvider, tasksProvider,
          child) {
        // Verificar el estado de los providers
        debugPrint(
            'AssignmentsProvider isLoading: ${assignmentsProvider.isLoading}');
        debugPrint('TasksProvider isLoading: ${tasksProvider.isLoading}');
        debugPrint(
            'Assignments count: ${assignmentsProvider.assignments.length}');
        debugPrint('Tasks count: ${tasksProvider.tasks.length}');

        // Verificar si necesitamos cargar datos
        if (_isLoading) {
          // Si estamos esperando y hay datos disponibles, procesar
          if (!assignmentsProvider.isLoading &&
              assignmentsProvider.assignments.isNotEmpty) {
            debugPrint('Procesando datos de asignaciones disponibles');
            _servicesData = processAssignmentData(
                assignmentsProvider.assignments, tasksProvider.tasks);
            for (var data in _servicesData) {
              debugPrint(
                  'Service: ${data.serviceName} - Workers: ${data.workerCount}');
            }
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
      AssignmentsProvider assignmentsProvider, TasksProvider tasksProvider) {
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
    // Determinar si necesitamos una visualización horizontal o vertical
    return Column(
      children: [
        // Nueva sección: Leyenda de servicios en la parte superior
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: _servicesData.map((data) {
                  final isSelected =
                      _servicesData.indexOf(data) == _selectedIndex;

                  // Elegir color basado en índice para diferenciar servicios
                  final Color serviceColor =
                      _getColorForService(_servicesData.indexOf(data));

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex =
                            isSelected ? -1 : _servicesData.indexOf(data);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? serviceColor.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: serviceColor,
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
                              color: serviceColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            data.serviceName.length > 20
                                ? '${data.serviceName.substring(0, 18)}...'
                                : data.serviceName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color:
                                  isSelected ? serviceColor : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: serviceColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${data.workerCount}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: serviceColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Gráfico existente
        Expanded(
          child: _servicesData.length <= 5
              ? _buildHorizontalBarChart()
              : _buildVerticalBarChart(),
        ),
      ],
    );
  }

  // Añadir método para obtener color por servicio
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

  Widget _buildVerticalBarChart() {
    // Calcular el máximo para escalar correctamente
    final maxValue = math.max(
        1,
        _servicesData.fold<int>(
            0, (max, data) => math.max(max, data.workerCount)));

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      itemCount: _servicesData.length,
      itemBuilder: (context, index) {
        final data = _servicesData[index];
        final isSelected = _selectedIndex == index;
        final percentage = data.workerCount / maxValue;
        // Usar el color específico del servicio para cada barra
        final serviceColor = _getColorForService(index);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic, // Curva más suave
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Column(
            children: [
              LayoutBuilder(builder: (context, constraints) {
                final availableWidth = constraints.maxWidth -
                    140; // Reservar espacio para el nombre del servicio

                return Row(
                  children: [
                    // Nombre del servicio con color específico
                    Container(
                      width: 120,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: isSelected ? 24 : 18,
                            decoration: BoxDecoration(
                              color: serviceColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            margin: const EdgeInsets.only(right: 8),
                          ),
                          Expanded(
                            child: Text(
                              data.serviceName,
                              style: TextStyle(
                                fontSize: isSelected ? 14 : 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? serviceColor.withOpacity(0.8)
                                    : const Color(0xFF4A5568),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Barra con un tamaño fijo y bien controlado
                    Expanded(
                      child: Container(
                        height: 32,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            // Barra de progreso con animación más suave
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOutCubic,
                              width: availableWidth * percentage,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    serviceColor,
                                    serviceColor.withOpacity(0.7),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: percentage > 0.25
                                  ? Center(
                                      child: Text(
                                        data.serviceName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black26,
                                              blurRadius: 2,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  : null,
                            ),

                            // Contador de trabajadores
                            Positioned(
                              right: 12,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.people_alt_rounded,
                                        size: 12,
                                        color: serviceColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        data.workerCount.toString(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: serviceColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),

              // Información detallada si está seleccionado
              if (isSelected)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(top: 16, bottom: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: serviceColor.withOpacity(0.3), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: serviceColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.business_center_rounded,
                              size: 18,
                              color: serviceColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Servicio",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF718096),
                                  ),
                                ),
                                Text(
                                  data.serviceName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: serviceColor.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItemCard(
                              'Trabajadores',
                              '${data.workerCount}',
                              Icons.people_outline_rounded,
                              const Color(0xFFE6FFFA),
                              const Color(0xFF319795),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoItemCard(
                              'Operaciones',
                              '${data.assignments}',
                              Icons.assignment_outlined,
                              const Color(0xFFFEF5ED),
                              const Color(0xFFDD6B20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItemCard(
                        'Periodo',
                        data.dateRange,
                        Icons.date_range_outlined,
                        const Color(0xFFF0F5FF),
                        const Color(0xFF4C51BF),
                        isWide: true,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItemCard(
      String label, String value, IconData icon, Color bgColor, Color iconColor,
      {bool isWide = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: iconColor.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isWide ? 12 : 14,
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

  Widget _buildHorizontalBarChart() {
    final maxValue = math.max(
        1,
        _servicesData.fold<int>(
            0, (max, data) => math.max(max, data.workerCount)));

    return Column(
      children: [
        // Gráfica principal
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(top: 0, left: 45, right: 16, bottom: 8),
            child: CustomPaint(
              size: Size.infinite,
              painter: GridPainter(maxValue),
              child: LayoutBuilder(builder: (context, constraints) {
                // Calcular el ancho exacto para cada barra
                final barWidth = math.min(
                    45.0, (constraints.maxWidth - 20) / _servicesData.length);
                final spacing =
                    (constraints.maxWidth - (barWidth * _servicesData.length)) /
                        (_servicesData.length + 1);
                // Dejar un pequeño margen en la parte superior para evitar desbordamiento
                final availableHeight = constraints.maxHeight * 0.90;

                return Stack(
                  children: [
                    // Líneas de cuadrícula verticales para cada barra
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(_servicesData.length, (index) {
                        return SizedBox(width: barWidth + spacing);
                      }),
                    ),

                    // Las barras con sus elementos - POSICIÓN FIJA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(_servicesData.length, (index) {
                        final isSelected = _selectedIndex == index;
                        final data = _servicesData[index];
                        final serviceColor = _getColorForService(index);

                        // Cálculo mejorado de altura
                        final barHeightPercentage = data.workerCount / maxValue;
                        final double barHeight = math.max(
                            constraints.maxHeight * 0.05,
                            availableHeight * barHeightPercentage);

                        return SizedBox(
                          width: barWidth,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Número sobre la barra
                              Text(
                                data.workerCount.toString(),
                                style: TextStyle(
                                  fontSize: isSelected ? 14 : 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: serviceColor,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Barra con altura animada - SIN CAMBIAR SU ANCHO AL SELECCIONAR
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = isSelected ? -1 : index;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutQuad,
                                  height: barHeight,
                                  width: barWidth * 0.75,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        serviceColor,
                                        serviceColor.withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(6),
                                      topRight: Radius.circular(6),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: serviceColor.withOpacity(
                                            isSelected ? 0.4 : 0.2),
                                        blurRadius: isSelected ? 8 : 3,
                                        offset: const Offset(0, 2),
                                        spreadRadius: isSelected ? 1 : 0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),

                    // INFORMACIÓN DETALLADA EN OVERLAY - No afecta al layout
                    if (_selectedIndex != -1)
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: math.max(300.0, constraints.maxWidth * 0.8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(
                                color: _getColorForService(_selectedIndex)
                                    .withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            _getColorForService(_selectedIndex)
                                                .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.business_center_rounded,
                                        size: 16,
                                        color:
                                            _getColorForService(_selectedIndex),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _servicesData[_selectedIndex]
                                            .serviceName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _getColorForService(
                                              _selectedIndex),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedIndex = -1;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoChip(
                                        'Trabajadores',
                                        '${_servicesData[_selectedIndex].workerCount}',
                                        Icons.people_outline_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildInfoChip(
                                        'Operaciones',
                                        '${_servicesData[_selectedIndex].assignments}',
                                        Icons.assignment_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  // Método auxiliar para el chip de información con detalle al hacer clic
  Widget _buildInfoChip(String label, String value, IconData icon,
      {bool isWorkersChip = false}) {
    return GestureDetector(
      onTap: () {
        if (_selectedIndex >= 0) {
          _showDetailDialog(
            context: context,
            isWorkers: isWorkersChip,
            data: _servicesData[_selectedIndex],
            title: isWorkersChip ? 'Trabajadores' : 'Operaciones',
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: Colors.grey[700]),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Colors.grey[500],
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
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
        return 'En progreso';
      case 'PENDING':
        return 'Pendiente';
      case 'CANCELED':
        return 'Cancelada';
      default:
        return status;
    }
  }
}

class GridPainter extends CustomPainter {
  final int maxValue;

  GridPainter(this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    // Corregir el TextPainter añadiendo textDirection
    final textPainter = TextPainter(
        textDirection: TextDirection.ltr // Esta es la línea clave que falta
        );

    // Dibujar líneas horizontales y valores del eje Y
    final steps = 5;
    for (int i = 0; i <= steps; i++) {
      final y = size.height - (i / steps * size.height);

      // Dibujar línea horizontal
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

      // Mostrar valor en el eje Y
      final value = (i * (maxValue) / steps).round();
      textPainter.text = TextSpan(
        text: value.toString(),
        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(-25, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) =>
      oldDelegate.maxValue != maxValue;
}

class ServiceWorkerData {
  final String serviceName;
  final int workerCount;
  final String dateRange;
  final int assignments;
  final List<Map<String, dynamic>> workers; // Lista detallada de trabajadores
  final List<Assignment> assignmentList;

  ServiceWorkerData({
    required this.serviceName,
    required this.workerCount,
    this.dateRange = '',
    this.assignments = 0,
    this.workers = const [],
    this.assignmentList = const [],
  });
}
