import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/store/workers.dart';

import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/assingments/components/buildWorkerItem.dart';
import 'package:plannerop/widgets/assingments/editAssignmentForm.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/widgets/assingments/emptyState.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/widgets/assingments/components/showCompletionDialog.dart';
import 'package:plannerop/widgets/assingments/components/utils.dart';

// Actualizar ActiveAssignmentsView para mostrar indicador sutil de actualización
class ActiveAssignmentsView extends StatefulWidget {
  final String searchQuery;

  const ActiveAssignmentsView({Key? key, required this.searchQuery})
      : super(key: key);

  @override
  _ActiveAssignmentsViewState createState() => _ActiveAssignmentsViewState();
}

class _ActiveAssignmentsViewState extends State<ActiveAssignmentsView> {
  String? _selectedArea;
  int? _selectedSupervisorId;
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    // Obtener áreas disponibles del provider
    final areasProvider = Provider.of<AreasProvider>(context);
    final areas = areasProvider.areas
        .map((area) => area.name) // sacar las areas unicas
        .toSet()
        .toList();

    // Verificar si el área seleccionada ya no existe en la lista filtrada
    if (_selectedArea != null && !areas.contains(_selectedArea)) {
      // Resetear si el área ya no existe
      _selectedArea = null;
    }

    // Obtener supervisores disponibles del provider
    final chargersProvider = Provider.of<ChargersOpProvider>(context);
    final supervisors = chargersProvider.chargers;

    // Verificar si el supervisor seleccionado aún existe
    if (_selectedSupervisorId != null &&
        !supervisors.any((s) => s.id == _selectedSupervisorId)) {
      _selectedSupervisorId = null;
    }

