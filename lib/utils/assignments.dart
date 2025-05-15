import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/assingments/components/buildWorkerItem.dart';
import 'package:plannerop/widgets/assingments/components/utils.dart';
import 'package:provider/provider.dart';

/// Shows assignment details in a modal bottom sheet
void showAssignmentDetails({
  required BuildContext context,
  required Assignment assignment,
  // Appearance customization
  Color statusColor = const Color(0xFF3182CE),
  String statusText = 'Pendiente',
  // Content builders
  List<Widget> Function(Assignment)? detailsBuilder,
  Widget Function(Assignment, BuildContext)? workersBuilder,
  // Actions
  List<Widget> Function(BuildContext, Assignment)? actionsBuilder,
  Widget Function(BuildContext, Assignment)? floatingActionBuilder,
  // Event handlers
  VoidCallback? onClose,
}) {
  // Get in-charge users
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

  // Default details builder if none provided
  List<Widget> buildDefaultDetails(Assignment assignment) {
    return [
      buildDetailRow('Fecha', DateFormat('dd/MM/yyyy').format(assignment.date)),
      buildDetailRow('Hora', assignment.time),
      buildDetailRow('Estado', statusText),
      if (assignment.endTime != null)
        buildDetailRow(
            'Hora de finalización', assignment.endTime ?? 'No especificada'),
      if (assignment.endDate != null)
        buildDetailRow('Fecha de finalización',
            DateFormat('dd/MM/yyyy').format(assignment.endDate!)),
      buildDetailRow('Zona', 'Zona ${assignment.zone}'),
      if (assignment.motorship != null && assignment.motorship!.isNotEmpty)
        buildDetailRow('Motonave', assignment.motorship!),
    ];
  }

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
                    color: statusColor.withOpacity(0.1),
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
                            onPressed: () {
                              Navigator.pop(context);
                              if (onClose != null) onClose();
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.room_outlined,
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            assignment.area,
                            style: TextStyle(
                              fontSize: 14,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
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
                        // Assignment details
                        buildDetailSection(
                          title: 'Detalles de la operación',
                          children: detailsBuilder != null
                              ? detailsBuilder(assignment)
                              : buildDefaultDetails(assignment),
                        ),
                        const SizedBox(height: 20),

                        // Workers section
                        if (workersBuilder != null) ...[
                          workersBuilder(assignment, context),
                          const SizedBox(height: 20),
                        ] else if (assignment.workers.isNotEmpty) ...[
                          buildDetailSection(
                            title: 'Trabajadores asignados',
                            children: assignment.workers
                                .map((worker) =>
                                    buildWorkerItem(worker, context))
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // In-charges section
                        if (inChargersFormat.isNotEmpty) ...[
                          buildDetailSection(
                            title: 'Encargados de la operación',
                            children: inChargersFormat
                                .map((charger) => buildInChargerItem(charger))
                                .toList(),
                          ),
                          const SizedBox(height: 60),
                        ],
                      ],
                    ),
                  ),
                ),

                // Action buttons
                if (actionsBuilder != null)
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
                      children: actionsBuilder(context, assignment),
                    ),
                  ),
              ],
            ),
          ),

          // Floating action button (e.g. cancel button)
          if (floatingActionBuilder != null)
            Positioned(
              right: 20,
              bottom: 90,
              child: floatingActionBuilder(context, assignment),
            ),
        ],
      );
    },
  );
}

Widget buildDetailSection(
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

Widget buildDetailRow(String label, String value) {
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

Color getStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return Colors.orange;
    case 'INPROGRESS':
      return Colors.blue;
    case 'COMPLETED':
      return Colors.green;
    case 'CANCELLED':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

// Método para mostrar el diálogo de cancelación (agregarlo si no existe)
void showCancelDialog(
    BuildContext context, Assignment assignment, AssignmentsProvider provider) {
  bool isProcessing = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          debugPrint('Cancelando asignación ${assignment.id}');

                          // Aquí iría la llamada a la API para cancelar
                          final success = await provider.updateAssignmentStatus(
                              assignment.id ?? 0, 'CANCELED', context);

                          final workersProvider = Provider.of<WorkersProvider>(
                              context,
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
