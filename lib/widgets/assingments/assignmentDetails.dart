import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/utils/assignments.dart';
import 'package:provider/provider.dart';

class AssignmentDetailsBottomSheet extends StatelessWidget {
  final Assignment assignment;
  final Color accentColor;
  final String statusText;
  final Function(BuildContext, Assignment, AssignmentsProvider)? primaryAction;
  final String primaryActionText;
  final Color primaryActionColor;
  final bool showEditButton;

  const AssignmentDetailsBottomSheet({
    Key? key,
    required this.assignment,
    required this.accentColor,
    required this.statusText,
    this.primaryAction,
    required this.primaryActionText,
    required this.primaryActionColor,
    this.showEditButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final areas_provider = Provider.of<AreasProvider>(context, listen: false);

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
              color: accentColor.withOpacity(0.1),
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
                    Icon(
                      Icons.room_outlined,
                      size: 16,
                      color: accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      areas_provider.getAreaById(assignment.areaId)?.name ??
                          assignment.area,
                      style: TextStyle(
                        fontSize: 14,
                        color: accentColor,
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
                  buildDetailsSection(
                    title: 'Detalles de la asignación',
                    children: [
                      buildDetailRow('Fecha',
                          DateFormat('dd/MM/yyyy').format(assignment.date)),
                      buildDetailRow('Hora', assignment.time),
                      buildDetailRow('Estado', statusText),
                      if (assignment.endTime != null &&
                          assignment.endTime!.isNotEmpty)
                        buildDetailRow(
                            'Hora de finalización', assignment.endTime!),
                      if (assignment.endDate != null)
                        buildDetailRow(
                            'Fecha de finalización',
                            DateFormat('dd/MM/yyyy')
                                .format(assignment.endDate!)),
                      buildDetailRow('Zona', 'Zona ${assignment.zone}'),
                      if (assignment.motorship != null &&
                          assignment.motorship!.isNotEmpty)
                        buildDetailRow('Motonave', assignment.motorship!),
                    ],
                  ),
                  const SizedBox(height: 20),
                  buildDetailsSection(
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
                if (showEditButton)
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
                        // Aquí se podría implementar la edición
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
                if (showEditButton) const SizedBox(width: 12),
                Expanded(
                  child: Consumer<AssignmentsProvider>(
                    builder: (context, provider, child) {
                      return NeumorphicButton(
                        style: NeumorphicStyle(
                          depth: 2,
                          intensity: 0.7,
                          color: primaryActionColor,
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(8)),
                        ),
                        onPressed: primaryAction != null
                            ? () {
                                Navigator.pop(context);
                                primaryAction!(context, assignment, provider);
                              }
                            : null,
                        child: Text(
                          primaryActionText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

// Función para mostrar el detalle de asignación como un modal
void showAssignmentDetails(
  BuildContext context,
  Assignment assignment, {
  Color accentColor = const Color(0xFF3182CE),
  String statusText = 'Pendiente',
  Function(BuildContext, Assignment, AssignmentsProvider)? primaryAction,
  String primaryActionText = 'Acción',
  Color primaryActionColor = const Color(0xFF3182CE),
  bool showEditButton = true,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AssignmentDetailsBottomSheet(
      assignment: assignment,
      accentColor: accentColor,
      statusText: statusText,
      primaryAction: primaryAction,
      primaryActionText: primaryActionText,
      primaryActionColor: primaryActionColor,
      showEditButton: showEditButton,
    ),
  );
}
