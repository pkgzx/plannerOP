import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/assignments.dart';

class Cifras extends StatelessWidget {
  const Cifras({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AssignmentsProvider>(
      builder: (context, provider, child) {
        // Calculamos las cifras necesarias
        final int totalAssignments = provider.assignments.length;
        final int pendingAssignments = provider.pendingAssignments.length;
        final int activeAssignments = provider.inProgressAssignments.length;
        final int completedAssignments = provider.completedAssignments.length;

        // Extraemos trabajadores únicos de todas las asignaciones
        final Set<String> uniqueWorkers = {};
        for (var assignment in provider.assignments) {
          for (var worker in assignment.workers) {
            uniqueWorkers.add(worker['name'] as String);
          }
        }
        final int totalWorkers = uniqueWorkers.length;

        return Neumorphic(
          style: NeumorphicStyle(
            depth: 3,
            intensity: 0.5,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
            color: const Color.fromARGB(255, 234, 241, 245),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.insights, color: Color(0xFF4299E1), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Cifras Clave',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Primera fila del grid
                Row(
                  children: [
                    // Trabajadores
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.person,
                        label: 'Trabajadores',
                        value: '$totalWorkers',
                        color: const Color(0xFFE6F0FF),
                        iconColor: const Color(0xFF3182CE),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Total de asignaciones
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.assignment_turned_in,
                        label: 'Activas',
                        value: '$activeAssignments',
                        color: const Color(0xFFE6FFED),
                        iconColor: const Color(0xFF2F855A),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Segunda fila del grid
                Row(
                  children: [
                    // Operaciones activas
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.pending_actions,
                        label: 'Pendientes',
                        value: '$pendingAssignments',
                        color: const Color(0xFFFFFAE6),
                        iconColor: const Color(0xFFDD6B20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Operaciones pendientes
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.check_circle,
                        label: 'Completadas',
                        value: '$completedAssignments',
                        color: const Color(0xFFEDFDFD),
                        iconColor: const Color(0xFF38B2AC),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color iconColor,
  }) {
    return SizedBox(
      height: 80, // Altura reducida para que quepa mejor en el grid
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 3,
          intensity: 0.6,
          lightSource: LightSource.topLeft,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
          color: color,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 12),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22, // Ligeramente más pequeño para ajustar mejor
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
