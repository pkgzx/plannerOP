import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/widgets/workers/workerFilter.dart';
import 'package:plannerop/store/faults.dart';
import 'package:plannerop/store/user.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/widgets/workers/workerListItem.dart';
import 'package:plannerop/widgets/workers/workerAddDialog.dart';
import 'package:plannerop/widgets/workers/workerDetailDialog.dart';
import 'package:plannerop/widgets/workers/workerEmptyState.dart';
import 'package:plannerop/widgets/workers/workerStats.dart';
import 'package:plannerop/core/model/fault.dart';

class WorkersTab extends StatefulWidget {
  const WorkersTab({Key? key}) : super(key: key);

  @override
  State<WorkersTab> createState() => _WorkersTabState();
}

class _WorkersTabState extends State<WorkersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  WorkerFilter _currentFilter =
      WorkerFilter.all; // Añade la variable para el filtro
  FaultType? _selectedFaultType;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Configurar estilo de barra de estado al iniciar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF4299E1), // Color de fondo de la barra de estado
      statusBarIconBrightness:
          Brightness.light, // Iconos claros para el fondo azul
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();

    // Restaurar estilo por defecto al salir
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  Color getColorArea(int idArea) {
    if (idArea % 9 == 0) {
      return Colors.teal;
    }

    if (idArea % 8 == 0) {
      return Colors.blue;
    }

    if (idArea % 7 == 0) {
      return Colors.green;
    }

    if (idArea % 6 == 0) {
      return Colors.yellow;
    }

    if (idArea % 5 == 0) {
      return Colors.purple;
    }

    if (idArea % 4 == 0) {
      return Colors.orange;
    }

    if (idArea % 3 == 0) {
      return Colors.pink;
    }

    if (idArea % 2 == 0) {
      return Colors.teal;
    }

    return Colors.indigo;
  }

  @override
  Widget build(BuildContext context) {
    User user = Provider.of<UserProvider>(context).user;
    final faultsProvider = Provider.of<FaultsProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera colorida
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4299E1), Color(0xFF3182CE)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trabajadores',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Gestiona tu equipo de trabajo',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buscador más colorido
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar trabajador...',
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFF4299E1)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Color(0xFF4299E1)),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Estadísticas de trabajadores con filtro
            Consumer<WorkersProvider>(
              builder: (context, workersProvider, _) {
                return WorkerStatsCards(
                  totalWorkers: workersProvider.totalWorkerWithoutRetired,
                  assignedWorkers: workersProvider.assignedWorkers,
                  currentFilter: _currentFilter,
                  disabledWorkers: workersProvider.disabledWorkers,
                  retiredWorkers: workersProvider.retiredWorkers,
                  onFilterChanged:
                      _handleFilterChanged, // Pasar el callback de cambio de filtro
                );
              },
            ),

