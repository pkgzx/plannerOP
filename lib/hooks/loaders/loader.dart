import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/operations.dart';
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
  required bool Function() isMounted,
  required void Function(void Function())?
      setStateCallback, // Función para llamar setState
  required void Function(bool)?
      updateLoadingState, // Función para actualizar el estado de carga
}) async {
  if (!isMounted()) return;

  if (setStateCallback != null && updateLoadingState != null) {
    // Actualizar estado de carga a true
    setStateCallback(() => updateLoadingState(true));
  }
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
      if (setStateCallback != null && updateLoadingState != null) {
        // Actualizar estado de carga a false
        setStateCallback(() => updateLoadingState(false));
      }
    }
  }
}

// Método para cargar faltas (similar a los otros métodos de carga)
Future<void> loadFaults({
  required BuildContext context,
  required bool Function() isMounted,
  required void Function(void Function())?
      setStateCallback, // Función para llamar setState
  required void Function(bool)?
      updateLoadingState, // Función para actualizar el estado de carga
}) async {
  if (!isMounted()) return;

  // Actualizar estado de carga a true
  if (setStateCallback != null && updateLoadingState != null) {
    setStateCallback(() => updateLoadingState(true));
  }

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
      if (setStateCallback != null && updateLoadingState != null) {
        setStateCallback(() => updateLoadingState(false));
      }
    }
  }
}

// Método para verificar si necesitamos cargar trabajadores
Future<void> checkAndLoadWorkersIfNeeded(
  bool Function() isMounted,
  Function setState,
  bool? isLoadingWorkers,
  BuildContext context,
) async {
  if (!isMounted()) return;

  final workersProvider = Provider.of<WorkersProvider>(context, listen: false);

  // Solo cargaremos si no se han cargado antes
  if (!workersProvider.hasLoadedInitialData) {
    await _loadWorkers(
      isMounted,
      setState,
      isLoadingWorkers,
      context,
    );
  }
}

Future<void> _loadWorkers(
  bool Function() isMounted,
  Function setState,
  bool? isLoadingWorkers,
  BuildContext context,
) async {
  if (!isMounted()) return;

  if (isLoadingWorkers != null)
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
    // Mostrar un mensaje de error
    if (isMounted()) {
      showErrorToast(context, 'Error al cargar trabajadores.');
    }
  } finally {
    if (isMounted()) {
      setState(() {
        if (isLoadingWorkers != null) {
          isLoadingWorkers = false;
        }
      });
    }
  }
}

Future<void> loadAreas(
  bool Function() isMounted,
  Function setState,
  bool? isLoadingAreas,
  BuildContext context,
) async {
  if (!isMounted()) return;

  final areasProvider = Provider.of<AreasProvider>(context, listen: false);

  // Verificar si ya hay áreas cargadas
  if (areasProvider.areas.isNotEmpty) return;

  if (isLoadingAreas != null) {
    // Si ya hay áreas cargadas, no mostrar el indicador de carga
    setState(() {
      isLoadingAreas = true;
    });
  }

  try {
    // Llamar al método fetchAreas con await para asegurar que se complete
    await areasProvider.fetchAreas(context);
  } catch (e, stackTrace) {
    debugPrint('Stack trace: $stackTrace');

    // Mostrar un mensaje de error más informativo
    if (isMounted()) {
      showErrorToast(context, "Error al cargar áreas.");
    }
  } finally {
    if (isMounted()) {
      if (isLoadingAreas != null) {
        // Asegurar que el estado de carga se desactive siempre al finalizar
        setState(() {
          isLoadingAreas = false;
        });
      }
    }
  }
}

Future<void> loadTask({
  required bool Function() isMounted,
  required setState,
  bool? isLoadingTasks,
  required BuildContext context,
}) async {
  if (!isMounted()) return;

  if (isLoadingTasks != null) {
    // Si ya hay tareas cargadas, no mostrar el indicador de carga
    setState(() {
      isLoadingTasks = true;
    });
  }

  try {
    final tasksProvider = Provider.of<TasksProvider>(context, listen: false);

    await tasksProvider.loadTasks(context);

    // Verificar resultado después de la carga
    if (tasksProvider.tasks.isEmpty) {
      debugPrint('La API devolvió una lista vacía de tareas.');
    } else {}
  } catch (e) {
    // En caso de error, mostramos una notificación
    if (isMounted()) {
      showErrorToast(context, 'Error al cargar tareas.');
    }
  } finally {
    if (isMounted()) {
      if (isLoadingTasks != null) {
        // Asegurar que el estado de carga se desactive siempre al finalizar
        setState(() {
          isLoadingTasks = false;
        });
      }
    }
  }
}

