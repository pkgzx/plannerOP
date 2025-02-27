import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';

class WorkerListItem extends StatelessWidget {
  final Worker worker;
  final Color specialtyColor;
  final VoidCallback onTap;

  const WorkerListItem({
    Key? key,
    required this.worker,
    required this.specialtyColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Círculo con la inicial
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: specialtyColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      worker.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: specialtyColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),

                // Información del trabajador
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: specialtyColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            worker.area,
                            style: const TextStyle(
                              color: Color(0xFF718096),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Estado (asignado/disponible)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: worker.status == WorkerStatus.assigned
                        ? const Color(0xFFFED7D7)
                        : const Color(0xFFE6FFFA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    worker.status == WorkerStatus.assigned
                        ? 'Asignado'
                        : 'Disponible',
                    style: TextStyle(
                      color: worker.status == WorkerStatus.assigned
                          ? const Color(0xFFC53030)
                          : const Color(0xFF2C7A7B),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