    return Consumer<AssignmentsProvider>(
      builder: (context, assignmentsProvider, child) {
        if (assignmentsProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        var activeAssignments = assignmentsProvider.inProgressAssignments;

        // Ordenar y traer las más recientes
        activeAssignments.sort((a, b) => b.date.compareTo(a.date));

        // Aplicar filtros
        var filteredAssignments = activeAssignments.where((assignment) {
          // Filtrar por texto de búsqueda
          bool matchesSearch = true;
          if (widget.searchQuery.isNotEmpty) {
            final matchesTask = assignment.task
                .toLowerCase()
                .contains(widget.searchQuery.toLowerCase());
            final matchesWorker = assignment.workers.any((worker) => worker.name
                .toString()
                .toLowerCase()
                .contains(widget.searchQuery.toLowerCase()));
            matchesSearch = matchesTask || matchesWorker;
          }

          // Filtrar por área seleccionada
          bool matchesArea = true;
          if (_selectedArea != null && _selectedArea!.isNotEmpty) {
            matchesArea = assignment.area == _selectedArea;
          }

          // Filtrar por supervisor seleccionado
          bool matchesSupervisor = true;
          if (_selectedSupervisorId != null) {
            matchesSupervisor =
                assignment.inChagers.contains(_selectedSupervisorId);
          }

          return matchesSearch && matchesArea && matchesSupervisor;
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            // Si tuviéramos una recarga desde API la llamaríamos aquí
          },
          child: Column(
            children: [
              _buildFilterBar(areas, supervisors),
              Expanded(
                child: filteredAssignments.isEmpty
                    ? EmptyState(
                        message: activeAssignments.isEmpty
                            ? 'No hay asignaciones activas en este momento.'
                            : 'No hay asignaciones activas que coincidan con los filtros aplicados.',
                        showClearButton: widget.searchQuery.isNotEmpty ||
                            _selectedArea != null ||
                            _selectedSupervisorId != null,
                        onClear: () {
                          setState(() {
                            _selectedArea = null;
                            _selectedSupervisorId = null;
                          });
                        },
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: filteredAssignments.length,
                            itemBuilder: (context, index) {
                              final assignment = filteredAssignments[index];
                              return _buildAssignmentCard(
                                  context, assignment, assignmentsProvider);
                            },
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

  Widget _buildFilterBar(List<String> areas, List<User> supervisors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              Spacer(),
              NeumorphicButton(
                style: NeumorphicStyle(
                  depth: 2,
                  intensity: 0.7,
                  boxShape: NeumorphicBoxShape.circle(),
                  color: _showFilters
                      ? const Color(0xFF3182CE)
                      : const Color(0xFFE2E8F0),
                ),
                padding: const EdgeInsets.all(8),
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                child: Icon(
                  Icons.filter_list,
                  size: 18,
                  color: _showFilters ? Colors.white : const Color(0xFF718096),
                ),
              ),
            ],
          ),
          if (_showFilters) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Área',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    value: _selectedArea,
                    hint: Text('Todas las áreas'),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('Todas las áreas'),
                      ),
                      ...areas.map((area) => DropdownMenuItem<String>(
                            value: area,
                            child: Text(area),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedArea = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Supervisor',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    value: _selectedSupervisorId,
                    hint: Text('Todos los supervisores'),
                    isExpanded: true,
                    // Personalizar cómo se muestra el elemento seleccionado
                    selectedItemBuilder: (BuildContext context) {
                      return supervisors.map<Widget>((User supervisor) {
                        return Container(
                          alignment: Alignment.centerLeft,
                          constraints: BoxConstraints(minWidth: 100),
                          child: Text(
                            supervisor.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: Color(0xFF2D3748),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList()
                        ..insert(
                            0,
                            Text(
                                'Todos los supervisores')); // Para el caso null
                    },
                    // Limitar altura máxima del menú desplegable
                    menuMaxHeight: 300,
                    // Separación entre elementos
                    itemHeight: 60,
                    items: [
                      DropdownMenuItem<int>(
                        value: null,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFEDF2F7),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text('Todos los supervisores'),
                        ),
                      ),
                      ...supervisors.map((supervisor) => DropdownMenuItem<int>(
                            value: supervisor.id,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFFEDF2F7),
                                    width: 1,
                                  ),
                                ),
                              ),
                              // En el menú desplegado podemos mostrar el nombre completo
                              child: Text(supervisor.name),
                            ),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSupervisorId = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            if (_selectedArea != null || _selectedSupervisorId != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: 2,
                    intensity: 0.7,
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onPressed: () {
                    setState(() {
                      _selectedArea = null;
                      _selectedSupervisorId = null;
                    });
                  },
                  child: Text(
                    'Limpiar filtros',
                    style: TextStyle(
                      color: Color(0xFF718096),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(BuildContext context, Assignment assignment,
      AssignmentsProvider provider) {
    final areas_provider = Provider.of<AreasProvider>(context, listen: false);

    return Neumorphic(
      style: NeumorphicStyle(
        depth: 4,
        intensity: 0.5,
        color: Colors.white,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
        lightSource: LightSource.topLeft,
        shadowDarkColorEmboss: Colors.grey.withOpacity(0.2),
        shadowLightColorEmboss: Colors.white,
      ),
      child: InkWell(
        onTap: () => _showAssignmentDetails(context, assignment),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: const Color(0xFF3182CE),
                width: 4,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3182CE).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3182CE),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'EN CURSO',
                      style: TextStyle(
                        color: Color(0xFF3182CE),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Task name - Usando Expanded para mejor adaptación
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.task,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Area with icon
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: Color(0xFF718096),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            areas_provider
                                    .getAreaById(assignment.areaId)
                                    ?.name ??
                                "",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF718096),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Elegant separator
              Container(
                height: 1,
                color: const Color(0xFFEDF2F7),
                margin: const EdgeInsets.only(bottom: 6),
              ),

              // Info footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Fecha - más compacta
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 10,
                        color: const Color(0xFF718096).withOpacity(0.8),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        DateFormat('dd/MM/yy').format(assignment.date),
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF718096).withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Worker count - más compacto
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 10,
                        color: const Color(0xFF718096).withOpacity(0.8),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        "${assignment.workers.length}",
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF718096).withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Complete button - elegante pero compacto
                  Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38A169),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38A169).withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => showCompletionDialog(
                            context: context,
                            assignment: assignment,
                            provider: provider),
                        customBorder: const CircleBorder(),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignmentDetails(BuildContext context, Assignment assignment) {
    final assignmentsProvider =
        Provider.of<AssignmentsProvider>(context, listen: false);

    final inChargersFormat =
        Provider.of<ChargersOpProvider>(context, listen: false)
            .chargers
            .where((charger) => assignment.inChagers.contains(charger.id))
            .map((charger) {
      return User(
        id: charger.id,
        name: charger.name,
        cargo: charger.cargo,
        dni: charger.dni,
        phone: charger.phone,
      );
    }).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.85,
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
                      color: const Color.fromARGB(255, 13, 184, 84)
                          .withOpacity(0.1),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                assignment.task,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.room_outlined,
                              size: 16,
                              color: Color.fromARGB(255, 11, 80, 53),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              assignment.area,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 11, 80, 53),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailsSection(
                            title: 'Detalles de la asignación',
                            children: [
                              buildDetailRow(
                                  'Fecha',
                                  DateFormat('dd/MM/yyyy')
                                      .format(assignment.date)),
                              buildDetailRow('Hora', assignment.time),
                              buildDetailRow('Estado', 'En curso'),
                              if (assignment.endTime != null)
                                buildDetailRow('Hora de finalización',
                                    assignment.endTime ?? 'No especificada'),
                              if (assignment.endDate != null)
                                buildDetailRow(
                                    'Fecha de finalización',
                                    DateFormat('dd/MM/yyyy')
                                        .format(assignment.endDate!)),
                              buildDetailRow('Zona', 'Zona ${assignment.zone}'),
                              if (assignment.motorship != "" &&
                                  assignment.motorship != null)
                                buildDetailRow(
                                    'Motonave', assignment.motorship ?? ''),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildWorkersSection(assignment),
                          const SizedBox(height: 20),
                          assignment.deletedWorkers.map(
                            (worker) {
                              return buildWorkerItem(worker);
                            },
                          ).isNotEmpty
                              ? _buildDetailsSection(
                                  title: 'Trabajadores eliminados',
                                  children: assignment.deletedWorkers.map(
                                    (worker) {
                                      return buildWorkerItem(worker,
                                          isDeleted: true);
                                    },
                                  ).toList(),
                                )
                              : const SizedBox(),
                          const SizedBox(height: 20),

                          // cargar los encargados de la operacion
                          _buildDetailsSection(
                            title: 'Encargados de la operación',
                            children: inChargersFormat.map((charger) {
                              return buildInChargerItem(charger);
                            }).toList(),
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),

                  // Action buttons
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
                            onPressed: () {
                              Navigator.pop(context);

                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.9,
                                        maxHeight:
                                            MediaQuery.of(context).size.height *
                                                0.9,
                                      ),
                                      child: EditAssignmentForm(
                                        assignment: assignment,
                                        onSave: (updatedAssignment) {
                                          assignmentsProvider.updateAssignment(
                                              updatedAssignment, context);
                                          showSuccessToast(context,
                                              'Asignación actualizada');
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        },
                                        onCancel: () => Navigator.pop(context),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: const Text(
                              'Editar',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF3182CE),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Consumer<AssignmentsProvider>(
                              builder: (context, provider, child) {
                            return NeumorphicButton(
                              style: NeumorphicStyle(
                                depth: 2,
                                intensity: 0.7,
                                color: const Color(0xFF3182CE),
                                boxShape: NeumorphicBoxShape.roundRect(
                                    BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                showCompletionDialog(
                                    context: context,
                                    assignment: assignment,
                                    provider: provider);
                              },
                              child: const Text(
                                'Completar',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Botón flotante de cancelar en la esquina inferior derecha
            Positioned(
              right: 20,
              bottom: 90, // Colocado encima de los botones principales
              child: NeumorphicButton(
                style: NeumorphicStyle(
                  depth: 4,
                  intensity: 0.8,
                  color: const Color(0xFFF56565),
                  boxShape: NeumorphicBoxShape.circle(),
                  shadowDarkColor: const Color(0xFFC53030).withOpacity(0.4),
                ),
                padding: const EdgeInsets.all(16),
                onPressed: () {
                  Navigator.pop(context);
                  _showCancelDialog(context, assignment, assignmentsProvider);
                },
                // garbage icon
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Método para mostrar el diálogo de cancelación (agregarlo si no existe)
  void _showCancelDialog(BuildContext context, Assignment assignment,
      AssignmentsProvider provider) {
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Cancelar asignación'),
              content: const Text(
                '¿Estás seguro de que deseas cancelar esta asignación?',
                style: TextStyle(color: Color(0xFF718096)),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isProcessing ? null : () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    foregroundColor: isProcessing
                        ? const Color(0xFFCBD5E0)
                        : const Color(0xFF718096),
                  ),
                  child: const Text('No'),
                ),
                NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: isProcessing ? 0 : 2,
                    intensity: 0.7,
                    color: isProcessing
                        ? const Color(0xFFFED7D7)
                        : const Color(0xFFF56565),
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                  ),
                  onPressed: isProcessing
                      ? null
                      : () async {
                          setDialogState(() {
                            isProcessing = true;
                          });

                          try {
                            debugPrint(
                                'Cancelando asignación ${assignment.id}');

                            // Aquí iría la llamada a la API para cancelar
                            final success =
                                await provider.updateAssignmentStatus(
                                    assignment.id ?? 0, 'CANCELED', context);

                            final workersProvider =
                                Provider.of<WorkersProvider>(context,
                                    listen: false);
                            for (var worker in assignment.workers) {
                              workersProvider.releaseWorkerObject(
                                  worker, context);
                            }

                            Navigator.pop(dialogContext);
                            showSuccessToast(
                                context, 'Asignación cancelada exitosamente');
                          } catch (e) {
                            debugPrint('Error al cancelar asignación: $e');

                            if (context.mounted) {
                              setDialogState(() {
                                isProcessing = false;
                              });
                              showErrorToast(
                                  context, 'Error al cancelar asignación: $e');
                            }
                          }
                        },
                  child: Container(
                    width: 100,
                    height: 36,
                    child: Center(
                      child: isProcessing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Procesando',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Sí, cancelar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWorkersSection(Assignment assignment) {
    // Obtener los grupos de la asignación
    final groups = assignment.groups;
    final assignmentsProvider =
        Provider.of<AssignmentsProvider>(context, listen: false);

    // Fecha y hora actual para comparar
    final DateTime now = DateTime.now();

    // Agrupar los workers por su grupo
    Map<String, List<Worker>> workersByGroup = {};
    List<Worker> ungroupedWorkers = [];

    // Conjunto para seguir los IDs de trabajadores que ya están en grupos o finalizados
    Set<int> groupedWorkerIds = {};
    Set<int> finishedWorkerIds =
        assignment.workersFinished.map((w) => w.id).toSet();

    // Asignar colores únicos a cada grupo
    Map<String, Color> groupColors = {};
    List<Color> groupColorOptions = [
      const Color(0xFFE6FFFA), // Verde claro
      const Color(0xFFEBF4FF), // Azul claro
      const Color(0xFFFEF3C7), // Amarillo claro
      const Color(0xFFFEE2E2), // Rojo claro
      const Color(0xFFFAF5FF), // Púrpura claro
    ];

    int colorIndex = 0;

    // Primero: identificar todos los trabajadores en grupos
    for (var group in groups) {
      // Solo considerar los grupos que no han finalizado o que su fecha de finalización es futura
      bool isGroupFinished = false;
      if (group.endDate != null && group.endTime != null) {
        // Parsear la fecha y hora de finalización
        try {
          final endDate = DateTime.parse(group.endDate!);
          final timeParts = group.endTime!.split(':');
          final endDateTime = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );

          if (endDateTime.isBefore(now)) {
            isGroupFinished = true;
          }
        } catch (e) {
          debugPrint('Error al parsear fecha/hora: $e');
        }
      }

      // Verificar si todos los trabajadores del grupo están en workersFinished
      if (group.workers
          .every((workerId) => finishedWorkerIds.contains(workerId))) {
        isGroupFinished = true;
      }

      // Si el grupo no ha finalizado o queremos mostrar todos incluyendo los finalizados
      if (!isGroupFinished) {
        // Asignar un color único al grupo
        if (!groupColors.containsKey(group.id)) {
          groupColors[group.id] =
              groupColorOptions[colorIndex % groupColorOptions.length];
          colorIndex++;
        }

        // Inicializar lista para este grupo
        workersByGroup[group.id] = [];

        // Añadir IDs de trabajadores de este grupo al conjunto de agrupados
        for (var workerId in group.workers) {
          // Solo añadir si no está finalizado
          if (!finishedWorkerIds.contains(workerId)) {
            groupedWorkerIds.add(workerId);
          }
        }
      }
    }

    // Segundo: clasificar trabajadores en sus grupos correspondientes
    for (var worker in assignment.workers) {
      // Saltarse trabajadores que ya están finalizados
      if (finishedWorkerIds.contains(worker.id)) {
        continue;
      }

      bool assignedToGroup = false;

      // Buscar en qué grupo está este trabajador
      for (var group in groups) {
        // Verificar si el grupo ya ha finalizado
        bool isGroupFinished = false;
        if (group.endDate != null && group.endTime != null) {
          try {
            final endDate = DateTime.parse(group.endDate!);
            final timeParts = group.endTime!.split(':');
            final endDateTime = DateTime(
              endDate.year,
              endDate.month,
              endDate.day,
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
            );

            if (endDateTime.isBefore(now)) {
              isGroupFinished = true;
            }
          } catch (e) {
            debugPrint('Error al parsear fecha/hora: $e');
          }
        }

        // Verificar si todos los trabajadores del grupo están en workersFinished
        if (group.workers
            .every((workerId) => finishedWorkerIds.contains(workerId))) {
          isGroupFinished = true;
        }

        // Solo procesar grupos no finalizados y si el trabajador pertenece a este grupo
        if (!isGroupFinished &&
            group.workers.contains(worker.id) &&
            workersByGroup.containsKey(group.id)) {
          workersByGroup[group.id]!.add(worker);
          assignedToGroup = true;
          break; // Un trabajador solo puede estar en un grupo
        }
      }

      // Si el trabajador no está en ningún grupo ni está finalizado, añadirlo a los trabajadores sin grupo
      if (!assignedToGroup &&
          !groupedWorkerIds.contains(worker.id) &&
          !finishedWorkerIds.contains(worker.id)) {
        ungroupedWorkers.add(worker);
      }
    }

    List<Widget> sections = [];

    // Primero mostrar los grupos (solo los no finalizados)
    workersByGroup.forEach((groupId, workers) {
      if (workers.isEmpty)
        return; // Ignorar grupos sin trabajadores (todos finalizados)

      final group = groups.firstWhere(
        (g) => g.id == groupId,
        orElse: () => WorkerGroup(workers: [], name: "", id: ""),
      );

      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF38A169),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(7),
                  topRight: Radius.circular(7),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.group, color: Colors.white, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  NeumorphicButton(
                    style: NeumorphicStyle(
                      depth: 2,
                      intensity: 0.5,
                      color: Colors.white,
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(4)),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    onPressed: () {
                      showGroupCompletionDialog(context, assignment, workers,
                          groupId, assignmentsProvider, setState);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.done_all,
                            color: Color(0xFF38A169), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Completar grupo',
                          style: TextStyle(
                            color: Color(0xFF38A169),
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: groupColors[groupId]!,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ...workers
                      .map((worker) => _buildWorkerItemWithCompletion(
                          worker, assignment, assignmentsProvider,
                          isInGroup: true))
                      .toList(),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      );
    });

    // Luego mostrar los trabajadores sin grupo si existen (y no están finalizados)
    if (ungroupedWorkers.isNotEmpty) {
      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (workersByGroup
                .isNotEmpty) // Solo mostrar este título si hay grupos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                      child: Text(
                        'Trabajadores individuales',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                    ),
                  ),
                  // Botón para completar todos los trabajadores individuales
                  if (ungroupedWorkers.length > 1)
                    NeumorphicButton(
                      style: NeumorphicStyle(
                        depth: 2,
                        intensity: 0.5,
                        color: Colors.white,
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(4)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      onPressed: () {
                        _showCompleteAllIndividualsDialog(context, assignment,
                            ungroupedWorkers, assignmentsProvider);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.done_all,
                              color: Color(0xFF38A169), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Completar todos',
                            style: TextStyle(
                              color: Color(0xFF38A169),
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ...ungroupedWorkers
                .map((worker) => _buildWorkerItemWithCompletion(
                    worker, assignment, assignmentsProvider,
                    isInGroup: false))
                .toList(),
          ],
        ),
      );
    }

    return Column(children: sections);
  }

  Widget _buildWorkerItemWithCompletion(Worker worker, Assignment assignment,
      AssignmentsProvider assignmentsProvider,
      {bool isDeleted = false, bool isInGroup = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: isDeleted
            ? BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFE2E8F0)),
              ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isDeleted
                  ? Colors.grey
                  : Colors.primaries[
                      worker.name.hashCode % Colors.primaries.length],
              radius: 18,
              child: isDeleted
                  ? const Icon(Icons.person_off_outlined,
                      color: Colors.white, size: 16)
                  : Text(
                      worker.name.toString().substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          worker.name.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDeleted
                                ? Colors.red.shade700
                                : const Color(0xFF2D3748),
                            decoration:
                                isDeleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (isDeleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Eliminado',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (worker.area.isNotEmpty)
                    Text(
                      worker.area.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDeleted
                            ? Colors.red.shade300
                            : const Color(0xFF718096),
                      ),
                    ),
                ],
              ),
            ),
            // Solo mostrar el botón de completar para trabajadores individuales (no en grupo)
            if (!isDeleted && !isInGroup)
              NeumorphicButton(
                style: NeumorphicStyle(
                  depth: 1,
                  intensity: 0.5,
                  color: Colors.white,
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(4)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onPressed: () {
                  showIndividualCompletionDialog(
                      context, assignment, worker, assignmentsProvider);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: Color(0xFF38A169), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Completar',
                      style: TextStyle(
                        color: Color(0xFF38A169),
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
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

  void _showCompleteAllIndividualsDialog(
      BuildContext context,
      Assignment assignment,
      List<Worker> workers,
      AssignmentsProvider provider) {
    bool isProcessing = false;
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    // Formatear fecha y hora para mostrar
    String formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate);
    String formattedTime =
        "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text('Completar Todos los Trabajadores Individuales'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Se marcarán como completadas las tareas de ${workers.length} trabajador(es) individual(es).',
                      style: TextStyle(color: Color(0xFF718096)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Fecha de finalización',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: isProcessing
                          ? null
                          : () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate:
                                    DateTime.now().subtract(Duration(days: 30)),
                                lastDate: DateTime.now().add(Duration(days: 1)),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  selectedDate = picked;
                                  formattedDate = DateFormat('dd/MM/yyyy')
                                      .format(selectedDate);
                                });
                              }
                            },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 18, color: Color(0xFF718096)),
                            SizedBox(width: 8),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.arrow_drop_down,
                                color: Color(0xFF718096)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Hora de finalización',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: isProcessing
                          ? null
                          : () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  selectedTime = picked;
                                  formattedTime =
                                      "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                                });
                              }
                            },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 18, color: Color(0xFF718096)),
                            SizedBox(width: 8),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.arrow_drop_down,
                                color: Color(0xFF718096)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isProcessing ? null : () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isProcessing ? Color(0xFFCBD5E0) : Color(0xFF718096),
                  ),
                  child: Text('Cancelar'),
                ),
                NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: isProcessing ? 0 : 2,
                    intensity: 0.7,
                    color: isProcessing ? Color(0xFF9AE6B4) : Color(0xFF38A169),
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                  ),
                  onPressed: isProcessing
                      ? null
                      : () async {
                          setDialogState(() {
                            isProcessing = true;
                          });

                          try {
                            // Liberar a todos los trabajadores individuales
                            var workersProvider = Provider.of<WorkersProvider>(
                                context,
                                listen: false);

                            // Crear copia de la asignación con solo los trabajadores completados
                            Assignment completedAssignment = Assignment(
                              id: assignment.id,
                              workers: assignment.workers,
                              area: assignment.area,
                              task: assignment.task,
                              date: assignment.date,
                              time: assignment.time,
                              supervisor: assignment.supervisor,
                              status: assignment.status,
                              endDate: selectedDate,
                              endTime: formattedTime,
                              zone: assignment.zone,
                              motorship: assignment.motorship,
                              userId: assignment.userId,
                              areaId: assignment.areaId,
                              taskId: assignment.taskId,
                              clientId: assignment.clientId,
                              inChagers: assignment.inChagers,
                              groups: assignment.groups,
                            );

                            // Llamar a API para completar operación grupal
                            final success =
                                await provider.completeGroupOrIndividual(
                                    completedAssignment,
                                    workers,
                                    "individual", // Identificador para trabajadores individuales
                                    selectedDate,
                                    formattedTime,
                                    context);

                            // Liberar trabajadores
                            if (success) {
                              for (var worker in workers) {
                                await workersProvider.releaseWorkerObject(
                                    worker, context);
                              }
                              Navigator.of(dialogContext).pop();
                              Navigator.of(context).pop();

                              // Forzar actualización del estado global
                              setState(() {
                                // Vacío intencionalmente, solo para forzar rebuild
                              });

                              if (context.mounted) {
                                showSuccessToast(context,
                                    'Trabajadores individuales completados exitosamente');
                              }
                            } else {
                              setDialogState(() {
                                isProcessing = false;
                              });
                              if (context.mounted) {
                                showErrorToast(context,
                                    'No se pudo completar la operación');
                              }
                            }
                          } catch (e) {
                            debugPrint(
                                'Error al completar tareas individuales: $e');

                            if (context.mounted) {
                              setDialogState(() {
                                isProcessing = false;
                              });
                              showErrorToast(
                                  context, 'Error al completar las tareas: $e');
                            }
                          }
                        },
                  child: Container(
                    width: 100,
                    height: 36,
                    child: Center(
                      child: isProcessing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Procesando',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Completar todos',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailsSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
