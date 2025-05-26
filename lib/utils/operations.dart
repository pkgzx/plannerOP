import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/store/clients.dart';
import 'package:plannerop/store/task.dart';
import 'package:plannerop/utils/group.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/operations/components/utils.dart';
import 'package:provider/provider.dart';

/// Shows assignment details in a modal bottom sheet
void showOperationDetails({
  required BuildContext context,
  required Operation assignment,
  // Appearance customization
  Color statusColor = const Color(0xFF3182CE),
  String statusText = 'Pendiente',
  // Content builders
  List<Widget> Function(Operation)? detailsBuilder,
  Widget Function(Operation, BuildContext)? workersBuilder,
  // Actions
  List<Widget> Function(BuildContext, Operation)? actionsBuilder,
  Widget Function(BuildContext, Operation)? floatingActionBuilder,
  // Event handlers
  VoidCallback? onClose,
}) {
  debugPrint("Groups: ${assignment.groups}");
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
  List<Widget> buildDefaultDetails(Operation assignment) {
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
                        ],
                        buildGroupsSection(
                          context,
                          assignment.groups,
                          'Grupos de trabajo',
                        ),

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

/// Funcion que construye un item de la card
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
    BuildContext context, Operation assignment, AssignmentsProvider provider) {
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
            title: const Text('Cancelar operación'),
            content: const Text(
              '¿Estás seguro de que deseas cancelar esta operación?',
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
                          debugPrint('Cancelando operación ${assignment.id}');

                          // Aquí iría la llamada a la API para cancelar
                          final success = await provider.updateAssignmentStatus(
                              assignment.id ?? 0, 'CANCELED', context);

                          // final workersProvider = Provider.of<WorkersProvider>(
                          //     context,
                          //     listen: false);
                          // for (var worker in assignment.workers) {
                          //   workersProvider.releaseWorkerObject(
                          //       worker, context);
                          // }

                          Navigator.pop(dialogContext);
                          showSuccessToast(
                              context, 'Asignación cancelada exitosamente');
                        } catch (e) {
                          debugPrint('Error al cancelar operación: $e');

                          if (context.mounted) {
                            setDialogState(() {
                              isProcessing = false;
                            });
                            showErrorToast(
                                context, 'Error al cancelar operación: $e');
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

// método para crear campos no editables con el mismo estilo que los editables
Widget buildNonEditableField({
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

List<Widget> getServicesGroups(BuildContext context, List<WorkerGroup> groups) {
  List<Widget> serviceWidgets = [];
  for (var group in groups) {
    serviceWidgets.add(getServiceGroup(context, group));
  }
  return serviceWidgets;
}

Widget getServiceGroup(BuildContext context, WorkerGroup group) {
  final serviceProvider = Provider.of<TasksProvider>(context, listen: false);
  final service = serviceProvider.getTaskNameByIdService(group.serviceId);

  return Row(
    children: [
      Icon(
        Icons.design_services,
        size: 12,
        color: const Color(0xFF3182CE),
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          service,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
      ),
    ],
  );
}

// Obtener el nombre del cliente usando el ID
Future<String?> getClientName(BuildContext context, int clientId) async {
  final clientsProvider = Provider.of<ClientsProvider>(context, listen: false);
  final client = clientsProvider.getClientById(clientId);

  return client.name;
}

// Método auxiliar para obtener el nombre del servicio
String getServiceName(BuildContext context, int serviceId) {
  try {
    final serviceProvider = Provider.of<TasksProvider>(context, listen: false);
    return serviceProvider.getTaskNameByIdService(serviceId);
  } catch (e) {
    return 'Servicio desconocido';
  }
}

// Helper para obtener el ícono según el estado
IconData getStatusIcon(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return Icons.pending_outlined;
    case 'INPROGRESS':
      return Icons.sync;
    case 'COMPLETED':
      return Icons.check_circle_outline;
    case 'CANCELED':
      return Icons.cancel_outlined;
    default:
      return Icons.pending_outlined;
  }
}