// Si estamos en modo faltas, mostrar filtros específicos
            if (_currentFilter == WorkerFilter.faults)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFaultTypeChip(
                        'Todas',
                        null,
                        _selectedFaultType,
                        (type) => setState(() => _selectedFaultType = type),
                      ),
                      _buildFaultTypeChip(
                        'Inasistencia',
                        FaultType.INASSISTANCE,
                        _selectedFaultType,
                        (type) => setState(() => _selectedFaultType = type),
                        color: const Color(0xFFE53E3E),
                        icon: Icons.event_busy,
                      ),
                      _buildFaultTypeChip(
                        'Abandono',
                        FaultType.ABANDONMENT,
                        _selectedFaultType,
                        (type) => setState(() => _selectedFaultType = type),
                        color: const Color(0xFFED8936),
                        icon: Icons.exit_to_app,
                      ),
                      _buildFaultTypeChip(
                        'Falta de Respeto',
                        FaultType.IRRESPECTFUL,
                        _selectedFaultType,
                        (type) => setState(() => _selectedFaultType = type),
                        color: const Color(0xFF805AD5),
                        icon: Icons.sentiment_very_dissatisfied,
                      ),
                    ],
                  ),
                ),
              ),

            // Lista de trabajadores con filtro aplicado
            Expanded(
              child: Consumer<WorkersProvider>(
                builder: (context, workersProvider, _) {
                  // Aplicar los filtros (búsqueda + tipo de trabajador)
                  List<Worker> workers;

                  // Aplicar filtro de tipo de trabajador
                  switch (_currentFilter) {
                    case WorkerFilter.all:
                      workers = workersProvider.workers
                          .where((worker) =>
                              worker.status != WorkerStatus.deactivated)
                          .toList();
                      break;
                    case WorkerFilter.available:
                      workers = workersProvider
                          .getWorkersByStatus(WorkerStatus.available);
                      break;
                    case WorkerFilter.assigned:
                      workers = workersProvider
                          .getWorkersByStatus(WorkerStatus.assigned);
                      break;
                    case WorkerFilter.disabled:
                      workers = workersProvider
                          .getWorkersByStatus(WorkerStatus.incapacitated);
                      break;
                    case WorkerFilter.retired:
                      workers = workersProvider
                          .getWorkersByStatus(WorkerStatus.deactivated);
                      workers.sort((a, b) =>
                          b.deactivationDate!.compareTo(a.deactivationDate!));
                      break;
                    case WorkerFilter.faults:
                      workers =
                          faultsProvider.getWorkersWithMostFaults(context);
                      // Filtrar por tipo de falta si se ha seleccionado uno
                      if (_selectedFaultType != null) {
                        workers = workers.where((worker) {
                          final workerFaults = faultsProvider
                              .fetchFaultsByWorker(context, worker.id);
                          return workerFaults
                              .any((fault) => fault.type == _selectedFaultType);
                        }).toList();
                      }
                      break;
                  }

                  //  Ordenar trabajadores por faltas más recientes cuando estamos en el filtro de faltas
                  if (_currentFilter == WorkerFilter.faults) {
                    workers.sort((a, b) {
                      final faultsA =
                          faultsProvider.fetchFaultsByWorker(context, a.id);
                      final faultsB =
                          faultsProvider.fetchFaultsByWorker(context, b.id);

                      // Si ambos tienen faltas, comparar por la fecha más reciente
                      if (faultsA.isNotEmpty && faultsB.isNotEmpty) {
                        // Obtener falta más reciente de cada trabajador
                        final latestFaultA = faultsA.reduce((curr, next) =>
                            curr.createdAt.isAfter(next.createdAt)
                                ? curr
                                : next);
                        final latestFaultB = faultsB.reduce((curr, next) =>
                            curr.createdAt.isAfter(next.createdAt)
                                ? curr
                                : next);

                        // Ordenar por fecha más reciente primero
                        return latestFaultB.createdAt
                            .compareTo(latestFaultA.createdAt);
                      }

                      // Si solo uno tiene faltas, ese va primero
                      if (faultsA.isNotEmpty) return -1;
                      if (faultsB.isNotEmpty) return 1;

                      // Si ninguno tiene faltas, ordenar por nombre
                      return a.name.compareTo(b.name);
                    });
                  } else {
                    // Para el filtro "Todos", ordenar por cantidad de faltas (pero no reordenar otros filtros)
                    if (_currentFilter == WorkerFilter.all) {
                      // Primero ordenar por cantidad de faltas (descendente)
                      workers.sort((a, b) => b.failures.compareTo(a.failures));
                    }
                  }

                  // Aplicar filtro de búsqueda sobre el resultado anterior
                  final filteredWorkers = _searchQuery.isEmpty
                      ? workers
                      : workers
                          .where((worker) =>
                              worker.name
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              worker.area
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              worker.document
                                  .toLowerCase()
                                  .contains(_searchQuery))
                          .toList();

                  if (filteredWorkers.isEmpty) {
                    return WorkerEmptyState(searchQuery: _searchQuery);
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 5, bottom: 100),
                      itemCount: filteredWorkers.length,
                      itemBuilder: (context, index) {
                        final worker = filteredWorkers[index];
                        final specialtyColor = getColorArea(worker.idArea);

                        return WorkerListItem(
                          worker: worker,
                          specialtyColor: specialtyColor,
                          onTap: () => _showWorkerDetails(
                              context, worker, specialtyColor),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          user.cargo == "GESTION HUMANA" || user.cargo == "ADMON PLATAFORMA"
              ? NeumorphicFloatingActionButton(
                  style: NeumorphicStyle(
                    color: const Color(0xFF4299E1),
                    shape: NeumorphicShape.flat,
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(28)),
                    depth: 8,
                    intensity: 0.65,
                    lightSource: LightSource.topLeft,
                  ),
                  child: const Icon(
                    Icons.person_add,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    WorkerAddDialog.show(
                      context,
                      _addWorker,
                    );
                  },
                )
              : null,
    );
  }

  // Añade este método para manejar cambios en el filtro
  void _handleFilterChanged(WorkerFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
  }

  void _showWorkerDetails(
      BuildContext context, Worker worker, Color specialtyColor) {
    // Si estamos en el filtro de faltas, mostrar un diálogo especializado con información de faltas
    if (_currentFilter == WorkerFilter.faults) {
      _showWorkerFaultsDetails(context, worker, specialtyColor);
    } else {
      // Mostrar el diálogo normal
      showDialog(
        context: context,
        builder: (context) => WorkerDetailDialog(
          worker: worker,
          isAssigned: worker.status == WorkerStatus.assigned,
          specialtyColor: specialtyColor,
          onUpdateWorker: _updateWorker,
        ),
      );
    }
  }

  // Método para mostrar detalles de faltas de un trabajador
  void _showWorkerFaultsDetails(
      BuildContext context, Worker worker, Color specialtyColor) {
    final faultsProvider = Provider.of<FaultsProvider>(context, listen: false);

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Cargar las faltas del trabajador
    List<Fault> faults = faultsProvider.fetchFaultsByWorker(context, worker.id);
    // debugPrint('Faltas cargadas: ${faults.length}');

    // Quitar indicador de carga
    Navigator.of(context).pop();

    // Variable para el tipo de falta seleccionado
    FaultType? selectedFaultType;

    // Mostrar diálogo con faltas
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          // Filtrar faltas según el tipo seleccionado
          final filteredFaults = selectedFaultType == null
              ? faults
              : faults.where((f) => f.type == selectedFaultType).toList();

          filteredFaults.sort((a, b) => b.createdAt.compareTo(a
              .createdAt)); // Ordenar por fecha de creación (más reciente primero)

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera con información del trabajador (código existente)
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: specialtyColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            worker.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: specialtyColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              worker.document,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // NUEVO: Añadir filtros por tipo de falta
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFaultTypeChip(
                          'Todas',
                          null,
                          selectedFaultType,
                          (type) => setState(() => selectedFaultType = type),
                        ),
                        _buildFaultTypeChip(
                          'Inasistencia',
                          FaultType.INASSISTANCE,
                          selectedFaultType,
                          (type) => setState(() => selectedFaultType = type),
                          color: const Color(0xFFE53E3E),
                          icon: Icons.event_busy,
                        ),
                        _buildFaultTypeChip(
                          'Abandono',
                          FaultType.ABANDONMENT,
                          selectedFaultType,
                          (type) => setState(() => selectedFaultType = type),
                          color: const Color(0xFFED8936),
                          icon: Icons.exit_to_app,
                        ),
                        _buildFaultTypeChip(
                          'Falta de Respeto',
                          FaultType.IRRESPECTFUL,
                          selectedFaultType,
                          (type) => setState(() => selectedFaultType = type),
                          color: const Color(0xFF805AD5),
                          icon: Icons.sentiment_very_dissatisfied,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Estadísticas de faltas (actualizado para mostrar tipo filtrado)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedFaultType == null
                              ? 'Faltas acumuladas:'
                              : 'Faltas de este tipo:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${filteredFaults.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lista de faltas filtradas
                  Expanded(
                    child: filteredFaults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  selectedFaultType == null
                                      ? 'No hay faltas registradas'
                                      : 'No hay faltas de este tipo',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredFaults.length,
                            itemBuilder: (context, index) {
                              final fault = filteredFaults[index];

                              // Determinar el tipo de falta
                              IconData icon;
                              Color color;
                              String typeText;

                              switch (fault.type) {
                                case FaultType.INASSISTANCE:
                                  icon = Icons.event_busy;
                                  color = const Color(0xFFE53E3E);
                                  typeText = 'Inasistencia';
                                  break;
                                case FaultType.ABANDONMENT:
                                  icon = Icons.exit_to_app;
                                  color = const Color(0xFFED8936);
                                  typeText = 'Abandono';
                                  break;
                                case FaultType.IRRESPECTFUL:
                                  icon = Icons.sentiment_very_dissatisfied;
                                  color = const Color(0xFF805AD5);
                                  typeText = 'Falta de Respeto';
                                  break;
                              }

                              // Obtener fecha
                              final date = fault.createdAt;
                              final formattedDate =
                                  DateFormat('dd/MM/yyyy').format(date);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: color.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(icon, color: color, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            typeText,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            formattedDate,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      fault.description,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Método para crear chips de filtro por tipo de falta
  Widget _buildFaultTypeChip(
    String label,
    FaultType? type,
    FaultType? selectedType,
    Function(FaultType?) onSelected, {
    Color? color,
    IconData? icon,
  }) {
    final isSelected = selectedType == type;

    return GestureDetector(
      onTap: () => onSelected(type),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? Colors.blue).withOpacity(0.2)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? (color ?? Colors.blue) : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? (color ?? Colors.blue) : Colors.grey[600],
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? (color ?? Colors.blue) : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addWorker(Worker workerData) {
    final workersProvider =
        Provider.of<WorkersProvider>(context, listen: false);

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Llamar al método addWorker y manejar el resultado
    workersProvider.addWorker(workerData, context).then((result) {
      // Cerrar indicador de carga
      Navigator.of(context).pop();

      if (result['success']) {
        // Mostrar notificación de éxito
        showSuccessToast(context, result['message']);
      } else {
        // Mostrar notificación de error
        showErrorToast(context, result['message']);
      }
    });
  }

  void _updateWorker(Worker oldWorker, Worker newWorker) {
    final workersProvider =
        Provider.of<WorkersProvider>(context, listen: false);
    workersProvider.updateWorker(oldWorker, newWorker, context);
  }
}
