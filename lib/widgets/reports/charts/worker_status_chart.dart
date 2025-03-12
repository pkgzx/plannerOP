import 'package:flutter/material.dart';

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
  late List<StatusData> _statusData;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(WorkerStatusChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate ||
        oldWidget.area != widget.area) {
      _loadData();
    }
  }

  void _loadData() {
    // Datos ficticios para demostración
    _statusData = [
      StatusData(
        'Disponible',
        45,
        const Color(0xFF38A169),
        Icons.check_circle,
      ),
      StatusData(
        'Asignado',
        65,
        const Color(0xFF4299E1),
        Icons.assignment,
      ),
      StatusData(
        'Incapacitado',
        12,
        const Color(0xFFE53E3E),
        Icons.healing,
      ),
      StatusData(
        'Vacaciones',
        8,
        const Color(0xFFECC94B),
        Icons.beach_access,
      ),
    ];

    if (widget.area != 'Todas') {
      // Ajustar datos según el área
      _statusData.forEach((status) {
        status.count = (status.count * 0.7).round();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _statusData.length,
            itemBuilder: (context, index) {
              final status = _statusData[index];
              final isSelected = _selectedIndex == index;
              final total =
                  _statusData.fold(0, (sum, item) => sum + item.count);
              final percentage =
                  (status.count / total * 100).toStringAsFixed(1);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = isSelected ? -1 : index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? status.color.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: status.color.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: status.color.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: status.color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          status.icon,
                          color: status.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${status.count} trabajadores',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: status.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: status.color,
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
      ],
    );
  }
}

class StatusData {
  final String name;
  int count;
  final Color color;
  final IconData icon;

  StatusData(this.name, this.count, this.color, this.icon);
}
