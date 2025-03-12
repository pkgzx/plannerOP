import 'package:flutter/material.dart';

class ZoneDistributionChart extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String area;

  const ZoneDistributionChart({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.area,
  }) : super(key: key);

  @override
  State<ZoneDistributionChart> createState() => _ZoneDistributionChartState();
}

class _ZoneDistributionChartState extends State<ZoneDistributionChart> {
  late List<ZoneData> _zoneData;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(ZoneDistributionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate ||
        oldWidget.area != widget.area) {
      _loadData();
    }
  }

  void _loadData() {
    // Datos ficticios para demostración
    _zoneData = [
      ZoneData('Zona A', 35, Colors.blue.shade400),
      ZoneData('Zona B', 28, Colors.blue.shade500),
      ZoneData('Zona C', 22, Colors.blue.shade600),
      ZoneData('Zona D', 15, Colors.blue.shade700),
      ZoneData('Zona E', 10, Colors.blue.shade800),
    ];

    if (widget.area != 'Todas') {
      _zoneData = _zoneData.take(3).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _buildChart(),
        ),
        const SizedBox(height: 20),
        _buildLegend(),
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
            // Círculo animado
            CustomPaint(
              size: const Size(240, 240),
              painter: PieChartPainter(_zoneData, total),
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
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
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
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  isSelected ? zone.color.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: zone.color,
                width: 1,
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
                  '${zone.name}: ${zone.personnel}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? zone.color : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ZoneData {
  final String name;
  final int personnel;
  final Color color;

  ZoneData(this.name, this.personnel, this.color);
}

// Custom painter para dibujar gráfica de pastel
class PieChartPainter extends CustomPainter {
  final List<ZoneData> data;
  final double total;

  PieChartPainter(this.data, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    double startAngle = -0.5 * 3.14159; // Comenzar desde arriba

    for (var item in data) {
      final sweepAngle = (item.personnel / total) * 2 * 3.14159;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, sweepAngle, true, paint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
