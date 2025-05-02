import 'package:flutter/material.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/core/model/worker.dart';

Map<String, List<Worker>> groupWorkersByGroup(Assignment assignment) {
  final Map<String, List<Worker>> workersByGroup = {};
  final Set<int> finishedWorkerIds =
      assignment.workersFinished.map((w) => w.id).toSet();

  for (var group in assignment.groups) {
    workersByGroup[group.id] = assignment.workers
        .where((worker) =>
            group.workers.contains(worker.id) &&
            !finishedWorkerIds.contains(worker.id))
        .toList();
  }

  return workersByGroup;
}

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

Widget buildInChargerItem(User charger) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.shade400,
            radius: 18,
            child: Text(
              charger.name.toString().substring(0, 1).toUpperCase(),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        charger.name.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ],
                ),
                if (charger.cargo.isNotEmpty)
                  Text(
                    charger.cargo.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF718096),
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
