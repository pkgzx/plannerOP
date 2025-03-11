import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/assingments/editAssignmentForm.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/widgets/assingments/emptyState.dart';
import 'package:plannerop/core/model/assignment.dart';

class PendingAssignmentsView extends StatelessWidget {
  final String searchQuery;

  const PendingAssignmentsView({Key? key, required this.searchQuery})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AssignmentsProvider>(
      builder: (context, assignmentsProvider, child) {
        if (assignmentsProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final pendingAssignments = assignmentsProvider.pendingAssignments;

        // Filtramos por búsqueda
        final filteredAssignments = pendingAssignments.where((assignment) {
          if (searchQuery.isEmpty) return true;

          // Buscar en área, tarea, o nombres de trabajadores
          final bool matchesArea =
              assignment.area.toLowerCase().contains(searchQuery.toLowerCase());
          final bool matchesTask =
              assignment.task.toLowerCase().contains(searchQuery.toLowerCase());
          final bool matchesWorker = assignment.workers.any((worker) => worker
              .name
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()));

          return matchesArea || matchesTask || matchesWorker;
        }).toList();

        if (filteredAssignments.isEmpty) {
          return EmptyState(
            message: pendingAssignments.isEmpty
                ? 'No hay asignaciones pendientes en este momento.'
                : 'No hay asignaciones pendientes que coincidan con la búsqueda.',
            showClearButton: searchQuery.isNotEmpty,
            onClear: () {
              // Esta función debería limpiar la búsqueda desde el padre
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Si tuviéramos una recarga desde API la llamaríamos aquí
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    final assignmentsProvider =
        Provider.of<AssignmentsProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
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
                  color: const Color(0xFFF6AD55).withOpacity(0.1),
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
                          color: Color(0xFFF6AD55),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          assignment.area,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFF6AD55),
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
                          _buildDetailRow('Fecha',
                              DateFormat('dd/MM/yyyy').format(assignment.date)),
                          _buildDetailRow('Hora', assignment.time),
                          _buildDetailRow('Estado', 'En vivo'),
                          if (assignment.endTime != null)
                            _buildDetailRow('Hora de finalización',
                                assignment.endTime ?? 'No especificada'),
                          if (assignment.endDate != null)
                            _buildDetailRow(
                                'Fecha de finalización',
                                DateFormat('dd/MM/yyyy')
                                    .format(assignment.endDate!)),
                          _buildDetailRow('Zona', 'Zona ${assignment.zone}'),
                          _buildDetailRow(
                              'Motonave', assignment.motorship ?? ''),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildDetailsSection(
                        title: 'Trabajadores asignados',
                        children: assignment.workers.map((worker) {
                          return _buildWorkerItem(worker);
                        }).toList(),
                      ),
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
                                        MediaQuery.of(context).size.width * 0.9,
                                    maxHeight:
                                        MediaQuery.of(context).size.height *
                                            0.9,
                                  ),
                                  child: EditAssignmentForm(
                                    assignment: assignment,
                                    onSave: (updatedAssignment) {
                                      assignmentsProvider.updateAssignment(
                                          updatedAssignment, context);
                                      showSuccessToast(
                                          context, 'Asignación actualizada');
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
                        );
                      }),
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

  void _showStartDialog(BuildContext context, Assignment assignment,
      AssignmentsProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Iniciar asignación'),
          content: const Text(
            '¿Estás seguro de que deseas iniciar esta asignación?',
            style: TextStyle(color: Color(0xFF718096)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            NeumorphicButton(
              style: NeumorphicStyle(
                depth: 2,
                intensity: 0.7,
                color: const Color(0xFF3182CE),
                boxShape:
                    NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
              ),
              onPressed: () {
                provider.updateAssignmentStatus(
                    assignment.id ?? 0, 'IN_PROGRESS', context);
                Navigator.pop(context);
                showSuccessToast(context, "Asignación iniciada");
              },
              child: const Text(
                'Confirmar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
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

  Widget _buildWorkerItem(Worker worker) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors
                .primaries[worker.name.hashCode % Colors.primaries.length],
            radius: 18,
            child: Text(
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
                Text(
                  worker.name.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                if (worker.area.isNotEmpty)
                  Text(
                    worker.area.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF718096),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
