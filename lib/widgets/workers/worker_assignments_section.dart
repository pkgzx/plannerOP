import 'package:flutter/material.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:provider/provider.dart';

class WorkerAssignmentsSection extends StatelessWidget {
  final Worker worker;
  final Color specialtyColor;

  const WorkerAssignmentsSection({
    Key? key,
    required this.worker,
    required this.specialtyColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Simulación de asignaciones actuales
    final List<Assignment> assignments =
        Provider.of<AssignmentsProvider>(context).assignments;

    if (assignments.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Divider(),
        ),
        Text(
          'Operaciones Actuales',
          style: TextStyle(
            color: specialtyColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...assignments
            .where((assignment) =>
                assignment.workers.any((w) => w.id == worker.id))
            .where((assignment) => assignment.status != 'COMPLETED')
            .map((assignment) => _buildAssignmentItem(assignment))
            .toList(),
      ],
    );
  }

  Widget _buildAssignmentItem(Assignment assignment) {
    final date = assignment.date;
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: specialtyColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(assignment.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  getStatusFormatted(assignment.status),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(assignment.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                assignment.area,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                formattedDate,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
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
}

String getStatusFormatted(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return 'Pendiente';
    case 'INPROGRESS':
      return 'En Curso';
    case 'COMPLETED':
      return 'Completada';
    case 'CANCELLED':
      return 'Cancelada';
    default:
      return 'Desconocido';
  }
}
