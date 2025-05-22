import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/hooks/loaders/loader.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/dashboard/quickActions.dart';
import 'package:plannerop/widgets/dashboard/recentOps.dart';
import 'package:plannerop/store/workers.dart';
import 'package:provider/provider.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _isLoadingWorkers = false;
  bool _isLoadingAreas = false;
  bool _isLoadingTasks = false;
  bool _isLoadingClients = false;
  bool _isLoadingAssignments = false;
  bool _isLoadingFaults = false;
  bool _isLoadingChargers = false;

  @override
  void initState() {
    super.initState();
    // Evitar multiples cargas simultáneas
    bool isLoading = false;

    // Usar addPostFrameCallback para programar la carga después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!isLoading) {
        isLoading = true;
        await Future.wait([
          checkAndLoadWorkersIfNeeded(
            mounted,
            setState,
            _isLoadingWorkers,
            context,
          ),
          loadAreas(
            mounted,
            setState,
            _isLoadingAreas,
            context,
          ),
          loadTask(
            mounted,
            setState,
            _isLoadingTasks,
            context,
          ),
          loadClients(
            mounted,
            setState,
            _isLoadingClients,
            context,
          ),
          loadAssignments(
            context: context,
            isMounted: () => mounted, // Retorna el valor actual de mounted
            setStateCallback: (fn) {
              if (mounted) setState(fn);
            },
            updateLoadingState: (isLoading) {
              _isLoadingAssignments = isLoading;
            },
          ),
          loadFaults(
            context: context,
            isMounted: () => mounted, // Retorna el valor actual de mounted
            setStateCallback: (fn) {
              if (mounted) setState(fn);
            },
            updateLoadingState: (isLoading) {
              _isLoadingFaults = isLoading;
            },
          ),
          loadChargersOp(
            context: context,
            isMounted: () => mounted, // Retorna el valor actual de mounted
            setStateCallback: (fn) {
              if (mounted) setState(fn);
            },
            updateLoadingState: (isLoading) {
              _isLoadingChargers = isLoading;
            },
          ),
        ]).catchError((error) {
          debugPrint('Error durante la carga en paralelo: $error');
          // Continuar aunque haya errores
        });
      }
    });
  }

  Future<void> _loadWorkers() async {
    if (!mounted) return;

    setState(() {
      _isLoadingWorkers = true;
    });

    final workersProvider =
        Provider.of<WorkersProvider>(context, listen: false);

    try {
      // Intentar cargar desde la API usando el método que respeta el flag
      // debugPrint('Cargando trabajadores desde API..++++.');
      await workersProvider.fetchWorkersIfNeeded(context);

      // Si después de intentar cargar no hay datos, añadir datos de muestra
      if (workersProvider.workers.isEmpty) {}
    } catch (e) {
      // Si algo falla, cargar datos de muestra

      // Mostrar un mensaje de error
      if (mounted) {
        showErrorToast(context, 'Error al cargar trabajadores.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWorkers = false;
        });
      }
    }
  }

  Future<void> _loadAssignments() async {
    if (!mounted) return;

    // Configurar un timeout para evitar carga infinita
    final loadingTimeout = Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoadingAssignments) {
        debugPrint('⚠️ Timeout en carga de asignaciones');
        setState(() {
          _isLoadingAssignments = false;
        });
        // Desactivar loading en el provider también
        Provider.of<AssignmentsProvider>(context, listen: false)
            .changeIsLoadingOff();
        showAlertToast(
            context, 'La carga de datos está tomando demasiado tiempo');
      }
    });

    // No mostrar indicador de carga si ya hay datos disponibles
    final assignmentsProvider =
        Provider.of<AssignmentsProvider>(context, listen: false);
    final hasExistingData = assignmentsProvider.assignments.isNotEmpty;

    if (!hasExistingData) {
      setState(() {
        _isLoadingAssignments = true;
      });
    }

    try {
      // Cargar asignaciones con prioridad
      await assignmentsProvider.loadAssignmentsWithPriority(context);
    } catch (e) {
      debugPrint('Error al cargar asignaciones: $e');

      if (mounted && !hasExistingData) {
        showErrorToast(context, 'Error al cargar asignaciones.');
      }
    } finally {
      // Asegurar que el estado de carga se desactive siempre al finalizar
      if (mounted) {
        setState(() {
          _isLoadingAssignments = false;
        });
        // Asegurar que el provider también deshabilite su indicador de carga
        assignmentsProvider.changeIsLoadingOff();
      }
    }

    // No necesitamos esperar el timeout
  }

  @override
  Widget build(BuildContext context) {
    // Obtener la altura de la barra de estado
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nueva cabecera elegante con gradiente
          Container(
            padding: EdgeInsets.fromLTRB(20, 20 + statusBarHeight, 20, 30),
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
              boxShadow: [
                BoxShadow(
                  color: Color(0x29000000),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila superior con título y botón de actualización
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        // Indicador de carga si es necesario
                        if (_isLoadingAreas ||
                            _isLoadingWorkers ||
                            _isLoadingAssignments)
                          Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 20,
                            height: 20,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        // Botón de actualización
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _isLoadingAreas ||
                                  _isLoadingWorkers ||
                                  _isLoadingAssignments
                              ? null
                              : () async {
                                  try {
                                    if (!mounted) {
                                      return;
                                    }

                                    setState(() {
                                      _isLoadingWorkers = true;
                                      _isLoadingAreas = true;
                                      _isLoadingAssignments = true;
                                    });
                                    // Al refrescar manualmente, forzamos la recarga de todo
                                    await _loadWorkers();
                                    await loadAreas(
                                      mounted,
                                      setState,
                                      _isLoadingAreas,
                                      context,
                                    );
                                    await _loadAssignments();

                                    if (!mounted) {
                                      return;
                                    }

                                    // Forzar actualización final
                                    setState(() {
                                      _isLoadingWorkers = false;
                                      _isLoadingAreas = false;
                                      _isLoadingAssignments = false;
                                    });
                                  } catch (e) {
                                    // Forzar actualización final
                                    setState(() {
                                      _isLoadingWorkers = false;
                                      _isLoadingAreas = false;
                                      _isLoadingAssignments = false;
                                    });
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Subtítulo
                Text(
                  'Resumen de tus operaciones',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),

                const SizedBox(height: 15),

                // Tarjeta de resumen rápido
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Operaciones pendientes
                      _buildQuickStatItem(
                          context,
                          Icons.pending_actions_outlined,
                          'Pendientes',
                          Provider.of<AssignmentsProvider>(context)
                              .pendingAssignments
                              .length
                              .toString()),
                      // Contador de operaciones en curso
                      _buildQuickStatItem(
                          context,
                          Icons.directions_run,
                          'En Curso',
                          Provider.of<AssignmentsProvider>(context)
                              .inProgressAssignments
                              .length
                              .toString()),
                      // Contador de asignaciones finalizadas
                      _buildQuickStatItem(
                          context,
                          Icons.check_circle_outline,
                          'Finalizadas',
                          Provider.of<AssignmentsProvider>(context)
                              .completedAssignments
                              .where((a) =>
                                  a.endDate?.month == DateTime.now().month &&
                                  a.endDate?.day == DateTime.now().day &&
                                  a.endDate?.year == DateTime.now().year)
                              .length
                              .toString()),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenido del dashboard
          Expanded(
            child: _isLoadingWorkers
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Cargando datos...',
                          style: TextStyle(
                            color: Color(0xFF718096),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      // Recargar datos al hacer pull-to-refresh
                      await Future.wait([
                        _loadWorkers(),
                        loadAreas(
                          mounted,
                          setState,
                          _isLoadingAreas,
                          context,
                        ),
                        _loadAssignments(),
                      ]);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            QuickActions(),
                            const SizedBox(height: 24),
                            RecentOps(),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar un elemento de estadística rápida
  Widget _buildQuickStatItem(
      BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
