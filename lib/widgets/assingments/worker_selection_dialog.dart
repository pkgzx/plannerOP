import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/worker.dart';

class WorkerSelectionDialog extends StatefulWidget {
  // Lista de todos los trabajadores disponibles
  final List<Worker> availableWorkers;
  // Lista de trabajadores ya seleccionados (para mostrarlos como seleccionados)
  final List<Worker> selectedWorkers;

  const WorkerSelectionDialog({
    Key? key,
    required this.availableWorkers,
    required this.selectedWorkers,
  }) : super(key: key);

  @override
  State<WorkerSelectionDialog> createState() => _WorkerSelectionDialogState();
}

class _WorkerSelectionDialogState extends State<WorkerSelectionDialog> {
  // Controlador para el campo de búsqueda
  final TextEditingController _searchController = TextEditingController();

  // Lista de trabajadores filtrados
  List<Worker> _filteredWorkers = [];

  // Lista temporal de trabajadores seleccionados
  late List<Worker> _tempSelectedWorkers;

  // Filtros activos
  String _areaFilter = "Todas";

  // Opciones para los filtros
  final List<String> _areas = [
    "Todas",
    "CAFE",
    "CARGA GENERAL",
    "LAVADO CONT.",
    "OPERADORES MC"
  ];

  @override
  void initState() {
    super.initState();

    // Inicializar con los trabajadores ya seleccionados
    _tempSelectedWorkers = List.from(widget.selectedWorkers);

    // Aplicar filtro inicial
    _applyFilters();

    // Escuchar cambios en el campo de búsqueda
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Método para aplicar los filtros y búsqueda
  void _applyFilters() {
    setState(() {
      _filteredWorkers = widget.availableWorkers.where((worker) {
        // Filtrar por texto de búsqueda (nombre o ID)
        final searchMatch = _searchController.text.isEmpty ||
            worker.name
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            worker.document
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());

        // Filtrar por área
        final areaMatch = _areaFilter == "Todas" || worker.area == _areaFilter;

        // Solo incluir si cumple todos los criterios
        return searchMatch && areaMatch;
      }).toList();
    });
  }

  // Cambiar el estado de selección de un trabajador
  void _toggleWorkerSelection(Worker worker) {
    setState(() {
      final isSelected = _isWorkerSelected(worker);

      if (isSelected) {
        // Eliminar de la selección
        _tempSelectedWorkers.removeWhere((w) => w.document == worker.document);
      } else {
        // Añadir a la selección
        _tempSelectedWorkers.add(worker);
      }
    });
  }

  // Verificar si un trabajador está seleccionado
  bool _isWorkerSelected(Worker worker) {
    return _tempSelectedWorkers.any((w) => w.document == worker.document);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 600,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Seleccionar Trabajadores',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Campo de búsqueda
            Neumorphic(
              style: NeumorphicStyle(
                depth: -3,
                intensity: 0.7,
                boxShape:
                    NeumorphicBoxShape.roundRect(BorderRadius.circular(10)),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre o ID',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF718096)),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Filtros
            Row(
              children: [
                Expanded(
                  child: _buildFilterDropdown(
                    'Área',
                    _areaFilter,
                    _areas,
                    (value) {
                      setState(() {
                        _areaFilter = value;
                        _applyFilters();
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Lista de trabajadores filtrados
            Expanded(
              child: _filteredWorkers.isEmpty
                  ? const Center(
                      child: Text(
                        'No se encontraron trabajadores',
                        style: TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredWorkers.length,
                      itemBuilder: (context, index) {
                        final worker = _filteredWorkers[index];
                        final isSelected = _isWorkerSelected(worker);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF3182CE)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getColorForWorker(worker),
                              child: Text(
                                worker.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              worker.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${worker.area}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF3182CE),
                                  )
                                : Icon(
                                    Icons.circle_outlined,
                                    color: Colors.grey[400],
                                  ),
                            onTap: () => _toggleWorkerSelection(worker),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            // Conteo y botón de selección
            Row(
              children: [
                Text(
                  '# ${_tempSelectedWorkers.length}',
                  style: const TextStyle(
                    color: Color(0xFF718096),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: 2,
                    intensity: 0.6,
                    color: Colors.white,
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Color(0xFF718096),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: 2,
                    intensity: 0.6,
                    color: const Color(0xFF3182CE),
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.pop(context, _tempSelectedWorkers);
                  },
                  child: const Text(
                    'Seleccionar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget para los dropdowns de filtros
  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF718096),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF718096)),
            items: options.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ),
      ],
    );
  }

  // Obtener un color consistente para cada trabajador basado en su ID
  Color _getColorForWorker(Worker worker) {
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
    int colorIndex = worker.document.hashCode % colors.length;
    return colors[colorIndex.abs()];
  }
}
