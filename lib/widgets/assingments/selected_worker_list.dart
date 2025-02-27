import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/worker.dart';
import 'worker_selection_dialog.dart';

class SelectedWorkersList extends StatefulWidget {
  // Lista de trabajadores seleccionados (ahora como Map)
  final List<Map<String, dynamic>> selectedWorkers;

  // Función de callback cuando cambia la selección (ahora con Map)
  final Function(List<Map<String, dynamic>>) onWorkersChanged;

  // Todos los trabajadores disponibles (para el diálogo de selección)
  final List<Map<String, dynamic>> availableWorkers;

  const SelectedWorkersList({
    Key? key,
    required this.selectedWorkers,
    required this.onWorkersChanged,
    required this.availableWorkers,
  }) : super(key: key);

  @override
  State<SelectedWorkersList> createState() => _SelectedWorkersListState();
}

class _SelectedWorkersListState extends State<SelectedWorkersList> {
  // Abrir diálogo para seleccionar trabajadores
  Future<void> _openWorkerSelectionDialog() async {
    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) => WorkerSelectionDialog(
        availableWorkers: widget.availableWorkers,
        selectedWorkers: widget.selectedWorkers,
      ),
    );

    if (result != null) {
      // Notificar al padre sobre el cambio
      widget.onWorkersChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título y botón para agregar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Trabajadores Asignados',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF4A5568),
              ),
            ),
            NeumorphicButton(
              style: NeumorphicStyle(
                depth: 2,
                intensity: 0.6,
                boxShape:
                    NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                color: const Color(0xFF3182CE),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onPressed: _openWorkerSelectionDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.person_add,
                    size: 16,
                    color: Colors.white,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "Añadir",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Lista de trabajadores seleccionados
        widget.selectedWorkers.isEmpty
            ? Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF7FAFC),
                ),
                child: const Center(
                  child: Text(
                    'No hay trabajadores seleccionados',
                    style: TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.selectedWorkers.length,
                  itemBuilder: (context, index) {
                    final worker = widget.selectedWorkers[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      elevation: 0,
                      color: const Color(0xFFF7FAFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: _getColorForWorker(worker),
                          radius: 16,
                          child: Text(
                            worker["name"].substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(
                          worker["name"],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${worker["area"]}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          onPressed: () {
                            final updatedList = List<Map<String, dynamic>>.from(
                                widget.selectedWorkers);
                            updatedList.removeAt(index);
                            widget.onWorkersChanged(updatedList);
                          },
                          tooltip: 'Eliminar',
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  // Obtener un color consistente para cada trabajador basado en su ID
  Color _getColorForWorker(Map<String, dynamic> worker) {
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
    ];

    // Convertir el ID a un número para seleccionar un color
    int colorIndex = worker["id"].hashCode % colors.length;
    return colors[colorIndex.abs()];
  }
}
