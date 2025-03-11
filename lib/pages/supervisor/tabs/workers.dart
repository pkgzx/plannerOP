import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/widgets/workers/worker_list_item.dart';
import 'package:plannerop/widgets/workers/worker_add_dialog.dart';
import 'package:plannerop/widgets/workers/worker_detail_dialog.dart';
import 'package:plannerop/widgets/workers/worker_empty_state.dart';
import 'package:plannerop/pages/supervisor/tabs/worker_filter.dart'; // Importa el WorkerFilter
import 'package:plannerop/widgets/workers/worker_stats.dart';

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

  @override
  Widget build(BuildContext context) {
    // Simplemente consume el WorkersProvider que debe estar proporcionado desde un nivel superior

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
                  totalWorkers: workersProvider.totalWorkers,
                  assignedWorkers: workersProvider.assignedWorkers,
                  currentFilter: _currentFilter,
                  disabledWorkers: workersProvider.disabledWorkers,
                  retiredWorkers: workersProvider.retiredWorkers,
                  onFilterChanged:
                      _handleFilterChanged, // Pasar el callback de cambio de filtro
                );
              },
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
                      workers = workersProvider.workers.toList();
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
                      break;
                    default:
                      workers = workersProvider.workers.toList();
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
                        final specialtyColor =
                            workersProvider.getColorForArea(worker.area);

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
      floatingActionButton: NeumorphicFloatingActionButton(
        style: NeumorphicStyle(
          color: const Color(0xFF4299E1),
          shape: NeumorphicShape.flat,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(28)),
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
      ),
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
