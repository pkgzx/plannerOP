import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/store/clients.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:intl/intl.dart';

class RecentOps extends StatelessWidget {
  const RecentOps({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AssignmentsProvider>(
      builder: (context, provider, child) {
        // Obtener las asignaciones ordenadas por fecha reciente
        final allAssignments = [...provider.assignments];
        allAssignments.sort((a, b) {
          final dateA = a.endDate ?? a.date;
          final dateB = b.endDate ?? b.date;
          return dateB.compareTo(dateA);
        });

        // Limitar a 5 elementos
        final recentOps = allAssignments.take(5).toList();
        final int itemCount = recentOps.isEmpty ? 0 : recentOps.length;

        return Neumorphic(
          style: NeumorphicStyle(
            depth: 3,
            intensity: 0.5,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
            color: const Color(0xFFF7FAFC),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize
                  .min, // Importante: esto evita que Column tome todo el espacio disponible
              children: [
                Row(
                  children: const [
                    Icon(Icons.history, color: Color(0xFF4299E1), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Operaciones Recientes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Lista con altura limitada, sin Expanded
                SizedBox(
                  height: 270, // Altura fija para evitar desbordamiento
                  child: Neumorphic(
                    style: NeumorphicStyle(
                      depth: 2,
                      intensity: 0.6,
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(12)),
                      color: Colors.white,
                    ),
                    child: itemCount == 0
                        ? _buildEmptyState()
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: itemCount,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final assignment = recentOps[index];

                              // Determinar el estado de la operación
                              String estado;
                              Color colorFondo;
                              Color colorTexto;

                              switch (assignment.status) {
                                case 'PENDING':
                                  estado = 'Pendiente';
                                  colorFondo = const Color(0xFFFEF5E7);
                                  colorTexto = const Color(0xFFB7791F);
                                  break;
                                case 'INPROGRESS':
                                  estado = 'En curso';
                                  colorFondo = const Color(0xFFEBF4FF);
                                  colorTexto = const Color(0xFF2B6CB0);
                                  break;
                                case 'COMPLETED':
                                  estado = 'Finalizada';
                                  colorFondo = const Color(0xFFE6FFED);
                                  colorTexto = const Color(0xFF2F855A);
                                  break;
                                default:
                                  estado = 'Pendiente';
                                  colorFondo = const Color(0xFFFEF5E7);
                                  colorTexto = const Color(0xFFB7791F);
                              }

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 6.0),
                                title: Text(
                                  assignment.task,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                                subtitle: Text(
                                  'Área: ${assignment.area}',
                                  style: const TextStyle(
                                    color: Color(0xFF718096),
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colorFondo,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    estado,
                                    style: TextStyle(
                                      color: colorTexto,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  _showAssignmentDetails(context, assignment);
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 48,
            color: Color(0xFFCBD5E0),
          ),
          SizedBox(height: 16),
          Text(
            'No hay operaciones recientes',
            style: TextStyle(
              color: Color(0xFF718096),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Reemplaza el método _showAssignmentDetails existente con este nuevo método:

  void _showAssignmentDetails(BuildContext context, Assignment assignment) {
    // Determinar el estado de la operación y sus colores
    String estado;
    Color colorFondo;
    Color colorTexto;
    IconData stateIcon;

    switch (assignment.status.toUpperCase()) {
      case 'PENDING':
        estado = 'Pendiente';
        colorFondo = const Color(0xFFFEF5E7);
        colorTexto = const Color(0xFFB7791F);
        stateIcon = Icons.pending_outlined;
        break;
      case 'INPROGRESS':
        estado = 'En curso';
        colorFondo = const Color(0xFFEBF4FF);
        colorTexto = const Color(0xFF2B6CB0);
        stateIcon = Icons.sync;
        break;
      case 'COMPLETED':
        estado = 'Finalizada';
        colorFondo = const Color(0xFFE6FFED);
        colorTexto = const Color(0xFF2F855A);
        stateIcon = Icons.check_circle_outline;
        break;
      default:
        estado = 'Pendiente';
        colorFondo = const Color(0xFFFEF5E7);
        colorTexto = const Color(0xFFB7791F);
        stateIcon = Icons.pending_outlined;
    }

    final formattedStartDate = DateFormat('dd/MM/yyyy').format(assignment.date);
    final formattedEndDate = assignment.endDate != null
        ? DateFormat('dd/MM/yyyy').format(assignment.endDate!)
        : '---';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabecera con estilo mejorado
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorFondo,
                      colorFondo.withOpacity(0.85),
                    ],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorTexto.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                stateIcon,
                                color: colorTexto,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              estado,
                              style: TextStyle(
                                color: colorTexto,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black54),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      assignment.task,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF2D3748),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Contenido principal (scrollable)
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sección de información general
                        _buildSectionHeader('Información de la Operación'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              _buildDetailRow(
                                icon: Icons.room_outlined,
                                label: 'Área',
                                value: assignment.area,
                              ),
                              const Divider(height: 16),
                              _buildDetailRow(
                                icon: Icons.grid_view_outlined,
                                label: 'Zona',
                                value: 'Zona ${assignment.zone}',
                              ),
                              if (assignment.motorship != null &&
                                  assignment.motorship!.isNotEmpty) ...[
                                const Divider(height: 16),
                                _buildDetailRow(
                                  icon: Icons.directions_boat_outlined,
                                  label: 'Motonave',
                                  value: assignment.motorship!,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Sección de fechas
                        _buildSectionHeader('Programación'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDetailRow(
                                      icon: Icons.calendar_today_outlined,
                                      label: 'Fecha inicio',
                                      value: formattedStartDate,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildDetailRow(
                                      icon: Icons.access_time_outlined,
                                      label: 'Hora inicio',
                                      value: assignment.time,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDetailRow(
                                      icon: Icons.event_outlined,
                                      label: 'Fecha fin',
                                      value: formattedEndDate,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildDetailRow(
                                      icon: Icons.timer_outlined,
                                      label: 'Hora fin',
                                      value: assignment.endTime ?? '---',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Sección de trabajadores
                        _buildSectionHeader('Trabajadores Asignados'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: assignment.workers.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    'No hay trabajadores asignados',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF718096),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: assignment.workers.map((worker) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor:
                                                _getColorForWorker(worker.name),
                                            child: Text(
                                              worker.name.isNotEmpty
                                                  ? worker.name
                                                      .substring(0, 1)
                                                      .toUpperCase()
                                                  : "?",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  worker.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF2D3748),
                                                  ),
                                                ),
                                                Text(
                                                  worker.area,
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
                                  }).toList(),
                                ),
                        ),

                        const SizedBox(height: 20),

                        // Sección de cliente
                        _buildSectionHeader('Cliente'),
                        const SizedBox(height: 8),
                        FutureBuilder(
                          future: _getClientName(context, assignment.clientId),
                          builder: (context, snapshot) {
                            final String clientName =
                                snapshot.data?.toString() ??
                                    'Cargando información...';

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: _buildDetailRow(
                                icon: Icons.business_outlined,
                                label: 'Empresa',
                                value: clientName,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Botones de acción
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(12)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: NeumorphicButton(
                        style: NeumorphicStyle(
                          depth: 2,
                          intensity: 0.7,
                          color: const Color(0xFF3182CE),
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(8)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cerrar',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Métodos auxiliares

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF3182CE),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF718096),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF718096),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF2D3748),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Obtener el nombre del cliente usando el ID
  Future<String?> _getClientName(BuildContext context, int clientId) async {
    if (clientId == null) return 'Sin cliente asignado';

    final clientsProvider =
        Provider.of<ClientsProvider>(context, listen: false);
    final client = clientsProvider.getClientById(clientId);

    return client?.name ?? 'Cliente no encontrado';
  }

  // Color para el avatar del trabajador basado en su nombre
  Color _getColorForWorker(String name) {
    final List<Color> colors = [
      const Color(0xFF4299E1), // azul
      const Color(0xFF48BB78), // verde
      const Color(0xFFED8936), // naranja
      const Color(0xFF9F7AEA), // púrpura
      const Color(0xFFF56565), // rojo
      const Color(0xFFECC94B), // amarillo
    ];

    return colors[name.hashCode % colors.length];
  }

  // Obtener texto de estado para el trabajador
  String _getStatusText(WorkerStatus status) {
    switch (status) {
      case WorkerStatus.available:
        return 'DISPONIBLE';
      case WorkerStatus.assigned:
        return 'ASIGNADO';
      case WorkerStatus.incapacitated:
        return 'INCAPACIDAD';
      case WorkerStatus.deactivated:
        return 'RETIRADO';
      default:
        return 'DESCONOCIDO';
    }
  }

  // Obtener color para el estado del trabajador
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return const Color(0xFF48BB78);
      case 'ASSIGNED':
        return const Color(0xFF4299E1);
      case 'INCAPACITATED':
        return const Color(0xFFF56565);
      case 'DEACTIVATED':
        return const Color(0xFF718096);
      default:
        return const Color(0xFF718096);
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF718096),
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2D3748),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
