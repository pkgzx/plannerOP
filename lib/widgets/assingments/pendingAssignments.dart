import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/assignments.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/assingments/components/utils.dart';
import 'package:plannerop/widgets/assingments/editAssignmentForm.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/widgets/assingments/emptyState.dart';
import 'package:plannerop/core/model/assignment.dart';

class PendingAssignmentsView extends StatefulWidget {
  final String searchQuery;

  const PendingAssignmentsView({Key? key, required this.searchQuery})
      : super(key: key);

  @override
  _PendingAssignmentsViewState createState() => _PendingAssignmentsViewState();
}

class _PendingAssignmentsViewState extends State<PendingAssignmentsView> {
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

        final pendingAssignments = assignmentsProvider.pendingAssignments;

        // Aplicar filtros
        var filteredAssignments = pendingAssignments.where((assignment) {
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              buildFilterBar(areas, supervisors, _showFilters, _selectedArea,
                  _selectedSupervisorId, context, setState),
              filteredAssignments.isEmpty
                  ? EmptyState(
                      message: pendingAssignments.isEmpty
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
                  : GridView.builder(
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
        );
      },
    );
  }

  Widget _buildAssignmentCard(BuildContext context, Assignment assignment,
      AssignmentsProvider provider) {
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
          padding: const EdgeInsets.fromLTRB(
              16, 16, 16, 8), // Reducir padding inferior
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: const Color(0xFFF6AD55),
                width: 4,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4), // Reducir padding vertical
                decoration: BoxDecoration(
                  color: const Color(0xFFF6AD55).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF6AD55),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'PENDIENTE',
                      style: TextStyle(
                        color: Color(0xFFF6AD55),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8), // Reducir espacio

              // Task name
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
              const SizedBox(height: 4), // Reducir espacio

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
                      assignment.area,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13, // Reducir tamaño de fuente
                        color: Color(0xFF718096),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Separator más compacto
              Container(
                height: 1,
                color: const Color(0xFFEDF2F7),
                margin:
                    const EdgeInsets.symmetric(vertical: 6), // Reducir margen
              ),

              // Date de manera más compacta
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Alinear entre extremos
                children: [
                  // Fecha
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 10, // Más pequeño
                        color: const Color(0xFF718096).withOpacity(0.8),
                      ),
                      const SizedBox(width: 3), // Menos espacio
                      Text(
                        DateFormat('dd/MM/yy')
                            .format(assignment.date), // Formato abreviado
                        style: TextStyle(
                          fontSize: 10, // Más pequeño
                          color: const Color(0xFF718096).withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Worker count
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 10, // Más pequeño
                        color: const Color(0xFF718096).withOpacity(0.8),
                      ),
                      const SizedBox(width: 3), // Menos espacio
                      Text(
                        "${assignment.workers.length}",
                        style: TextStyle(
                          fontSize: 10, // Más pequeño
                          color: const Color(0xFF718096).withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Start button - Reducido aún más
                  Container(
                    height: 24, // Altura fija
                    width: 24, // Ancho fijo para hacerlo circular
                    decoration: BoxDecoration(
                      color: const Color(0xFF3182CE),
                      shape: BoxShape.circle, // Forma circular
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3182CE).withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            _showStartDialog(context, assignment, provider),
                        customBorder: const CircleBorder(),
                        child: const Icon(
                          Icons.play_arrow_rounded,
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
    final provider = Provider.of<AssignmentsProvider>(context, listen: false);

    showAssignmentDetails(
      context: context,
      assignment: assignment,
      statusColor: const Color(0xFFF6AD55),
      statusText: "Pendiente",
      workersBuilder: (assignment, context) =>
          buildWorkersSection(assignment, context, setState: setState),
      actionsBuilder: (context, assignment) => [
        // Edit button
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
              // Show edit dialog
              showEditAssignmentForm(context, assignment);
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
        // Start button
        Expanded(
          child: NeumorphicButton(
            style: NeumorphicStyle(
              depth: 2,
              intensity: 0.7,
              color: const Color(0xFF3182CE),
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showStartDialog(context, assignment, provider);
            },
            child: const Text(
              'Iniciar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
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
          _showCancelDialog(context, assignment, provider);
        },
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  void _showStartDialog(BuildContext context, Assignment assignment,
      AssignmentsProvider provider) {
    // Variable de estado local para el diálogo
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Evitar cierre al tocar fuera del diálogo
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(// Usar StatefulBuilder para manejar estado local
            builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Iniciar asignación'),
            content: const Text(
              '¿Estás seguro de que deseas iniciar esta asignación?',
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
                          0xFF90CDF4) // Color más claro cuando está procesando
                      : const Color(0xFF3182CE),
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                ),
                onPressed: isProcessing
                    ? null
                    : () async {
                        // Actualizar estado del diálogo a "procesando"
                        setDialogState(() {
                          isProcessing = true;
                        });

                        try {
                          debugPrint('Iniciando asignación ${assignment.id}');

                          // Actualizar el estado de la asignación
                          await provider.updateAssignmentStatus(
                              assignment.id ?? 0, 'INPROGRESS', context);

                          // Cerrar el diálogo
                          Navigator.pop(dialogContext);

                          // Mostrar mensaje de éxito
                          showSuccessToast(context, "Asignación iniciada");
                        } catch (e) {
                          // En caso de error, volver a habilitar el botón
                          if (context.mounted) {
                            setDialogState(() {
                              isProcessing = false;
                            });
                            showErrorToast(
                                context, "Error al iniciar la asignación");
                          }
                        }
                      },
                child: Container(
                  width: 100, // Ancho fijo para evitar redimensionamiento
                  height: 36,
                  child: Center(
                    child: isProcessing
                        ? Row(
                            // Mostrar indicador de carga
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
                                'Iniciando',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Confirmar',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          );
        });
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
}
