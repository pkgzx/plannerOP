import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/store/user.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/assingments/editAssignmentForm.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/widgets/assingments/emptyState.dart';
import 'package:plannerop/core/model/assignment.dart';

// Actualizar ActiveAssignmentsView para mostrar indicador sutil de actualización
class ActiveAssignmentsView extends StatefulWidget {
  final String searchQuery;

  const ActiveAssignmentsView({Key? key, required this.searchQuery})
      : super(key: key);

  @override
  _ActiveAssignmentsViewState createState() => _ActiveAssignmentsViewState();
}

class _ActiveAssignmentsViewState extends State<ActiveAssignmentsView> {
  bool _isRefreshing = false;
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
                        onTap: () => _showCompletionDialog(
                            context, assignment, provider),
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

  // Método para mostrar trabajadores agrupados
  Widget _buildWorkersSection(Assignment assignment) {
    // Obtener los grupos de la asignación
    final groups = assignment.groups;

    // Agrupar los workers por su grupo
    Map<String, List<Worker>> workersByGroup = {};
    List<Worker> ungroupedWorkers = [];

    // Conjunto para seguir los IDs de trabajadores que ya están en grupos
    Set<int> groupedWorkerIds = {};

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
      for (var workerId in group.workers) {
        groupedWorkerIds.add(workerId);
      }
    }

    // Segundo: clasificar trabajadores en sus grupos correspondientes
    for (var worker in assignment.workers) {
      bool assignedToGroup = false;

      // Buscar en qué grupo está este trabajador
      for (var group in groups) {
        if (group.workers.contains(worker.id)) {
          // Inicializar la lista del grupo si es necesario
          if (!workersByGroup.containsKey(group.id)) {
            workersByGroup[group.id] = [];
            groupColors[group.id] =
                groupColorOptions[colorIndex % groupColorOptions.length];
            colorIndex++;
          }

          // Añadir el trabajador a su grupo
          workersByGroup[group.id]!.add(worker);
          assignedToGroup = true;
          break;
        }
      }

      // Si el trabajador no está en ningún grupo, añadirlo a los trabajadores sin grupo
      if (!assignedToGroup && !groupedWorkerIds.contains(worker.id)) {
        ungroupedWorkers.add(worker);
      }
    }

    List<Widget> sections = [];