Future<void> loadAssignments({
  required BuildContext context,
  required bool Function() isMounted,
  required void Function(void Function())?
      setStateCallback, // Función para llamar setState
  required void Function(bool)?
      updateLoadingState, // Función para actualizar el estado de carga
}) async {
  if (!isMounted()) return;

  if (setStateCallback != null && updateLoadingState != null) {
    // Actualizar estado de carga a true
    setStateCallback(() => updateLoadingState(true));
  }

  // Configurar un timeout para evitar carga infinita
  final loadingTimeout = Future.delayed(const Duration(seconds: 10), () {
    if (isMounted()) {
      if (setStateCallback != null && updateLoadingState != null) {
        setStateCallback(() {
          updateLoadingState(false);
        });
      }

      // Desactivar loading en el provider también
      Provider.of<OperationsProvider>(context, listen: false)
          .changeIsLoadingOff();
      showAlertToast(
          context, 'La carga de datos está tomando demasiado tiempo');
    }
  });

  loadingTimeout.then((_) {
    if (isMounted()) {
      // debugPrint('Carga de asignaciones completada');
    }
  });
  // No mostrar indicador de carga si ya hay datos disponibles
  final assignmentsProvider =
      Provider.of<OperationsProvider>(context, listen: false);
  final hasExistingData = assignmentsProvider.operations.isNotEmpty;

  if (!hasExistingData) {
    if (setStateCallback != null && updateLoadingState != null) {
      setStateCallback(() {
        updateLoadingState(true);
      });
    }
  }

  try {
    // Cargar asignaciones con prioridad
    await assignmentsProvider.loadAssignmentsWithPriority(context);

    if (assignmentsProvider.operations.isNotEmpty) {
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
      if (setStateCallback != null && updateLoadingState != null) {
        setStateCallback(() {
          updateLoadingState(false);
        });
        // Asegurar que el provider también deshabilite su indicador de carga
        assignmentsProvider.changeIsLoadingOff();
      }
    }
  }
}

Future<bool> loadClients({
  required bool Function() isMounted,
  required Function setState,
  bool? isLoadingClients,
  required BuildContext context,
}) async {
  if (!isMounted()) return false;

  final clientsProvider = Provider.of<ClientsProvider>(context, listen: false);

  // Si ya se han cargado clientes, no hacer nada
  if (clientsProvider.clients.isNotEmpty) {
    return true;
  }

  if (isLoadingClients != null) {
    // Si ya hay clientes cargados, no mostrar el indicador de carga
    setState(() {
      isLoadingClients = true;
    });
  }

  try {
    await clientsProvider.fetchClients(context);

    if (clientsProvider.clients.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  } catch (e, stackTrace) {
    debugPrint('Error al cargar clientes: $e');
    debugPrint('Stack trace: $stackTrace');

    // Mostrar un mensaje de error más informativo
    if (isMounted()) {
      showErrorToast(context, 'Error al cargar clientes.');
    }

    return false;
  } finally {
    if (isMounted()) {
      if (isLoadingClients != null) {
        // Asegurar que el estado de carga se desactive siempre al finalizar
        setState(() {
          isLoadingClients = false;
        });
      }
    }
  }
}

Future<void> loadClientProgramming(
  bool Function() isMounted,
  Function setState,
  bool? isLoadingClientProgramming,
  BuildContext context, {
  bool forceRefresh = false,
}) async {
  if (!isMounted()) return;

  final programmingsProvider =
      Provider.of<ProgrammingsProvider>(context, listen: false);

  // Si no es refresh forzado y ya se han cargado programaciones, no hacer nada
  if (!forceRefresh && programmingsProvider.programmings.isNotEmpty) return;

  setState(() {
    isLoadingClientProgramming = true;
  });

  final DateTime now = DateTime.now();
  final String formattedDate = DateFormat('yyyy-MM-dd').format(now);

  try {
    if (forceRefresh) {
      // Si es refresh forzado, usar el nuevo método de refresh
      await programmingsProvider.refreshProgrammings(context,
          specificDate: formattedDate);
    } else {
      // Si no es refresh forzado, usar el método normal
      await programmingsProvider.fetchProgrammingsByDate(
          formattedDate, context);
    }

    if (!programmingsProvider.programmings.isNotEmpty) {
      debugPrint('No se cargaron programaciones o la lista está vacía');
    }
  } catch (e, stackTrace) {
    debugPrint('Error al cargar programaciones del cliente: $e');
    debugPrint('Stack trace: $stackTrace');

    // Mostrar un mensaje de error más informativo
    if (isMounted()) {
      showErrorToast(context, 'Error al cargar programaciones del cliente.');
    }
  } finally {
    if (isMounted()) {
      setState(() {
        isLoadingClientProgramming = false;
      });
    }
  }
}
