import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';

class ReportFilter extends StatefulWidget {
  final List<String> periods;
  final List<String> areas;
  final String selectedPeriod;
  final String selectedArea;
  final DateTime startDate;
  final DateTime endDate;
  final Function(
      {String? period,
      String? area,
      DateTime? startDate,
      DateTime? endDate}) onApply;

  const ReportFilter({
    Key? key,
    required this.periods,
    required this.areas,
    required this.selectedPeriod,
    required this.selectedArea,
    required this.startDate,
    required this.endDate,
    required this.onApply,
  }) : super(key: key);

  @override
  State<ReportFilter> createState() => _ReportFilterState();
}

class _ReportFilterState extends State<ReportFilter> {
  late String _period;
  late String _area;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _period = widget.selectedPeriod;
    _area = widget.selectedArea;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar reportes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),

          // Selección de periodo
          _buildDropdown(
            'Periodo',
            _period,
            widget.periods,
            (String? value) {
              if (value != null) {
                setState(() {
                  _period = value;

                  // Actualizar fechas según el periodo seleccionado
                  if (value == 'Día') {
                    _startDate = DateTime.now();
                    _endDate = DateTime.now();
                  } else if (value == 'Semana') {
                    _startDate =
                        DateTime.now().subtract(const Duration(days: 7));
                    _endDate = DateTime.now();
                  } else if (value == 'Mes') {
                    _startDate =
                        DateTime(DateTime.now().year, DateTime.now().month, 1);
                    _endDate = DateTime.now();
                  } else if (value == 'Trimestre') {
                    _startDate =
                        DateTime.now().subtract(const Duration(days: 90));
                    _endDate = DateTime.now();
                  }
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Selección de área
          _buildDropdown(
            'Área',
            _area,
            widget.areas,
            (String? value) {
              if (value != null) {
                setState(() {
                  _area = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Fechas personalizadas (mostrar solo si está seleccionado "Personalizado")
          if (_period == 'Personalizado')
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    'Fecha inicio',
                    _startDate,
                    (date) {
                      setState(() {
                        _startDate = date;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    'Fecha fin',
                    _endDate,
                    (date) {
                      setState(() {
                        _endDate = date;
                      });
                    },
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Botones
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              NeumorphicButton(
                style: NeumorphicStyle(
                  depth: 2,
                  intensity: 0.6,
                  color: Colors.white,
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                ),
                onPressed: () {
                  // Restaurar filtros por defecto
                  widget.onApply(
                    period: 'Semana',
                    area: 'Todas',
                    startDate: DateTime.now().subtract(const Duration(days: 7)),
                    endDate: DateTime.now(),
                  );
                },
                child: const Text(
                  'Restablecer',
                  style: TextStyle(
                    color: Color(0xFF718096),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              NeumorphicButton(
                style: NeumorphicStyle(
                  depth: 2,
                  intensity: 0.6,
                  color: const Color(0xFF3182CE),
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                ),
                onPressed: () {
                  widget.onApply(
                    period: _period,
                    area: _area,
                    startDate: _startDate,
                    endDate: _endDate,
                  );
                },
                child: const Text(
                  'Aplicar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF718096)),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged as void Function(String?),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime initialDate,
    Function(DateTime) onDateChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              onDateChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(initialDate),
                    style: const TextStyle(
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF718096),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
