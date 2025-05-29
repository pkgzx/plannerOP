import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/store/feedings.dart';
import 'package:plannerop/utils/operations.dart' hide buildDetailRow;
import 'package:plannerop/utils/feedingUtils.dart';
import 'package:plannerop/utils/groups/groups.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/operations/components/OperationCard.dart';
import 'package:plannerop/widgets/operations/components/workers/buildWorkerItem.dart';
import 'package:plannerop/widgets/operations/update/editOperationForm.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/operations.dart';
import 'package:plannerop/widgets/operations/components/utils/emptyState.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/widgets/operations/components/completeDialogs.dart';
import 'package:plannerop/widgets/operations/components/utils.dart';

class ActiveOperationsView extends StatefulWidget {
  final String searchQuery;

  const ActiveOperationsView({Key? key, required this.searchQuery})
      : super(key: key);

  @override
  _ActiveOperationsViewState createState() => _ActiveOperationsViewState();
}

class _ActiveOperationsViewState extends State<ActiveOperationsView> {
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

    return Consumer<OperationsProvider>(
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
            await assignmentsProvider.refreshActiveAssignments(context);
          },
          child: Column(
            children: [
              buildFilterBar(
                areas,
                supervisors,
                _showFilters,
                _selectedArea,
                _selectedSupervisorId,
                context,
                setState,
                onAreaChanged: (String? area) {
                  setState(() {
                    _selectedArea = area;
                  });
                },
                onSupervisorChanged: (int? supervisorId) {
                  setState(() {
                    _selectedSupervisorId = supervisorId;
                  });
                },
                onClearFilters: () {
                  setState(() {
                    _selectedArea = null;
                    _selectedSupervisorId = null;
                  });
                },
                onToggleFilters: () {
                  // AGREGAR ESTE CALLBACK
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
              ),
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

  Widget _buildEmptyState(List<Operation> activeAssignments) {
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

  Widget _buildAssignmentGrid(List<Operation> assignments) {
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

                return OperationCard(
                  assignment: assignment,
                  onTap: _showAssignmentDetails,
                  statusColor: const Color(0xFF38A169), // Verde para activas
                  statusText: 'EN CURSO',
                  showFoodInfo: true, // Mostrar información de alimentación
                );
              },
            );
          },
        ),
      ],
    );
  }

  List<Operation> _applyFilters(List<Operation> assignments) {
    return assignments.where((assignment) {
      // Filtrar por texto de búsqueda
      bool matchesSearch = true;
      // if (widget.searchQuery.isNotEmpty) {
      //   final matchesTask = assignment.task
      //       .toLowerCase()
      //       .contains(widget.searchQuery.toLowerCase());
      //   final matchesWorker = assignment.workers.any((worker) => worker.name
      //       .toString()
      //       .toLowerCase()
      //       .contains(widget.searchQuery.toLowerCase()));
      //   matchesSearch = matchesTask || matchesWorker;
      // }

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

  void _showAssignmentDetails(BuildContext context, Operation assignment) {
    final assignmentsProvider =
        Provider.of<OperationsProvider>(context, listen: false);
    final feedingProvider =
        Provider.of<FeedingProvider>(context, listen: false);

    // Cargar datos de alimentación para esta operación
    feedingProvider.loadFeedingStatusForOperation(assignment.id ?? 0, context);

    List<String> foods = FeedingUtils.determinateFoodsWithDeliveryStatus(
        assignment.time, assignment.endTime, context);

    bool tieneDerechoAlimentacion = foods.isNotEmpty;

    // Usar la función unificada showOperationDetails
    showOperationDetails(
      context: context,
      assignment: assignment,
      statusColor: const Color(0xFF38A169),
      statusText: 'EN CURSO',

      // Configuración específica para grupos activos
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
      setState: () => setState(() {}),

      // Workers builder para trabajadores eliminados
      workersBuilder: (assignment, context) {
        return assignment.deletedWorkers.isNotEmpty
            ? _buildDeletedWorkersSection(assignment)
            : const SizedBox();
      },

      // Action buttons
      actionsBuilder: (context, assignment) => [
        Expanded(
          child: NeumorphicButton(
            style: NeumorphicStyle(
              depth: 2,
              intensity: 0.7,
              color: Colors.white,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showEditDialog(context, assignment, assignmentsProvider);
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
          child:
              Consumer<OperationsProvider>(builder: (context, provider, child) {
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

      // Floating action button (cancelar)
      floatingActionBuilder: (context, assignment) => NeumorphicButton(
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
          showCancelDialog(context, assignment, assignmentsProvider);
        },
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildDeletedWorkersSection(Operation assignment) {
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

  void _showEditDialog(
      BuildContext context, Operation assignment, OperationsProvider provider) {
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
            child: EditOperationForm(
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
