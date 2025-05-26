import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/store/clients.dart';
import 'package:plannerop/store/faults.dart';
import 'package:plannerop/store/programmings.dart';
import 'package:plannerop/store/task.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:provider/provider.dart';

Future<void> loadChargersOp({
  required BuildContext context,
  required bool Function() isMounted, // Función que verifica el valor actual
  required void Function(void Function())
      setStateCallback, // Función para llamar setState
  required void Function(bool)
      updateLoadingState, // Función para actualizar el estado de carga
}) async {
  if (!isMounted()) return;

  // Actualizar estado de carga a true
  setStateCallback(() => updateLoadingState(true));

  try {
    final chargersOpProvider =
        Provider.of<ChargersOpProvider>(context, listen: false);
    await chargersOpProvider.fetchChargers(context);
  } catch (e) {
    debugPrint('Error al cargar cargadores: $e');
    if (isMounted()) {
      showErrorToast(context, "Error al cargar cargadores.");
    }
  } finally {
    if (isMounted()) {
      setStateCallback(() => updateLoadingState(false));
    }
  }
}

// Método para cargar faltas (similar a los otros métodos de carga)
Future<void> loadFaults({
  required BuildContext context,
  required bool Function() isMounted, // Función que verifica el valor actual
  required void Function(void Function())
      setStateCallback, // Función para llamar setState
  required void Function(bool)
      updateLoadingState, // Función para actualizar el estado de carga
}) async {
  if (!isMounted()) return;

  // Actualizar estado de carga a true
  setStateCallback(() => updateLoadingState(true));

  try {
    final faultsProvider = Provider.of<FaultsProvider>(context, listen: false);

    await faultsProvider.fetchFaults(context);
  } catch (e) {
    debugPrint('Error al cargar cargadores: $e');
    if (isMounted()) {
      showErrorToast(context, "Error al cargar cargadores.");
    }
  } finally {
    if (isMounted()) {
      setStateCallback(() => updateLoadingState(false));
    }
  }
}

// Método para verificar si necesitamos cargar trabajadores
Future<void> checkAndLoadWorkersIfNeeded(
  bool mounted,
  Function setState,
  bool isLoadingWorkers,
  BuildContext context,
) async {
  if (!mounted) return;

  final workersProvider = Provider.of<WorkersProvider>(context, listen: false);

  // Solo cargaremos si no se han cargado antes
  if (!workersProvider.hasLoadedInitialData) {
    await _loadWorkers(
      mounted,
      setState,
      isLoadingWorkers,
      context,
    );
  }
}

Future<void> _loadWorkers(
  bool mounted,
  Function setState,
  bool isLoadingWorkers,
  BuildContext context,
) async {
  if (!mounted) return;

  setState(() {
    isLoadingWorkers = true;
  });

  final workersProvider = Provider.of<WorkersProvider>(context, listen: false);

  try {
    // Intentar cargar desde la API usando el método que respeta el flag
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
        isLoadingWorkers = false;
      });
    }
  }
}

Future<void> loadAreas(
  bool mounted,
  Function setState,
  bool isLoadingAreas,
  BuildContext context,
) async {
  if (!mounted) return;

  final areasProvider = Provider.of<AreasProvider>(context, listen: false);

  // Verificar si ya hay áreas cargadas
  if (areasProvider.areas.isNotEmpty) {
    // debugPrint(
    //     'Áreas ya cargadas anteriormente: ${areasProvider.areas.length}');
    return;
  }

  // Mostrar indicador de carga para áreas
  setState(() {
    isLoadingAreas = true;
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
    }
  } catch (e, stackTrace) {
    debugPrint('Error al cargar áreas: $e');
    debugPrint('Stack trace: $stackTrace');

    // Mostrar un mensaje de error más informativo
    if (mounted) {
      showErrorToast(context, "Error al cargar áreas.");
    }
  } finally {
    if (mounted) {
      setState(() {
        isLoadingAreas = false;
      });
    }
  }
}

Future<void> loadTask(
  bool mounted,
  Function setState,
  bool isLoadingTasks,
  BuildContext context,
) async {
  if (!mounted) return;

  setState(() {
    isLoadingTasks = true;
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
        isLoadingTasks = false;
      });
    }
  }
}

