import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/widgets/reports/charts/ship_personnel_chart.dart';
import 'package:plannerop/widgets/reports/charts/zone_distribution_chart.dart';
import 'package:plannerop/widgets/reports/charts/worker_status_chart.dart';
import 'package:plannerop/widgets/reports/charts/service_trend_chart.dart';

class ChartsDashboard extends StatefulWidget {
  final String periodName;
  final DateTime startDate;
  final DateTime endDate;
  final String area;

  const ChartsDashboard({
    Key? key,
    required this.periodName,
    required this.startDate,
    required this.endDate,
    required this.area,
  }) : super(key: key);

  @override
  State<ChartsDashboard> createState() => _ChartsDashboardState();
}

class _ChartsDashboardState extends State<ChartsDashboard> {
  int _selectedChartIndex = 0;
  final PageController _pageController = PageController();

  final List<String> _chartTitles = [
    'Personal por Buque',
    'Distribución por Zona',
    'Estado de Trabajadores',
    'Tendencia de Servicios'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Selector de gráfica
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _chartTitles.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_chartTitles[index]),
                  selected: _selectedChartIndex == index,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedChartIndex = index;
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      });
                    }
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: const Color(0xFF4299E1).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _selectedChartIndex == index
                        ? const Color(0xFF4299E1)
                        : Colors.grey[800],
                    fontWeight: _selectedChartIndex == index
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),

        // Gráficas
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedChartIndex = index;
              });
            },
            children: [
              _buildChartCard(
                context,
                'Personal por Buque',
                'Distribución del personal asignado por embarcación',
                ShipPersonnelChart(
                  startDate: widget.startDate,
                  endDate: widget.endDate,
                  area: widget.area,
                ),
              ),
              _buildChartCard(
                context,
                'Distribución por Zona',
                'Visualización del personal asignado por zona de operación',
                ZoneDistributionChart(
                  startDate: widget.startDate,
                  endDate: widget.endDate,
                  area: widget.area,
                ),
              ),
              _buildChartCard(
                context,
                'Estado de Trabajadores',
                'Distribución de trabajadores por estado (disponible, asignado, incapacitado)',
                WorkerStatusChart(
                  startDate: widget.startDate,
                  endDate: widget.endDate,
                  area: widget.area,
                ),
              ),
              _buildChartCard(
                context,
                'Tendencia de Servicios',
                'Evolución de los servicios realizados a lo largo del tiempo',
                ServiceTrendChart(
                  startDate: widget.startDate,
                  endDate: widget.endDate,
                  area: widget.area,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(
    BuildContext context,
    String title,
    String subtitle,
    Widget chart,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 4,
          intensity: 0.6,
          lightSource: LightSource.topLeft,
          color: Colors.white,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: chart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
