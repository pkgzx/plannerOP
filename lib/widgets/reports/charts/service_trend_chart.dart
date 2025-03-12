import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:intl/intl.dart';

class ServiceTrendChart extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String area;

  const ServiceTrendChart({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.area,
  }) : super(key: key);

  @override
  State<ServiceTrendChart> createState() => _ServiceTrendChartState();
}

class _ServiceTrendChartState extends State<ServiceTrendChart> {
  late List<ServiceWorkerData> _servicesData;
  int _selectedIndex = -1;

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
    // Datos simulados de servicios y trabajadores
    final services = [
      'Carga general',
      'Descarga',
      'Almacenaje',
      'Refrigerado',
      'Mantenimiento',
      'Seguridad',
      'Administración',
      'Transporte'
    ];

    // Filtrar servicios basados en el área seleccionada
    List<String> filteredServices = services;
    if (widget.area != 'Todas') {
      // Simular filtrado por área
      if (widget.area == 'CARGA GENERAL') {
        filteredServices = ['Carga general', 'Descarga', 'Almacenaje'];
      } else if (widget.area == 'CARGA REFRIGERADA') {
        filteredServices = ['Refrigerado', 'Descarga'];
      } else if (widget.area == 'MANTENIMIENTO') {
        filteredServices = ['Mantenimiento'];
      } else if (widget.area == 'SEGURIDAD') {
        filteredServices = ['Seguridad'];
      } else if (widget.area == 'ADMINISTRATIVA') {
        filteredServices = ['Administración'];
      }
    }

    // Generar datos simulados para los servicios filtrados
    _servicesData = filteredServices.map((service) {
      // Crear datos aleatorios pero consistentes para cada servicio
      final seed = services.indexOf(service);
      final totalWorkers = 10 + (seed * 4) % 30;

      return ServiceWorkerData(
        serviceName: service,
        workerCount: totalWorkers,
      );
    }).toList();

    // Ordenar por cantidad de trabajadores (de mayor a menor)
    _servicesData.sort((a, b) => b.workerCount.compareTo(a.workerCount));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal por Servicio',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _servicesData.isEmpty
              ? const Center(child: Text('No hay datos disponibles'))
              : _buildChart(),
        ),
      ],
    );
  }

  Widget _buildChart() {
    // Determinar si necesitamos una visualización horizontal o vertical basada en el número de servicios
    return _servicesData.length <= 5
        ? _buildHorizontalBarChart()
        : _buildVerticalBarChart();
  }

  // Gráfico de barras horizontales (mejor para muchos servicios)
  Widget _buildVerticalBarChart() {
    // Calcular el máximo para escalar correctamente
    final maxValue = _servicesData.fold<int>(
        0, (max, data) => math.max(max, data.workerCount));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _servicesData.length,
      itemBuilder: (context, index) {
        final data = _servicesData[index];
        final isSelected = _selectedIndex == index;
        final percentage = data.workerCount / maxValue;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedIndex = isSelected ? -1 : index;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Nombre del servicio
                    SizedBox(
                      width: 120,
                      child: Text(
                        data.serviceName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFF2D3748)
                              : const Color(0xFF718096),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // La barra
                    Expanded(
                      child: Stack(
                        children: [
                          // Fondo de la barra
                          Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),

                          // Barra de progreso
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 24,
                            width: (MediaQuery.of(context).size.width - 150) *
                                percentage,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isSelected
                                    ? [
                                        const Color(0xFF3182CE),
                                        const Color(0xFF4299E1)
                                      ]
                                    : [
                                        const Color(0xFF4299E1)
                                            .withOpacity(0.7),
                                        const Color(0xFF63B3ED)
                                      ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),

                          // Texto con la cantidad
                          Container(
                            height: 24,
                            padding: const EdgeInsets.only(right: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    data.workerCount.toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? const Color(0xFF2C5282)
                                          : const Color(0xFF4299E1),
                                    ),
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

                // Información detallada si está seleccionado
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 8, left: 120),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Servicio: ${data.serviceName}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total de trabajadores: ${data.workerCount}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4A5568),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Periodo: ${_formatDateRange()}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4A5568),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Gráfico de barras verticales (mejor para pocos servicios)
  Widget _buildHorizontalBarChart() {
    // Calcular el valor máximo para la escala vertical
    final maxValue = _servicesData.fold<int>(
      0,
      (max, data) => math.max(max, data.workerCount),
    );

    return Column(
      children: [
        // Gráfica principal
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10, left: 40, right: 16),
            child: CustomPaint(
              size: Size.infinite,
              painter: GridPainter(maxValue),
              child: LayoutBuilder(builder: (context, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(_servicesData.length, (index) {
                    final isSelected = _selectedIndex == index;
                    final data = _servicesData[index];
                    final double barHeight =
                        constraints.maxHeight * (data.workerCount / maxValue);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = isSelected ? -1 : index;
                          });
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Información en tooltip si está seleccionado
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
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Total: ${data.workerCount}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Número sobre la barra
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: isSelected ? 14 : 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF2C5282)
                                    : const Color(0xFF4A5568),
                              ),
                              child: Text(
                                data.workerCount.toString(),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Barra
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: barHeight,
                              width: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: isSelected
                                      ? [
                                          const Color(0xFF3182CE),
                                          const Color(0xFF4299E1)
                                        ]
                                      : [
                                          const Color(0xFF4299E1)
                                              .withOpacity(0.7),
                                          const Color(0xFF63B3ED)
                                        ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF4299E1)
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        ),

        // Etiquetas de servicios
        SizedBox(
          height: 50,
          child: Row(
            children: [
              // Espacio para alinear con el eje Y
              const SizedBox(width: 40),

              // Etiquetas
              Expanded(
                child: Row(
                  children: List.generate(_servicesData.length, (index) {
                    final isSelected = _selectedIndex == index;
                    final label = _servicesData[index].serviceName;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Text(
                            label,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF2D3748)
                                  : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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

  String _formatDateRange() {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    return '${formatter.format(widget.startDate)} - ${formatter.format(widget.endDate)}';
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

    final textPainter = TextPainter();

    // Dibujar líneas horizontales y valores del eje Y
    final steps = 5;
    for (int i = 0; i <= steps; i++) {
      final y = size.height - (i / steps * size.height);

      // Dibujar línea horizontal
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

      // Mostrar valor en el eje Y
      final value = (i * maxValue / steps).round();
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

  ServiceWorkerData({
    required this.serviceName,
    required this.workerCount,
  });
}
