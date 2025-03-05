import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/worker.dart';

class WorkerDetailsSection extends StatelessWidget {
  final Worker worker;
  final Color specialtyColor;
  final String workerCode;

  const WorkerDetailsSection({
    Key? key,
    required this.worker,
    required this.specialtyColor,
    required this.workerCode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información de contacto
        _buildInfoSection(
          title: 'Información Personal',
          icon: Icons.person_outline,
          color: specialtyColor,
          content: [
            _buildInfoRow(Icons.badge_outlined, 'Documento', worker.document),
            _buildInfoRow(Icons.phone_outlined, 'Teléfono', worker.phone),
            _buildInfoRow(Icons.calendar_today_outlined, 'Fecha de inicio',
                DateFormat('dd/MM/yyyy').format(worker.startDate)),
          ],
        ),

        const SizedBox(height: 20),

        // Información de estado
        _buildStatusSection(),
      ],
    );
  }

  Widget _buildStatusSection() {
    // No mostrar esta sección para trabajadores disponibles regulares
    if (worker.status == WorkerStatus.available ||
        (worker.status == WorkerStatus.assigned && worker.endDate == null)) {
      return Container();
    }

    String title;
    IconData icon;
    Color color;
    List<Widget> rows = [];

    // Configurar según el estado
    switch (worker.status) {
      case WorkerStatus.assigned:
        title = 'Información de Asignación';
        icon = Icons.assignment_turned_in;
        color = Colors.amber[700]!;
        if (worker.endDate != null) {
          rows.add(_buildInfoRow(
              Icons.event_available_outlined,
              'Asignado hasta',
              DateFormat('dd/MM/yyyy').format(worker.endDate!)));
        }
        break;

      case WorkerStatus.incapacitated:
        title = 'Información de Incapacidad';
        icon = Icons.medical_services_outlined;
        color = Colors.purple;

        if (worker.incapacityStartDate != null) {
          rows.add(_buildInfoRow(Icons.date_range_outlined, 'Inicio',
              DateFormat('dd/MM/yyyy').format(worker.incapacityStartDate!)));
        }

        if (worker.incapacityEndDate != null) {
          rows.add(_buildInfoRow(Icons.date_range_outlined, 'Fin',
              DateFormat('dd/MM/yyyy').format(worker.incapacityEndDate!)));

          // Calcular días restantes
          final daysLeft =
              worker.incapacityEndDate!.difference(DateTime.now()).inDays;
          String daysLeftText =
              daysLeft > 0 ? '$daysLeft días restantes' : 'Finalizada';

          rows.add(
              _buildInfoRow(Icons.hourglass_bottom, 'Estado', daysLeftText));
        }
        break;

      case WorkerStatus.deactivated:
        title = 'Información de Retiro';
        icon = Icons.exit_to_app;
        color = Colors.grey[700]!;

        if (worker.deactivationDate != null) {
          rows.add(_buildInfoRow(Icons.event_busy_outlined, 'Fecha de retiro',
              DateFormat('dd/MM/yyyy').format(worker.deactivationDate!)));
        }
        break;

      default:
        return Container();
    }

    // Si no hay filas, no mostrar la sección
    if (rows.isEmpty) {
      return Container();
    }

    return _buildInfoSection(
      title: title,
      icon: icon,
      color: color,
      content: rows,
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              ...content,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
