import 'package:flutter/material.dart';
import 'package:plannerop/core/model/area.dart';
import './dropdown_field.dart';
import './date_time_fields.dart';

class AssignmentForm extends StatefulWidget {
  final TextEditingController zoneController;
  final TextEditingController startDateController;
  final TextEditingController startTimeController;
  final TextEditingController taskController;
  final List<String> currentTasks;
  final List<Area> areas;
  final Function(String) onAreaSelected;

  const AssignmentForm({
    Key? key,
    required this.zoneController,
    required this.startDateController,
    required this.startTimeController,
    required this.taskController,
    required this.currentTasks,
    required this.areas,
    required this.onAreaSelected,
  }) : super(key: key);

  @override
  State<AssignmentForm> createState() => _AssignmentFormState();
}

class _AssignmentFormState extends State<AssignmentForm> {
  // Variable para forzar actualizaciones visuales
  int _dateUpdateCounter = 0;
  int _timeUpdateCounter = 0;

  @override
  void initState() {
    super.initState();

    // Añadir listeners a los controladores para detectar cambios
    widget.startTimeController.addListener(_onTimeChanged);
    widget.startDateController.addListener(_onDateChanged);
  }

  @override
  void dispose() {
    // Remover listeners para evitar memory leaks
    widget.startTimeController.removeListener(_onTimeChanged);
    widget.startDateController.removeListener(_onDateChanged);
    super.dispose();
  }

  void _onTimeChanged() {
    setState(() {
      _timeUpdateCounter++;
    });
    debugPrint(
        'Hora actualizada: ${widget.startTimeController.text}, contador: $_timeUpdateCounter');
  }

  void _onDateChanged() {
    _handleDateChanged(widget.startDateController.text);
  }

  void _handleDateChanged(String newDate) {
    // Actualizar el contador para forzar rebuild
    setState(() {
      _dateUpdateCounter++;
    });

    // También podríamos resetear el campo de hora si es necesario
    if (widget.startTimeController.text.isNotEmpty) {
      // Opcional: limpiar la hora si cambia la fecha, para forzar una nueva selección
      widget.startTimeController.clear();
    }

    debugPrint('Fecha actualizada: $newDate, contador: $_dateUpdateCounter');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Campo de selección de zona
        DropdownField(
          label: 'Área',
          hint: 'Seleccionar área',
          icon: Icons.location_on_outlined,
          controller: widget.zoneController,
          options: widget.areas.map((area) => area.name).toList(),
          onSelected: widget.onAreaSelected,
        ),

        // Campo de fecha de inicio - Ahora con callback
        DateField(
          label: 'Fecha de inicio',
          hint: 'DD/MM/AAAA',
          icon: Icons.calendar_today_outlined,
          controller: widget.startDateController,
          onDateChanged: _handleDateChanged,
          key: ValueKey('date_field_$_dateUpdateCounter'),
        ),

        // Campo de hora de inicio
        TimeField(
          label: 'Hora de inicio',
          hint: 'HH:MM',
          icon: Icons.schedule_outlined,
          controller: widget.startTimeController,
          dateController: widget.startDateController,
          // Añadir key para forzar reconstrucción cuando la fecha cambia
          key: ValueKey(
              'time_field_${_dateUpdateCounter}_${_timeUpdateCounter}'),
        ),

        // Campo para seleccionar tarea
        DropdownField(
          label: 'Tarea',
          hint: widget.zoneController.text.isEmpty
              ? 'Primero selecciona un área'
              : 'Seleccionar tarea',
          icon: Icons.assignment_outlined,
          controller: widget.taskController,
          options: widget.currentTasks,
          enabled: widget.zoneController.text.isNotEmpty,
          onSelected: (String task) => debugPrint('Tarea seleccionada $task'),
        ),
      ],
    );
  }
}
