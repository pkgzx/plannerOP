import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/services/workerService.dart';
import 'package:intl/intl.dart';

class WorkerCard extends StatelessWidget {
  final Worker worker;
  final bool isActive;
  final bool isHistory;

  const WorkerCard({
    Key? key,
    required this.worker,
    required this.isActive,
    this.isHistory = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    if (isHistory) {
      statusColor = const Color(0xFF718096);
      statusText = 'Finalizada';
    } else if (isActive) {
      statusColor = const Color(0xFF3182CE);
      statusText = 'Activa';
    } else {
      statusColor = const Color(0xFFDD6B20);
      statusText = 'Pendiente';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 2,
          intensity: 0.8,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
          color: isHistory ? const Color(0xFFF7FAFC) : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: WorkerService.getAvatarColor(worker.name),
                    radius: 24,
                    child: Text(
                      worker.name.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          worker.position,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                            Icons.location_on_outlined, 'Zona', worker.zone),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                            Icons.calendar_today_outlined,
                            'Fecha Inicio',
                            DateFormat('dd/MM/yyyy').format(worker.startDate)),
                        if (worker.endDate != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.event_outlined, 'Fecha Fin',
                              DateFormat('dd/MM/yyyy').format(worker.endDate!)),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.access_time_outlined, 'Horario',
                            worker.schedule),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                            Icons.assignment_outlined, 'Tarea', worker.task),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isHistory) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    NeumorphicButton(
                      style: NeumorphicStyle(
                        depth: 2,
                        intensity: 0.6,
                        color: Colors.white,
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        // Editar asignación
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: Color(0xFF3182CE),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Editar',
                            style: TextStyle(
                              color: Color(0xFF3182CE),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    NeumorphicButton(
                      style: NeumorphicStyle(
                        depth: 2,
                        intensity: 0.6,
                        color: Colors.white,
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        // Cancelar asignación
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Color(0xFFE53E3E),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Color(0xFFE53E3E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFF718096),
          size: 16,
        ),
        const SizedBox(width: 6),
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
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
