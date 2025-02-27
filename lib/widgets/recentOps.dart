import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
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
          final dateA = a.completedDate ?? a.date;
          final dateB = b.completedDate ?? b.date;
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
                                case 'pending':
                                  estado = 'Pendiente';
                                  colorFondo = const Color(0xFFFEF5E7);
                                  colorTexto = const Color(0xFFB7791F);
                                  break;
                                case 'in_progress':
                                  estado = 'En progreso';
                                  colorFondo = const Color(0xFFEBF4FF);
                                  colorTexto = const Color(0xFF2B6CB0);
                                  break;
                                case 'completed':
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

  void _showAssignmentDetails(BuildContext context, Assignment assignment) {
    // Determinar el estado de la operación y sus colores
    String estado;
    Color colorFondo;
    Color colorTexto;
    IconData stateIcon;

    switch (assignment.status) {
      case 'pending':
        estado = 'Pendiente';
        colorFondo = const Color(0xFFFEF5E7);
        colorTexto = const Color(0xFFB7791F);
        stateIcon = Icons.pending_outlined;
        break;
      case 'in_progress':
        estado = 'En progreso';
        colorFondo = const Color(0xFFEBF4FF);
        colorTexto = const Color(0xFF2B6CB0);
        stateIcon = Icons.sync;
        break;
      case 'completed':
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

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabecera
              Container(
                decoration: BoxDecoration(
                  color: colorFondo,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            stateIcon,
                            color: colorTexto,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                estado,
                                style: TextStyle(
                                  color: colorTexto,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                assignment.status == 'completed' &&
                                        assignment.completedDate != null
                                    ? 'Completada el ${DateFormat('dd/MM/yyyy').format(assignment.completedDate!)}'
                                    : 'Programada para el ${DateFormat('dd/MM/yyyy').format(assignment.date)}',
                                style: TextStyle(
                                  color: colorTexto.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Contenido
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      assignment.task,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info básica
                    _buildInfoRow(
                      icon: Icons.room_outlined,
                      label: 'Área',
                      value: assignment.area,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Fecha',
                      value: DateFormat('dd/MM/yyyy').format(assignment.date),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.access_time_outlined,
                      label: 'Hora',
                      value: assignment.time,
                    ),
                    const SizedBox(height: 16),

                    // Trabajadores
                    const Text(
                      'Trabajadores asignados',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (assignment.workers.isEmpty)
                      const Text(
                        'No hay trabajadores asignados',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF718096),
                        ),
                      )
                    else
                      ...assignment.workers.map((worker) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 16,
                                color: Color(0xFF718096),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                worker['name'] as String,
                                style: const TextStyle(
                                  color: Color(0xFF4A5568),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
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
