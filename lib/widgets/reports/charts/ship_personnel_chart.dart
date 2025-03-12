import 'package:flutter/material.dart';

class ShipPersonnelChart extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String area;

  const ShipPersonnelChart({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.area,
  }) : super(key: key);

  @override
  State<ShipPersonnelChart> createState() => _ShipPersonnelChartState();
}

class _ShipPersonnelChartState extends State<ShipPersonnelChart> {
  late List<ShipData> _shipData;
  int _selectedIndex = -1;

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
    // Datos ficticios para demostración
    _shipData = [
      ShipData('Motonave Amazon', 28, Colors.blue.shade400),
      ShipData('Buque Pacífico', 22, Colors.blue.shade500),
      ShipData('Sea Voyager', 18, Colors.blue.shade600),
      ShipData('Blue Horizon', 15, Colors.blue.shade700),
      ShipData('Caribbean Star', 12, Colors.blue.shade800),
    ];

    if (widget.area != 'Todas') {
      _shipData = _shipData.take(3).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Personal por Buque',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              SizedBox(
                height: 300,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Eje Y (valores numéricos)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('30',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600])),
                        Text('25',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600])),
                        Text('20',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600])),
                        Text('15',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600])),
                        Text('10',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600])),
                        Text('5',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600])),
                        Text('0',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600])),
                      ],
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
                                    padding: const EdgeInsets.all(6),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: data.color,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${data.personnel} personas',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                // Barra
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 40,
                                  height: data.personnel * 10,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? data.color.withOpacity(1.0)
                                        : data.color.withOpacity(0.7),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(4),
                                    ),
                                  ),
                                ),

                                // Etiqueta de la barra
                                const SizedBox(height: 8),
                                Container(
                                  width: 60,
                                  child: Text(
                                    data.name.length > 10
                                        ? '${data.name.substring(0, 7)}...'
                                        : data.name,
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
          ),
        ),
      ],
    );
  }
}

class ShipData {
  final String name;
  final int personnel;
  final Color color;

  ShipData(this.name, this.personnel, this.color);
}
