import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';

Widget buildWorkerItem(Worker worker, {bool isDeleted = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: isDeleted
          ? BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade100),
            )
          : null,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isDeleted
                ? Colors.grey
                : Colors
                    .primaries[worker.name.hashCode % Colors.primaries.length],
            radius: 18,
            child: isDeleted
                ? const Icon(Icons.person_off_outlined,
                    color: Colors.white, size: 16)
                : Text(
                    worker.name.toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDeleted
                        ? Colors.red.shade700
                        : const Color(0xFF2D3748),
                    decoration: isDeleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (worker.area.isNotEmpty)
                  Text(
                    worker.area.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDeleted
                          ? Colors.red.shade300
                          : const Color(0xFF718096),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