    // Primero mostrar los grupos
    workersByGroup.forEach((groupId, workers) {
      final group = groups.firstWhere(
        (g) => g.id == groupId,
        orElse: () => WorkerGroup(workers: [], name: "", id: ""),
      );

      sections.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: groupColors[groupId],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado del grupo
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF38A169),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(7),
                    topRight: Radius.circular(7),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.white, size: 14),
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
                  ],
                ),
              ),

              // Lista de trabajadores en este grupo
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: workers
                      .map((worker) => _buildWorkerItem(worker))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      );
    });

    // Luego mostrar los trabajadores sin grupo si existen
    if (ungroupedWorkers.isNotEmpty) {
      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (workersByGroup
                .isNotEmpty) // Solo mostrar este título si hay grupos
              Padding(
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
            ...ungroupedWorkers
                .map((worker) => _buildWorkerItem(worker))
                .toList(),
          ],
        ),
      );
    }

    return Column(children: sections);
  }

  // Modificar la sección de _showAssignmentDetails para incluir un FloatingActionButton para cancelar
  void _showAssignmentDetails(BuildContext context, Assignment assignment) {
    final areas_provider = Provider.of<AreasProvider>(context, listen: false);
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
            // Contenido principal del modal
            Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (sin cambios)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3182CE).withOpacity(0.1),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primera fila: título y botón cerrar
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // IconButton(
                            //   icon: const Icon(Icons.close),
                            //   onPressed: () => Navigator.pop(context),
                            // ),
                          ],
                        ),

                        // Segunda fila: Área y estado
                        Row(
                          children: [
                            const Icon(
                              Icons.room_outlined,
                              size: 16,
                              color: Color(0xFF3182CE),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              areas_provider
                                      .getAreaById(assignment.areaId)
                                      ?.name ??
                                  "",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF3182CE),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content (sin cambios)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailsSection(
                            title: 'Detalles de la operación',
                            children: [
                              _buildDetailRow(
                                  'Fecha',
                                  DateFormat('dd/MM/yyyy')
                                      .format(assignment.date)),
                              _buildDetailRow('Hora', assignment.time),
                              _buildDetailRow('Estado', 'En curso'),
                              if (assignment.endTime != null)
                                _buildDetailRow('Hora de finalización',
                                    assignment.endTime ?? 'No especificada'),
                              if (assignment.endDate != null)
                                _buildDetailRow(
                                    'Fecha de finalización',
                                    DateFormat('dd/MM/yyyy')
                                        .format(assignment.endDate!)),
                              _buildDetailRow('Zona',
                                  ' ${assignment.zone == 0 ? 'N/A' : 'Zona ' + assignment.zone.toString()}'),
                              _buildDetailRow(
                                  'Motonave', assignment.motorship ?? ''),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildWorkersSection(assignment),

                          const SizedBox(height: 20),
                          assignment.deletedWorkers.map(
                            (worker) {
                              return _buildWorkerItem(worker);
                            },
                          ).isNotEmpty
                              ? _buildDetailsSection(
                                  title: 'Trabajadores eliminados',
                                  children: assignment.deletedWorkers.map(
                                    (worker) {
                                      return _buildWorkerItem(worker,
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
                              return _buildInChargerItem(charger);
                            }).toList(),
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),

                  // Action buttons (mantener los botones principales)
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
                              // Código de edición existente

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
                                color: const Color(0xFF38A169),
                                boxShape: NeumorphicBoxShape.roundRect(
                                    BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _showCompletionDialog(
                                    context, assignment, provider);
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
  // Reemplaza el método _showCompletionDialog actual con este:

  void _showCompletionDialog(BuildContext context, Assignment assignment,
      AssignmentsProvider provider) {
    // Variable para controlar el estado de procesamiento
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Evita cierres accidentales
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Completar asignación'),
              content: const Text(
                '¿Estás seguro de que deseas marcar esta asignación como completada?',
                style: TextStyle(color: Color(0xFF718096)),
              ),
              actions: [
                // Botón Cancelar (deshabilitado durante el procesamiento)
                TextButton(
                  onPressed:
                      isProcessing ? null : () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    foregroundColor: isProcessing
                        ? const Color(0xFFCBD5E0)
                        : const Color(0xFF718096),
                  ),
                  child: const Text('Cancelar'),
                ),
                // Botón Confirmar con estado de carga
                NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: isProcessing ? 0 : 2,
                    intensity: 0.7,
                    color: isProcessing
                        ? const Color(
                            0xFF9AE6B4) // Color más claro cuando está procesando
                        : const Color(0xFF38A169),
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                  ),
                  onPressed: isProcessing
                      ? null
                      : () async {
                          // Actualizar estado a "procesando"
                          setDialogState(() {
                            isProcessing = true;
                          });

                          try {
                            // Obtener fecha y hora actuales
                            final now = DateTime.now();
                            final currentTime = DateFormat('HH:mm').format(now);

                            debugPrint(
                                'Completando asignación ${assignment.id}');

                            var endTimeToSave =
                                assignment.endTime?.isNotEmpty == true
                                    ? assignment.endTime
                                    : currentTime;

                            endTimeToSave ??= currentTime;

                            // Actualizar la asignación en el servidor con todos los datos modificados
                            final success = await provider.completeAssignment(
                                assignment.id ?? 0,
                                assignment.endDate ?? now,
                                endTimeToSave,
                                context);

                            if (success) {
                              // Liberar a los trabajadores
                              final workersProvider =
                                  Provider.of<WorkersProvider>(context,
                                      listen: false);
                              for (var worker in assignment.workers) {
                                workersProvider.releaseWorkerObject(
                                    worker, context);
                              }

                              Navigator.pop(dialogContext);
                              showSuccessToast(
                                  context, 'Operación completada exitosamente');
                            } else {
                              // En caso de error, restaurar el estado del botón
                              setDialogState(() {
                                isProcessing = false;
                              });
                              showErrorToast(context,
                                  'Error al completar la asignación: ${provider.error ?? "Desconocido"}');
                            }
                          } catch (e) {
                            debugPrint('Error al completar asignación: $e');

                            // Restaurar estado del botón en caso de error
                            if (context.mounted) {
                              setDialogState(() {
                                isProcessing = false;
                              });
                              showErrorToast(
                                  context, 'Error al completar asignación: $e');
                            }
                          }
                        },
                  child: Container(
                    width: 100, // Ancho fijo para evitar saltos de diseño
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
                              'Confirmar',
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5568),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildWorkerItem(Worker worker, {bool isDeleted = false}) {
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
            : null,
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
          ],
        ),
      ),
    );
  }

  Widget _buildInChargerItem(User charger) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade100),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.shade400,
              radius: 18,
              child: Text(
                charger.name.toString().substring(0, 1).toUpperCase(),
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
                          charger.name.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (charger.cargo.isNotEmpty)
                    Text(
                      charger.cargo.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF718096),
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
}
