import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/core/model/fault.dart';
import 'package:plannerop/store/faults.dart';
import 'package:plannerop/store/workers.dart';
import 'package:provider/provider.dart';

class WorkersWithMostFaults extends StatelessWidget {
  final Function(Worker) onWorkerTap;

  const WorkersWithMostFaults({Key? key, required this.onWorkerTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<WorkersProvider, FaultsProvider>(
      builder: (context, workersProvider, faultsProvider, child) {
        if (faultsProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Obtener trabajadores ordenados por faltas
        final workersWithFaults =
            faultsProvider.getWorkersWithMostFaults(context);

        if (workersWithFaults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay trabajadores con faltas registradas',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: workersWithFaults.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final worker = workersWithFaults[index];
            final faultCount = faultsProvider.getFaultCountForWorker(worker.id);

            return _buildWorkerCard(context, worker, faultCount);
          },
        );
      },
    );
  }

  Widget _buildWorkerCard(BuildContext context, Worker worker, int faultCount) {
    // Color basado en la cantidad de faltas
    Color statusColor;
    if (faultCount >= 5) {
      statusColor = Colors.red;
    } else if (faultCount >= 3) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.amber;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(12),
          onTap: () => onWorkerTap(worker),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${worker.name.substring(0, 1).toUpperCase()}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        worker.area,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$faultCount ${faultCount == 1 ? 'falta' : 'faltas'}',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
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
