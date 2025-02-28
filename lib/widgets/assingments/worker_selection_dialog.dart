import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/store/workers.dart';
import 'package:provider/provider.dart';

class WorkerSelectionDialog extends StatefulWidget {
  // Lista de trabajadores ya seleccionados (mapas con detalles del trabajador)
  final List<Worker> selectedWorkers;

  const WorkerSelectionDialog({
    Key? key,
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
  List<String> _areas = ["Todas"];

  @override
  void initState() {
    super.initState();

    // Inicializar con los trabajadores ya seleccionados
    _tempSelectedWorkers = List.from(widget.selectedWorkers);

    // Escuchar cambios en el campo de búsqueda
    _searchController.addListener(() {
      _applyFilters();
    });

    // Aplicamos los filtros inicialmente después de construir el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAreas();
      _applyFilters();
    });
  }

  void _initializeAreas() {
    final workersProvider =
        Provider.of<WorkersProvider>(context, listen: false);
    final workers = workersProvider.getWorkersByStatus(WorkerStatus.available);

    // Recopilamos las áreas disponibles
    final uniqueAreas = <String>{"Todas"};
    for (var worker in workers) {
      uniqueAreas.add(worker.area);
    }

    setState(() {
      _areas = uniqueAreas.toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Método para aplicar los filtros y búsqueda
  void _applyFilters() {
    final workersProvider =
        Provider.of<WorkersProvider>(context, listen: false);
    final availableWorkers =
        workersProvider.getWorkersByStatus(WorkerStatus.available);

    setState(() {
      _filteredWorkers = availableWorkers.where((worker) {
        // Filtrar por texto de búsqueda (nombre o documento)
        final searchQuery = _searchController.text.toLowerCase();
        final searchMatch = searchQuery.isEmpty ||
            worker.name.toLowerCase().contains(searchQuery) ||
            worker.document.toLowerCase().contains(searchQuery) ||
            worker.area.toLowerCase().contains(searchQuery);

        // Filtrar por área
        final areaMatch = _areaFilter == "Todas" || worker.area == _areaFilter;

        // Solo incluir si cumple todos los criterios
        return searchMatch && areaMatch;
      }).toList();
    });
  }

  // Cambiar el estado de selección de un trabajador
  void _toggleWorkerSelection(Worker worker) {
    final workersProvider =
        Provider.of<WorkersProvider>(context, listen: false);

    setState(() {
      // Verificamos si el trabajador ya está seleccionado por su documento
      final isSelected = _isWorkerSelected(worker.document);

      if (isSelected) {
        // Eliminar de la selección
        _tempSelectedWorkers.removeWhere((w) => w.document == worker.document);
      } else {
        // Añadir a la selección
        _tempSelectedWorkers.add(worker);
      }
    });
  }

  // Verificar si un trabajador está seleccionado por su documento
  bool _isWorkerSelected(String documentId) {
    return _tempSelectedWorkers.any((w) => w.document == documentId);
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
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSearchField(),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 16),
            _buildWorkersList(),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
    );
  }

  Widget _buildSearchField() {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: -3,
        intensity: 0.7,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(10)),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Buscar por nombre o documento',
          prefixIcon: Icon(Icons.search, color: Color(0xFF718096)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
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
    );
  }

  Widget _buildWorkersList() {
    return Expanded(
      child: _filteredWorkers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_search,
                    color: Colors.grey[300],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No se encontraron trabajadores disponibles',
                    style: TextStyle(
                      color: const Color(0xFF718096),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_searchController.text.isNotEmpty ||
                      _areaFilter != "Todas")
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _areaFilter = "Todas";
                          _applyFilters();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("Limpiar filtros"),
                    ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _filteredWorkers.length,
              itemBuilder: (context, index) {
                final worker = _filteredWorkers[index];
                final isSelected = _isWorkerSelected(worker.document);
                final workersProvider =
                    Provider.of<WorkersProvider>(context, listen: false);

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
                      backgroundColor:
                          workersProvider.getColorForArea(worker.area),
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.area,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'DNI: ${worker.document}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
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
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Text(
          '#: ${_tempSelectedWorkers.length}',
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
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
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
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
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
}