Future<void> loadAssignments({
  required BuildContext context,
  required bool Function() isMounted, // Función que verifica el valor actual
  required void Function(void Function())
      setStateCallback, // Función para llamar setState
  required void Function(bool)
      updateLoadingState, // Función para actualizar el estado de carga
}) async {
  if (!isMounted()) return;

  // Actualizar estado de carga a true
  setStateCallback(() => updateLoadingState(true));

  // Configurar un timeout para evitar carga infinita
  final loadingTimeout = Future.delayed(const Duration(seconds: 10), () {
    if (isMounted()) {
      debugPrint('⚠️ Timeout en carga de asignaciones');
      setStateCallback(() {
        updateLoadingState(false);
      });
      // Desactivar loading en el provider también
      Provider.of<AssignmentsProvider>(context, listen: false)
          .changeIsLoadingOff();
      // showAlertToast(
      //     context, 'La carga de datos está tomando demasiado tiempo');
    }
  });

  loadingTimeout.then((_) {
    if (isMounted()) {
      // debugPrint('Carga de asignaciones completada');
    }
  });
  // No mostrar indicador de carga si ya hay datos disponibles
  final assignmentsProvider =
      Provider.of<AssignmentsProvider>(context, listen: false);
  final hasExistingData = assignmentsProvider.assignments.isNotEmpty;

  if (!hasExistingData) {
    setStateCallback(() {
      updateLoadingState(true);
    });
  }

  try {
    // Cargar asignaciones con prioridad
    await assignmentsProvider.loadAssignmentsWithPriority(context);

    if (assignmentsProvider.assignments.isNotEmpty) {
    } else {
      debugPrint('No se cargaron asignaciones o la lista está vacía');
    }
  } catch (e) {
    debugPrint('Error al cargar asignaciones: $e');

    if (isMounted() && !hasExistingData) {
      showErrorToast(context, 'Error al cargar asignaciones.');
    }
  } finally {
    // Asegurar que el estado de carga se desactive siempre al finalizar
    if (isMounted()) {
      setStateCallback(() {
        updateLoadingState(false);
      });
      // Asegurar que el provider también deshabilite su indicador de carga
      assignmentsProvider.changeIsLoadingOff();
    }
  }
}

Future<bool> loadClients(
  bool mounted,
  Function setState,
  bool isLoadingClients,
  BuildContext context,
) async {
  if (!mounted) return false;

  final clientsProvider = Provider.of<ClientsProvider>(context, listen: false);

  // Si ya se han cargado clientes, no hacer nada
  if (clientsProvider.clients.isNotEmpty) {
    debugPrint('Clientes ya cargados: ${clientsProvider.clients.length}');
    return true;
  }

  setState(() {
    isLoadingClients = true;
  });

  try {
    await clientsProvider.fetchClients(context);

    if (clientsProvider.clients.isNotEmpty) {
      debugPrint(
          'Clientes cargados con éxito: ${clientsProvider.clients.length}');
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
        isLoadingClients = false;
      });
    }
  }
}

Future<void> loadClientProgramming(
  bool mounted,
  Function setState,
  bool isLoadingClientProgramming,
  BuildContext context,
) async {
  if (!mounted) return;

  final programmingsProvider =
      Provider.of<ProgrammingsProvider>(context, listen: false);

  // Si ya se han cargado clientes, no hacer nada
  if (programmingsProvider.programmings.isNotEmpty) {
    debugPrint(
        'Clientes ya cargados: ${programmingsProvider.programmings.length}');
    return;
  }

  setState(() {
    isLoadingClientProgramming = true;
  });

  final DateTime now = DateTime.now();
  final String formattedDate = DateFormat('yyyy-MM-dd').format(now);

  try {
    await programmingsProvider.fetchProgrammingsByDate(formattedDate, context);

    if (programmingsProvider.programmings.isNotEmpty) {
      debugPrint(
          'Programaciones cargadas con éxito: ${programmingsProvider.programmings.length}');
    } else {
      debugPrint('No se cargaron programaciones o la lista está vacía');
    }
  } catch (e, stackTrace) {
    debugPrint('Error al cargar programaciones: $e');
    debugPrint('Stack trace: $stackTrace');

    // Mostrar un mensaje de error más informativo
    if (mounted) {
      showErrorToast(context, 'Error al cargar programaciones.');
    }
  } finally {
    if (mounted) {
      setState(() {
        isLoadingClientProgramming = false;
      });
    }
  }
}
