import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/store/feedings.dart';
import 'package:plannerop/utils/assignments.dart' hide buildDetailRow;
import 'package:plannerop/utils/foodUtils.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/assingments/components/assigmentCard.dart';
import 'package:plannerop/widgets/assingments/components/buildWorkerItem.dart';
import 'package:plannerop/widgets/assingments/editAssignmentForm.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/widgets/assingments/emptyState.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/widgets/assingments/components/showCompletionDialog.dart';
import 'package:plannerop/widgets/assingments/components/utils.dart';

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
  Map<int, bool> alimentacionStatus = {};

  @override
  Widget build(BuildContext context) {
    // Obtener áreas disponibles del provider
    final areasProvider = Provider.of<AreasProvider>(context);
    final areas = areasProvider.areas.map((area) => area.name).toSet().toList();

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
        var filteredAssignments = _applyFilters(activeAssignments);

        return RefreshIndicator(
          onRefresh: () async {
            // Si tuviéramos una recarga desde API la llamaríamos aquí
            await assignmentsProvider.refreshActiveAssignments(context);
          },
          child: Column(
            children: [
              buildFilterBar(areas, supervisors, _showFilters, _selectedArea,
                  _selectedSupervisorId, context, setState),
              Expanded(
                child: filteredAssignments.isEmpty
                    ? _buildEmptyState(activeAssignments)
                    : _buildAssignmentGrid(filteredAssignments),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(List<Assignment> activeAssignments) {
    return EmptyState(
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
    );
  }

  Widget _buildAssignmentGrid(List<Assignment> assignments) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Consumer<FeedingProvider>(
          builder: (context, feedingProvider, _) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                return AssignmentCard(
                  assignment: assignment,
                  onTap: _showAssignmentDetails,
                );
              },
            );
          },
        ),
      ],
    );
  }

  List<Assignment> _applyFilters(List<Assignment> assignments) {
    return assignments.where((assignment) {
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
  }

  void _showAssignmentDetails(BuildContext context, Assignment assignment) {
    final assignmentsProvider =
        Provider.of<AssignmentsProvider>(context, listen: false);
    final feedingProvider =
        Provider.of<FeedingProvider>(context, listen: false);

    // Cargar datos de alimentación para esta operación
    feedingProvider.loadFeedingStatusForOperation(assignment.id ?? 0, context);

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

    List<String> foods =
        FoodUtils.determinateFoods(assignment.time, assignment.endTime);
    bool tieneDerechoAlimentacion = foods.isNotEmpty;

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
                  _buildDetailHeader(assignment, context),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailsSection(
                            title: 'Detalles de la asignación',
                            children: _buildAssignmentDetails(assignment),
                          ),
                          const SizedBox(height: 20),
                          buildWorkersSection(
                            assignment,
                            context,
                            setState: setState,
                            alimentacionStatus: alimentacionStatus,
                            foods: foods,
                            onAlimentacionChanged: tieneDerechoAlimentacion
                                ? (workerId, entregada) {
                                    if (foods.isNotEmpty) {
                                      feedingProvider.markFeeding(
                                        operationId: assignment.id ?? 0,
                                        workerId: workerId,
                                        foodType: foods[0],
                                        context: context,
                                      );
                                    }
                                  }
                                : null,
                          ),
                          _buildDeletedWorkersSection(assignment),
                          const SizedBox(height: 20),
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
                  _buildActionButtons(context, assignment, assignmentsProvider),
                ],
              ),
            ),

            // Botón flotante de cancelar
            Positioned(
              right: 20,
              bottom: 90,
              child:
                  _buildCancelButton(context, assignment, assignmentsProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailHeader(Assignment assignment, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 13, 184, 84).withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
    );
  }

  List<Widget> _buildAssignmentDetails(Assignment assignment) {
    return [
      buildDetailRow('Fecha', DateFormat('dd/MM/yyyy').format(assignment.date)),
      buildDetailRow('Hora', assignment.time),
      buildDetailRow('Estado', 'En curso'),
      if (assignment.endTime != null)
        buildDetailRow(
            'Hora de finalización', assignment.endTime ?? 'No especificada'),
      if (assignment.endDate != null)
        buildDetailRow('Fecha de finalización',
            DateFormat('dd/MM/yyyy').format(assignment.endDate!)),
      buildDetailRow('Zona', 'Zona ${assignment.zone}'),
      if (assignment.motorship != "" && assignment.motorship != null)
        buildDetailRow('Motonave', assignment.motorship ?? ''),
    ];
  }

  Widget _buildDeletedWorkersSection(Assignment assignment) {
    return assignment.deletedWorkers.map(
      (worker) {
        bool entregada = alimentacionStatus[worker.id] ?? false;
        return buildWorkerItem(worker, context,
            alimentacionEntregada: entregada,
            onAlimentacionChanged: (newValue) {
          setState(() {
            alimentacionStatus[worker.id] = newValue;
          });
        });
      },
    ).isNotEmpty
        ? _buildDetailsSection(
            title: 'Trabajadores eliminados',
            children: assignment.deletedWorkers.map(
              (worker) {
                return buildWorkerItem(worker, context, isDeleted: true);
              },
            ).toList(),
          )
        : const SizedBox();
  }

  Widget _buildActionButtons(BuildContext context, Assignment assignment,
      AssignmentsProvider provider) {
    return Container(
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
                boxShape:
                    NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _showEditDialog(context, assignment, provider);
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
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
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
    );
  }

  Widget _buildCancelButton(BuildContext context, Assignment assignment,
      AssignmentsProvider provider) {
    return NeumorphicButton(
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
        showCancelDialog(context, assignment, provider);
      },
      child: const Icon(
        Icons.delete_outline,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  void _showEditDialog(BuildContext context, Assignment assignment,
      AssignmentsProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: EditAssignmentForm(
              assignment: assignment,
              onSave: (updatedAssignment) {
                provider.updateAssignment(updatedAssignment, context);
                showSuccessToast(context, 'Asignación actualizada');
                Navigator.pop(context);
              },
              onCancel: () => Navigator.pop(context),
            ),
          ),
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
