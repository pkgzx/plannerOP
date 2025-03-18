import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';

class WorkerSelectionWidget extends StatefulWidget {
  final List<Worker> selectedWorkers;
  final List<Worker> allWorkers;
  final Function(List<Worker>, List<Worker>) onSelectionChanged;
  final List<Worker> deletedWorkers;

  const WorkerSelectionWidget({
    Key? key,
    required this.selectedWorkers,
    required this.allWorkers,
    required this.onSelectionChanged,
    this.deletedWorkers = const [],
  }) : super(key: key);

  @override
  _WorkerSelectionWidgetState createState() => _WorkerSelectionWidgetState();
}

class _WorkerSelectionWidgetState extends State<WorkerSelectionWidget> {
  late List<Worker> _availableWorkers;
  late List<Worker> _selectedWorkers;
  late List<Worker> _deletedWorkers;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedWorkers = List.from(widget.selectedWorkers);
    _deletedWorkers =
        List.from(widget.deletedWorkers); // Initialize deleted workers list

    // Asegurar que los trabajadores disponibles no incluyan a los ya seleccionados
    _updateAvailableWorkers();
  }

  @override
  void didUpdateWidget(WorkerSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedWorkers != widget.selectedWorkers ||
        oldWidget.allWorkers != widget.allWorkers ||
        oldWidget.deletedWorkers != widget.deletedWorkers) {
      _selectedWorkers = List.from(widget.selectedWorkers);
      _deletedWorkers = List.from(widget.deletedWorkers);
      _updateAvailableWorkers();
    }
  }

  void _updateAvailableWorkers() {
    final selectedIds = _selectedWorkers.map((w) => w.id).toSet();
    _availableWorkers = widget.allWorkers
        .where((worker) => !selectedIds.contains(worker.id))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trabajadores asignados',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 12),

        // Mostrar trabajadores seleccionados
        if (_selectedWorkers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Text(
                'No hay trabajadores seleccionados',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            children: _selectedWorkers.map((worker) {
              return Chip(
                backgroundColor: Colors.blue[50],
                label: Text(worker.name),
                deleteIconColor: Colors.blue[700],
                onDeleted: () {
                  setState(() {
                    _selectedWorkers.remove(worker);
                    _availableWorkers.add(worker);

                    // Add to deleted workers list if not already there
                    if (!_deletedWorkers.any((w) => w.id == worker.id)) {
                      _deletedWorkers.add(worker);
                    }

                    // Call onSelectionChanged with both updated lists
                    widget.onSelectionChanged(
                        _selectedWorkers, _deletedWorkers);
                  });
                },
              );
            }).toList(),
          ),

        const SizedBox(height: 16),

        // Botón para agregar trabajadores
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Agregar trabajador'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3182CE),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _showWorkerSelectionDialog,
        ),
      ],
    );
  }

  void _showWorkerSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Filtrar trabajadores disponibles con la búsqueda
            final filteredWorkers = _searchQuery.isEmpty
                ? _availableWorkers
                : _availableWorkers
                    .where((worker) => worker.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();

            return AlertDialog(
              title: const Text('Seleccionar trabajadores'),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Campo de búsqueda
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar trabajador...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Lista de trabajadores
                    Expanded(
                      child: filteredWorkers.isEmpty
                          ? Center(
                              child: Text(
                                _searchQuery.isEmpty
                                    ? 'No hay trabajadores disponibles'
                                    : 'No se encontraron coincidencias',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredWorkers.length,
                              itemBuilder: (context, index) {
                                final worker = filteredWorkers[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.primaries[
                                        worker.name.hashCode %
                                            Colors.primaries.length],
                                    child: Text(
                                      worker.name.isNotEmpty
                                          ? worker.name[0].toUpperCase()
                                          : '?',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(worker.name),
                                  subtitle: Text(worker.area),
                                  onTap: () {
                                    this.setState(() {
                                      _selectedWorkers.add(worker);
                                      _availableWorkers.remove(worker);
                                      widget.onSelectionChanged(
                                          _selectedWorkers, _deletedWorkers);
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
