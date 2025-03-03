import 'package:flutter/material.dart';
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
        _buildDetailRow(
          icon: Icons.phone,
          label: 'Contacto',
          value: worker.phone,
          color: specialtyColor,
        ),
        const SizedBox(height: 10),
        _buildDetailRow(
          icon: Icons.badge,
          label: 'Documento',
          value: worker.document,
          color: specialtyColor,
        ),
        const SizedBox(height: 10),
        _buildDetailRow(
          icon: Icons.qr_code,
          label: 'Código',
          value: workerCode,
          color: specialtyColor,
        ),

        // Si el trabajador está incapacitado, mostrar fechas de incapacidad
        if (worker.status == WorkerStatus.incapacitated &&
            worker.startDate != null &&
            worker.endDate != null) ...[
          const SizedBox(height: 10),
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Incapacidad',
            value:
                '${_formatDate(worker.startDate!)} - ${_formatDate(worker.endDate!)}',
            color: Colors.purple,
          ),
        ],

        // Si el trabajador está retirado, mostrar fecha de retiro
        if (worker.status == WorkerStatus.deactivated &&
            worker.endDate != null) ...[
          const SizedBox(height: 10),
          _buildDetailRow(
            icon: Icons.exit_to_app,
            label: 'Fecha de Retiro',
            value: _formatDate(worker.endDate!),
            color: Colors.grey,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
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
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
