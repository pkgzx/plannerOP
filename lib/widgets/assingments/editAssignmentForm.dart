import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/area.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/core/model/client.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/store/clients.dart';
import 'package:plannerop/store/task.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/assingments/date_time_fields.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/widgets/assingments/dropdown_field.dart';
import 'package:plannerop/widgets/assingments/workerSelection.dart';

class EditAssignmentForm extends StatefulWidget {
  final Assignment assignment;
  final Function(Assignment) onSave;
  final VoidCallback onCancel;

  const EditAssignmentForm({
    Key? key,
    required this.assignment,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  _EditAssignmentFormState createState() => _EditAssignmentFormState();
}

class _EditAssignmentFormState extends State<EditAssignmentForm> {
  // Controladores
  late TextEditingController _areaController;
  late TextEditingController _taskController;
  late TextEditingController _startDateController;
  late TextEditingController _startTimeController;
  late TextEditingController _endDateController;
  late TextEditingController _endTimeController;
  late TextEditingController _zoneController;
  late TextEditingController _motorshipController;
  late TextEditingController _clientController;

  // Estado de la edición
  late List<Worker> _selectedWorkers;
  bool _isShipArea = false;

  // Contadores para forzar la reconstrucción de los campos de fecha/hora
  int _dateUpdateCounter = 0;
  int _timeUpdateCounter = 0;
  int _endDateUpdateCounter = 0;
  int _endTimeUpdateCounter = 0;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores con los datos de la asignación
    _areaController = TextEditingController(text: widget.assignment.area);
    _taskController = TextEditingController(text: widget.assignment.task);
    _startDateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(widget.assignment.date),
    );
    _startTimeController = TextEditingController(text: widget.assignment.time);
    _endDateController = TextEditingController(
      text: widget.assignment.endDate != null
          ? DateFormat('dd/MM/yyyy').format(widget.assignment.endDate!)
          : '',
    );
    _endTimeController = TextEditingController(
      text: widget.assignment.endTime ?? '',
    );
    _zoneController =
        TextEditingController(text: 'Zona ${widget.assignment.zone}');
    _motorshipController = TextEditingController(
      text: widget.assignment.motorship ?? '',
    );
    _clientController = TextEditingController();

    // Inicializar trabajadores seleccionados
    _selectedWorkers = List.from(widget.assignment.workers);

    // Verificar si es un área de barco
    _checkIfShipArea(widget.assignment.area);

    // Buscar el nombre del cliente después del build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeClientName();
    });
  }

  void _initializeClientName() {
    final clientsProvider =
        Provider.of<ClientsProvider>(context, listen: false);
    final client = clientsProvider.getClientById(widget.assignment.clientId);
    if (client != null) {
      _clientController.text = client.name;
    }
  }

  void _checkIfShipArea(String area) {
    setState(() {
      _isShipArea = area.toUpperCase().contains('BUQUE');
    });
  }

  void _handleDateChanged(String date) {
    setState(() {
      _timeUpdateCounter++;
    });
  }

  void _handleEndDateChanged(String date) {
    setState(() {
      _endTimeUpdateCounter++;
    });
  }

  @override
  void dispose() {
    _areaController.dispose();
    _taskController.dispose();
    _startDateController.dispose();
    _startTimeController.dispose();
    _endDateController.dispose();
    _endTimeController.dispose();
    _zoneController.dispose();
    _motorshipController.dispose();
    _clientController.dispose();
    super.dispose();
  }

  // Dentro de la clase _EditAssignmentFormState, modifica el método build()

  @override
  Widget build(BuildContext context) {
    // Proveedores necesarios para las selecciones
    final areasProvider = Provider.of<AreasProvider>(context);
    final tasksProvider = Provider.of<TasksProvider>(context);
    final clientsProvider = Provider.of<ClientsProvider>(context);
    final workersProvider = Provider.of<WorkersProvider>(context);

    var client = clientsProvider.getClientById(widget.assignment.clientId);

    // Listas de opciones
    final List<String> zones =
        List.generate(10, (index) => 'Zona ${index + 1}');

    return Container(
      height: MediaQuery.of(context).size.height *
          0.85, // Reducir un poco la altura
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3182CE).withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Editar Asignación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
          ),

          // Formulario
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de trabajadores
                  WorkerSelectionWidget(
                    selectedWorkers: _selectedWorkers,
                    allWorkers: workersProvider.getWorkersAvailable(),
                    deletedWorkers: widget.assignment.deletedWorkers,
                    onSelectionChanged: (workers, deletedWorkers) {
                      setState(() {
                        _selectedWorkers = workers;
                        // Store deleted workers in the assignment
                        widget.assignment.deletedWorkers = deletedWorkers;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Campo de área (NO editable)
                  _buildNonEditableField(
                    label: 'Área',
                    value: widget.assignment.area,
                    icon: Icons.location_on_outlined,
                  ),

                  // Campo de motonave (NO editable - condicional)
                  if (_isShipArea)
                    _buildNonEditableField(
                      label: 'Nombre de Motonave',
                      value: widget.assignment.motorship ?? 'No especificada',
                      icon: Icons.directions_boat,
                    ),

                  // Campos de fecha y hora de inicio (editables)
                  DateField(
                    label: 'Fecha de inicio',
                    hint: 'DD/MM/AAAA',
                    icon: Icons.calendar_today_outlined,
                    controller: _startDateController,
                    onDateChanged: _handleDateChanged,
                    key: ValueKey('date_field_$_dateUpdateCounter'),
                  ),

                  TimeField(
                    label: 'Hora de inicio',
                    hint: 'HH:MM',
                    icon: Icons.schedule_outlined,
                    controller: _startTimeController,
                    dateController: _startDateController,
                    key: ValueKey(
                        'time_field_${_dateUpdateCounter}_${_timeUpdateCounter}'),
                  ),

                  // Divider para campos opcionales
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "FINALIZACIÓN (OPCIONAL)",
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                  ),

                  // Campos opcionales de fecha y hora de finalización (editables)
                  DateField(
                    label: 'Fecha de finalización',
                    hint: 'DD/MM/AAAA',
                    icon: Icons.event_outlined,
                    controller: _endDateController,
                    onDateChanged: _handleEndDateChanged,
                    key: ValueKey('end_date_field_$_endDateUpdateCounter'),
                    isOptional: true,
                  ),

                  TimeField(
                    label: 'Hora de finalización',
                    hint: 'HH:MM',
                    icon: Icons.access_time_outlined,
                    controller: _endTimeController,
                    dateController: _endDateController,
                    key: ValueKey(
                        'end_time_field_${_endDateUpdateCounter}_${_endTimeUpdateCounter}'),
                    isOptional: true,
                  ),

                  // Campo de tarea/servicio (NO editable)
                  _buildNonEditableField(
                    label: 'Servicio',
                    value: widget.assignment.task,
                    icon: Icons.assignment_outlined,
                  ),

                  // Campo de zona (NO editable)
                  _buildNonEditableField(
                    label: 'Zona',
                    value: 'Zona ${widget.assignment.zone}',
                    icon: Icons.grid_view_outlined,
                  ),

                  // Campo de cliente (NO editable)
                  _buildNonEditableField(
                    label: 'Cliente',
                    value: client.name,
                    icon: Icons.person_outline,
                  ),
                ],
              ),
            ),
          ),

          // Botones de acción
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: NeumorphicButton(
                    style: NeumorphicStyle(
                      depth: 2,
                      intensity: 0.7,
                      color: Colors.white,
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(8)),
                    ),
                    onPressed: widget.onCancel,
                    child: const Text(
                      'Cancelar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF718096),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeumorphicButton(
                    style: NeumorphicStyle(
                      depth: 2,
                      intensity: 0.7,
                      color: const Color(0xFF3182CE),
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(8)),
                    ),
                    onPressed: () => _saveChanges(context),
                    child: const Text(
                      'Guardar Cambios',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Nuevo método para crear campos no editables con el mismo estilo que los editables
  Widget _buildNonEditableField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
              color: const Color(
                  0xFFF7FAFC), // Color de fondo más claro para indicar que no es editable
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF718096)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF2D3748),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveChanges(BuildContext context) {
    try {
      // Validaciones
      if (_selectedWorkers.isEmpty) {
        _showValidationError('Por favor, selecciona al menos un trabajador');
        return;
      }

      if (_startDateController.text.isEmpty) {
        _showValidationError('Por favor, selecciona una fecha de inicio');
        return;
      }

      if (_startTimeController.text.isEmpty) {
        _showValidationError('Por favor, selecciona una hora de inicio');
        return;
      }

      // Validación para motonave en área de buque
      if (_isShipArea && _motorshipController.text.isEmpty) {
        _showValidationError('Por favor, ingresa el nombre de la motonave');
        return;
      }

      // Obtener providers
      final workersProvider =
          Provider.of<WorkersProvider>(context, listen: false);

      // Procesar fecha y hora
      final startDate =
          DateFormat('dd/MM/yyyy').parse(_startDateController.text);

      // Procesar fecha y hora de fin
      DateTime? endDate;
      if (_endDateController.text.isNotEmpty) {
        endDate = DateFormat('dd/MM/yyyy').parse(_endDateController.text);
      }

      // Identificar trabajadores agregados y removidos para actualizar su estado
      final List<Worker> addedWorkers = [];
      final List<Worker> removedWorkers = [];

      // Encontrar trabajadores que se añadieron (están en selectedWorkers pero no en assignment.workers)
      for (var worker in _selectedWorkers) {
        if (!widget.assignment.workers.any((w) => w.id == worker.id)) {
          addedWorkers.add(worker);
        }
      }

      // Encontrar trabajadores que se quitaron (están en assignment.workers pero no en selectedWorkers)
      for (var worker in widget.assignment.workers) {
        if (!_selectedWorkers.any((w) => w.id == worker.id)) {
          removedWorkers.add(worker);
        }
      }

      // Actualizar estados de los trabajadores
      for (var worker in addedWorkers) {
        workersProvider.assignWorkerObject(worker, context);
      }

      for (var worker in removedWorkers) {
        workersProvider.releaseWorkerObject(worker, context);
      }

      // Crear la asignación actualizada con los valores editables
      final updatedAssignment = Assignment(
        id: widget.assignment.id,
        workers: _selectedWorkers,
        area: widget.assignment.area, // No editable
        task: widget.assignment.task, // No editable
        date: startDate, // Editable
        time: _startTimeController.text, // Editable
        zone: widget.assignment.zone, // No editable
        status: widget.assignment.status, // No editable por este formulario
        endDate: endDate, // Editable
        endTime: _endTimeController.text.isNotEmpty
            ? _endTimeController.text
            : null, // Editable
        motorship: _isShipArea
            ? _motorshipController.text
            : null, // Editable si es área de buque
        userId: widget.assignment.userId, // No editable
        areaId: widget.assignment.areaId, // No editable
        taskId: widget.assignment.taskId, // No editable
        clientId: widget.assignment.clientId, // No editable
        deletedWorkers:
            widget.assignment.deletedWorkers, // Include deleted workers
      );

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Llamar al callback con la asignación actualizada
      widget.onSave(updatedAssignment);
    } catch (e) {
      debugPrint('Error al guardar cambios: $e');
      _showValidationError('Ha ocurrido un error al guardar los cambios');
    }
  }

  void _showValidationError(String message) {
    showErrorToast(context, message);
  }
}

// Función global para mostrar el formulario de edición como modal bottom sheet
Future<void> showEditAssignmentForm(
  BuildContext context,
  Assignment assignment,
) async {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final assignmentsProvider =
          Provider.of<AssignmentsProvider>(context, listen: false);

      return EditAssignmentForm(
        assignment: assignment,
        onSave: (updatedAssignment) async {
          // Cerrar el formulario primero
          Navigator.pop(context);

          // Mostrar indicador de carga
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          try {
            // Actualizar la asignación
            final success = await assignmentsProvider.updateAssignment(
              updatedAssignment,
              context,
            );

            // Cerrar indicador de carga
            Navigator.pop(context);

            if (success) {
              showSuccessToast(context, 'Asignación actualizada correctamente');
            } else {
              showErrorToast(context, 'No se pudo actualizar la asignación');
            }
          } catch (e) {
            // Cerrar indicador de carga si hay error
            Navigator.pop(context);

            showErrorToast(
                context, 'Ha ocurrido un error al actualizar la asignación');
          }
        },
        onCancel: () {
          Navigator.pop(context);
        },
      );
    },
  );
}
