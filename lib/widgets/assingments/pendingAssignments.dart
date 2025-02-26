import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
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
          final bool matchesWorker = assignment.workers.any((worker) =>
              worker['name']
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
              const Text(
                'Asignaciones Pendientes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 16),
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
        depth: 3,
        intensity: 0.7,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
      ),
      child: InkWell(
        onTap: () => _showAssignmentDetails(context, assignment),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6AD55).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PENDIENTE',
                  style: TextStyle(
                    color: Color(0xFFF6AD55),
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 8),

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
              const SizedBox(height: 6),

              // Area
              Text(
                assignment.area,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF718096),
                ),
              ),

              const Spacer(),
              const Divider(),

              // Date and workers
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(assignment.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Worker count
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${assignment.workers.length} trabajador${assignment.workers.length > 1 ? 'es' : ''}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  // Start button
                  InkWell(
                    onTap: () =>
                        _showStartDialog(context, assignment, provider),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3182CE).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 12,
                        color: Color(0xFF3182CE),
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
                          _buildDetailRow('Estado', 'Pendiente'),
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
                provider.updateAssignmentStatus(assignment.id, 'in_progress');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Asignación iniciada exitosamente'),
                    backgroundColor: Color(0xFF3182CE),
                  ),
                );
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

  Widget _buildWorkerItem(Map<String, dynamic> worker) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors
                .primaries[worker['name'].hashCode % Colors.primaries.length],
            radius: 18,
            child: Text(
              worker['name'].toString().substring(0, 1).toUpperCase(),
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
                  worker['name'].toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                if (worker.containsKey('specialty') &&
                    worker['specialty'] != null)
                  Text(
                    worker['specialty'].toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF718096),
                    ),
                  ),
              ],
            ),
          ),
          if (worker.containsKey('rating') && worker['rating'] != null)
            Row(
              children: [
                const Icon(
                  Icons.star,
                  size: 14,
                  color: Color(0xFFF6E05E),
                ),
                const SizedBox(width: 2),
                Text(
                  worker['rating'].toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
