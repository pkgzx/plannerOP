import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/store/clients.dart';
import 'package:plannerop/store/faults.dart';
import 'package:plannerop/store/task.dart';
import 'package:plannerop/utils/backgroundDataLoader.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/quickActions.dart';
import 'package:plannerop/widgets/recentOps.dart';
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
  bool _isMounted = true;
  // Variable para controlar si ya hemos iniciado las cargas
  bool _hasStartedLoading = false;

  final BackgroundDataLoader _backgroundLoader = BackgroundDataLoader();

  // Sobreescribir para mantener el estado del widget entre cambios de tab
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Evitar multiples cargas simultáneas
    bool isLoading = false;
    _isMounted = true;

    _startBackgroundLoading();

    // Usar addPostFrameCallback para programar la carga después del primer frame
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   if (!isLoading) {
    //     isLoading = true;
    //     await Future.wait([
    //       _checkAndLoadWorkersIfNeeded(),
    //       _loadAreas(),
    //       _loadTask(),
    //       _loadClients(),
    //       _loadAssignments(),
    //       _loadChargersOp(),
    //     ]).catchError((error) {
    //       debugPrint('Error durante la carga en paralelo: $error');
    //       // Continuar aunque haya errores
    //     });

    //     _loadFaults();
    //   }
    // });

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _loadDataInBackground();
    // });
  }

  void _startBackgroundLoading() {
    // Estas cargas no dependen del estado del widget
    _backgroundLoader.loadData('workers', () async {
      final workersProvider =
          Provider.of<WorkersProvider>(context, listen: false);
      await workersProvider.fetchWorkersIfNeeded(context);
      return;
    });

    _backgroundLoader.loadData('areas', () async {
      final areasProvider = Provider.of<AreasProvider>(context, listen: false);
      await areasProvider.fetchAreas(context);
      return;
    });

    _backgroundLoader.loadData('assignments', () async {
      final assignmentsProvider =
          Provider.of<AssignmentsProvider>(context, listen: false);
      await assignmentsProvider.loadAssignmentsWithPriority(context);
      return;
    });

    _backgroundLoader.loadData('tasks', () async {
      final tasksProvider = Provider.of<TasksProvider>(context, listen: false);
      await tasksProvider.loadTasksIfNeeded(context);
      return;
    });

    _backgroundLoader.loadData('clients', () async {
      final clientsProvider =
          Provider.of<ClientsProvider>(context, listen: false);
      await clientsProvider.fetchClients(context);
      return;
    });

    _backgroundLoader.loadData('chargers', () async {
      final chargersProvider =
          Provider.of<ChargersOpProvider>(context, listen: false);
      await chargersProvider.fetchChargers(context);
      return;
    });

    _backgroundLoader.loadData('faults', () async {
      final faultsProvider =
          Provider.of<FaultsProvider>(context, listen: false);
      await faultsProvider.fetchFaults(context);
      return;
    });
  }

  @override
  void dispose() {
    // Marcar que el widget ya no está montado para evitar actualizaciones de estado
    _isMounted = false;
    super.dispose();
  }

  // void _loadDataInBackground() async {
  //   // Cargar datos esenciales primero
  //   await Future.wait([
  //     _loadAreas(),
  //     _loadAssignments(),
  //     _checkAndLoadWorkersIfNeeded(),
  //   ]).catchError((error) {
  //     debugPrint('Error durante la carga esencial: $error');
  //   });

  //   // Luego cargar datos secundarios si el widget sigue montado
  //   if (_isMounted) {
  //     // dar prioridad altisima a la carga de trabajadores
  //     Future.sync(() async {
  //       await Future.wait([
  //         _loadTask(),
  //         _loadClients(),
  //         _loadChargersOp(),
  //       ]).catchError((error) {
  //         debugPrint('Error durante la carga secundaria: $error');
  //       });
  //     });
  //   }
  // }

  Future<void> _loadChargersOp() async {
    // if (!mounted) return;

    setState(() {
      _isLoadingChargers = true;
    });

    try {
      final chargersOpProvider =
          Provider.of<ChargersOpProvider>(context, listen: false);

      await chargersOpProvider.fetchChargers(context);
    } catch (e) {
      debugPrint('Error al cargar cargadores: $e');

      if (mounted) {
        showErrorToast(context, "Error al cargar cargadores.");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingChargers = false;
        });
      }
    }
  }

  // Método para verificar si necesitamos cargar trabajadores
  Future<void> _checkAndLoadWorkersIfNeeded() async {
    // if (!mounted) return;

    final workersProvider =
        Provider.of<WorkersProvider>(context, listen: false);

    final faultsProvider = Provider.of<FaultsProvider>(context, listen: false);

    // Solo cargaremos si no se han cargado antes
    if (!workersProvider.hasLoadedInitialData) {
      await _loadWorkers();
    }

    if (!faultsProvider.hasLoadedInitialData) {
      // debugPrint('Cargando faltas....................');
      _loadFaults();
    }
  }

  Future<void> _loadAreas() async {
    // if (!mounted) return;

    final areasProvider = Provider.of<AreasProvider>(context, listen: false);

    // Verificar si ya hay áreas cargadas
    if (areasProvider.areas.isNotEmpty) {
      // debugPrint(
      //     'Áreas ya cargadas anteriormente: ${areasProvider.areas.length}');
      return;
    }

    // debugPrint('Iniciando carga de áreas desde API...');

    // Mostrar indicador de carga para áreas
    setState(() {
      _isLoadingAreas = true;
    });

    try {
      // Llamar al método fetchAreas con await para asegurar que se complete
      await areasProvider.fetchAreas(context);

      // Verificar si se cargaron áreas
      if (areasProvider.areas.isNotEmpty) {
        // debugPrint(
        //     'Áreas cargadas con éxito: ${areasProvider.areas.length} áreas');
      } else {
        // debugPrint('No se cargaron áreas o la lista está vacía');

        // Si no hay áreas, cargar algunas predeterminadas
        _loadDefaultAreas(areasProvider);
      }
    } catch (e, stackTrace) {
      debugPrint('Error al cargar áreas: $e');
      debugPrint('Stack trace: $stackTrace');

      // Cargar áreas predeterminadas en caso de error
      _loadDefaultAreas(areasProvider);

      // Mostrar un mensaje de error más informativo
      if (mounted) {
        showErrorToast(context, "Error al cargar áreas.");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAreas = false;
        });
      }
    }
  }

  Future<void> _loadTask() async {
    // if (!mounted) return;

    setState(() {
      _isLoadingTasks = true;
    });

    try {
      final tasksProvider = Provider.of<TasksProvider>(context, listen: false);

      // Si ya se ha intentado cargar o ya hay tareas, no hacemos nada
      if (tasksProvider.hasAttemptedLoading || tasksProvider.tasks.isNotEmpty) {
        // debugPrint('Tareas ya cargadas o intento previo realizado.');
        return;
      }

      await tasksProvider.loadTasks(context);

      // Verificar resultado después de la carga
      if (tasksProvider.tasks.isEmpty) {
        debugPrint('La API devolvió una lista vacía de tareas.');
        // Esto ahora lo hace automáticamente el provider
        // _loadDefaultTasks(tasksProvider);
      } else {
        debugPrint('Tareas cargadas con éxito: ${tasksProvider.tasks.length}');
      }
    } catch (e) {
      debugPrint('Error al cargar tareas: $e');

      // En caso de error, mostramos una notificación
      if (mounted) {
        showErrorToast(context, 'Error al cargar tareas.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTasks = false;
        });
      }
    }
  }

  Future<void> _loadAssignments() async {
    // 1. Verificar si el widget está montado al inicio
    if (!_isMounted) return;

    // 2. Usar un Completer para manejar el timeout
    var timeoutCompleter = Completer<void>();
    var hasTimedOut = false;

    // 3. Extraer el provider para usarlo independientemente del estado del widget
    final assignmentsProvider =
        Provider.of<AssignmentsProvider>(context, listen: false);
    final hasExistingData = assignmentsProvider.assignments.isNotEmpty;

    // 4. Solo actualizar UI si estamos montados
    if (!hasExistingData && _isMounted) {
      setState(() {
        _isLoadingAssignments = true;
      });
    } else {
      // Aun así marcar como cargando para la lógica interna
      _isLoadingAssignments = true;
    }

    // 5. Configurar timeout con cancelación segura
    var timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (_isMounted && _isLoadingAssignments) {
        hasTimedOut = true;
        _isLoadingAssignments = false;
        assignmentsProvider.changeIsLoadingOff();

        if (_isMounted) {
          setState(() {});
          showAlertToast(
              context, 'La carga de datos está tomando demasiado tiempo');
        }

        if (!timeoutCompleter.isCompleted) {
          timeoutCompleter.complete();
        }
      }
    });

    try {
      // 6. Cargar datos con el provider (esto es independiente del estado UI)
      await assignmentsProvider.loadAssignmentsWithPriority(context);

      // Cancelar el timeout ya que terminamos exitosamente
      timeoutTimer.cancel();

      if (assignmentsProvider.assignments.isNotEmpty) {
        debugPrint(
            'Operaciones cargadas exitosamente: ${assignmentsProvider.assignments.length}');
      } else {
        debugPrint('No se cargaron asignaciones o la lista está vacía');
      }
    } catch (e) {
      // Cancelar el timeout en caso de error
      timeoutTimer.cancel();

      debugPrint('Error al cargar asignaciones: $e');

      // 7. Verificar estado de montado antes de mostrar errores en UI
      if (_isMounted && !hasExistingData && !hasTimedOut) {
        showErrorToast(context, 'Error al cargar asignaciones.');
      }
    } finally {
      // 8. Cancelar el timer para evitar memory leaks
      timeoutTimer.cancel();

      // 9. Actualizar estado independientemente del estado de UI
      _isLoadingAssignments = false;
      assignmentsProvider.changeIsLoadingOff();

      // 10. Solo actualizar UI si estamos montados y no ha ocurrido timeout
      if (_isMounted && !hasTimedOut) {
        setState(() {});
      }
    }
  }

  Future<void> _loadFaults() async {
    final faultsProvider = Provider.of<FaultsProvider>(context, listen: false);

    // Solo actualizar UI si estamos montados
    if (mounted) {
      setState(() {
        _isLoadingFaults = true;
      });
    } else {
      // Aun así cambiar la variable de estado
      _isLoadingFaults = true;
    }

    try {
      await faultsProvider.fetchFaults(context);
      // debugPrint('Faltas cargadas exitosamente');
    } catch (e) {
      debugPrint('Error al cargar faltas: $e');

      if (mounted) {
        showErrorToast(context, "Error al cargar faltas.");
      }
    } finally {
      _isLoadingFaults = false;

      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadWorkers() async {
    final workersProvider =
        Provider.of<WorkersProvider>(context, listen: false);

    // Solo actualizar UI si estamos montados
    if (mounted) {
      setState(() {
        _isLoadingWorkers = true;
      });
    } else {
      _isLoadingWorkers = true;
    }

    try {
      await workersProvider.fetchWorkersIfNeeded(context);
    } catch (e) {
      debugPrint('Error al cargar trabajadores: $e');

      if (mounted) {
        showErrorToast(context, 'Error al cargar trabajadores.');
      }
    } finally {
      _isLoadingWorkers = false;

      if (mounted) {
        setState(() {});
      }
    }
  }

  // Método auxiliar para cargar áreas predeterminadas
  void _loadDefaultAreas(AreasProvider areasProvider) {
    // Verificar si el AreasProvider tiene un método para agregar áreas predeterminadas
    if (areasProvider.areas.isEmpty) {
      debugPrint(
          'Se cargaron áreas predeterminadas: ${areasProvider.areas.length} áreas');
    }
  }

  Future<bool> _loadClients() async {
    // if (!mounted) return false;

    final clientsProvider =
        Provider.of<ClientsProvider>(context, listen: false);

    // Si ya se han cargado clientes, no hacer nada
    if (clientsProvider.clients.isNotEmpty) {
      // debugPrint('Clientes ya cargados: ${clientsProvider.clients.length}');
      return true;
    }

    // debugPrint('Iniciando carga de clientes desde API...');

    if (mounted) {
      setState(() {
        _isLoadingClients = true;
      });
    } else {
      // Actualizar la variable de estado aunque no actualicemos la UI
      _isLoadingClients = true;
    }

    try {
      await clientsProvider.fetchClients(context);

      if (clientsProvider.clients.isNotEmpty) {
        // debugPrint(
        // 'Clientes cargados con éxito: ${clientsProvider.clients.length}');
        return true;
      } else {
        debugPrint('No se cargaron clientes o la lista está vacía');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error al cargar clientes: $e');
      debugPrint('Stack trace: $stackTrace');

      // Mostrar un mensaje de error más informativo
      if (mounted) {
        showErrorToast(context, 'Error al cargar clientes.');
      }

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingClients = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener la altura de la barra de estado
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;

    // Verificar si los datos principales están cargando o no han cargado
    bool isLoadingMainData = _backgroundLoader.isLoading('workers') ||
        _backgroundLoader.isLoading('assignments') ||
        _backgroundLoader.isLoading('areas');

    // El resto del código de build...

    // Para mostrar el indicador de carga
    if (_backgroundLoader.isLoading('workers') ||
        _backgroundLoader.isLoading('assignments') ||
        _backgroundLoader.isLoading('areas')) {
      // Mostrar indicador de carga
    }

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
                        // IconButton(
                        //   icon: const Icon(Icons.refresh, color: Colors.white),
                        //   onPressed: _isLoadingAreas ||
                        //           _isLoadingWorkers ||
                        //           _isLoadingAssignments
                        //       ? null
                        //       : () async {
                        //           setState(() {
                        //             _isLoadingWorkers = true;
                        //             _isLoadingAreas = true;
                        //             _isLoadingAssignments = true;
                        //           });
                        //           // Al refrescar manualmente, forzamos la recarga de todo
                        //           await _loadWorkers();
                        //           await _loadAreas();
                        //           await _loadAssignments();

                        //           // Forzar actualización final
                        //           setState(() {
                        //             _isLoadingWorkers = false;
                        //             _isLoadingAreas = false;
                        //             _isLoadingAssignments = false;
                        //           });
                        //         },
                        // ),

                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: isLoadingMainData
                              ? null
                              : () {
                                  // Recargar datos en segundo plano
                                  _startBackgroundLoading();
                                  if (_isMounted) {
                                    setState(
                                        () {}); // Solo para forzar un rebuild
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
                        _loadAreas(),
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
