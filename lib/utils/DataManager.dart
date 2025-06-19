import 'package:flutter/material.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/operations.dart';
import 'package:plannerop/store/auth.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/store/clients.dart';
import 'package:plannerop/store/faults.dart';
import 'package:plannerop/store/task.dart';
import 'package:plannerop/store/workers.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class DataManager {
  // Singleton
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  // Estado
  final Map<String, bool> _isLoading = {};
  final Map<String, bool> _hasLoaded = {};
  final Map<String, DateTime> _lastLoaded = {};
  final Map<String, Completer<void>> _loadingCompleters = {};

  // Tiempo mínimo entre actualizaciones forzadas
  final Duration _minRefreshInterval = Duration(minutes: 2);

  // Control de inicialización
  bool _initialized = false;
  BuildContext? _appContext;

  // Verificar si los datos están cargando
  bool isLoading(String resource) => _isLoading[resource] ?? false;
  bool hasLoaded(String resource) => _hasLoaded[resource] ?? false;

  void initialize(BuildContext context) {
    if (_initialized) return;
    _initialized = true;
    _appContext = context;
  }

  //  método para cargar datos después del login
  Future<void> loadDataAfterAuthentication(BuildContext context) async {
    // Verificar que el token esté disponible
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.accessToken.isEmpty) {
      debugPrint('DataManager: Token no disponible, no se cargarán datos');
      return;
    }

    // Ahora sí, cargar datos críticos
    await _loadCriticalData(context);

    // Y programar carga secundaria
    Future.delayed(Duration(milliseconds: 500), () {
      if (_appContext != null) {
        _loadSecondaryData(_appContext!);
      }
    });
  }

  // Métodos de control para carga de diferentes datos
  Future<void> _loadCriticalData(BuildContext context) async {
    await Future.wait([
      _loadWorkers(context),
      _loadAssignments(context),
      _loadAreas(context),
    ]).catchError((error) {
      debugPrint('Error cargando datos críticos: $error');
    });
  }

  Future<void> _loadSecondaryData(BuildContext context) async {
    try {
      // Verificar token antes de intentar cargar
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.accessToken.isEmpty) {
        debugPrint(
            'DataManager: No hay token disponible para cargar datos secundarios');
        return;
      }

      await Future.wait([
        _loadTasks(context),
        _loadClients(context),
        // _loadChargers(context),
        _loadFaults(context),
      ]);
    } catch (error) {
      debugPrint('Error cargando datos secundarios: $error');
    }
  }

  // Métodos específicos para cada tipo de datos
  Future<void> _loadWorkers(BuildContext context) async {
    return _loadResource('workers', context, () async {
      final provider = Provider.of<WorkersProvider>(context, listen: false);
      await provider.fetchWorkersIfNeeded(context);
    });
  }

  Future<void> _loadAssignments(BuildContext context) async {
    return _loadResource('assignments', context, () async {
      final provider = Provider.of<OperationsProvider>(context, listen: false);
      await provider.loadAssignmentsWithPriority(context);
    });
  }

  Future<void> _loadAreas(BuildContext context) async {
    return _loadResource('areas', context, () async {
      final provider = Provider.of<AreasProvider>(context, listen: false);
      if (provider.areas.isEmpty) {
        await provider.fetchAreas(context);
      }
    });
  }

  Future<void> _loadTasks(BuildContext context) async {
    return _loadResource('tasks', context, () async {
      final provider = Provider.of<TasksProvider>(context, listen: false);
      if (!provider.hasAttemptedLoading) {
        await provider.loadTasks(context);
      }
    });
  }

  Future<void> _loadClients(BuildContext context) async {
    return _loadResource('clients', context, () async {
      final provider = Provider.of<ClientsProvider>(context, listen: false);
      if (provider.clients.isEmpty) {
        await provider.fetchClients(context);
      }
    });
  }

  // Future<void> _loadChargers(BuildContext context) async {
  //   return _loadResource('chargers', context, () async {
  //     final provider = Provider.of<ChargersOpProvider>(context, listen: false);
  //     await provider.fetchChargers(context);
  //   });
  // }

  Future<void> _loadFaults(BuildContext context) async {
    return _loadResource('faults', context, () async {
      final provider = Provider.of<FaultsProvider>(context, listen: false);
      await provider.fetchFaults(context);
    });
  }

  // Método genérico para cargar recursos con seguridad
  Future<void> _loadResource(String resourceKey, BuildContext context,
      Future<void> Function() loadFunction) async {
    // Si ya está cargando, devolver el completer actual
    if (_isLoading[resourceKey] == true) {
      return _loadingCompleters[resourceKey]?.future ?? Future.value();
    }

    // Verificar si necesita actualizarse
    final lastLoaded = _lastLoaded[resourceKey];
    final now = DateTime.now();
    if (lastLoaded != null &&
        now.difference(lastLoaded) < _minRefreshInterval) {
      return Future.value(); // Evitar cargas frecuentes
    }

    // Preparar para carga
    _isLoading[resourceKey] = true;
    _loadingCompleters[resourceKey] = Completer<void>();

    try {
      // Realizar carga
      await loadFunction();

      // Actualizar estado
      _hasLoaded[resourceKey] = true;
      _lastLoaded[resourceKey] = DateTime.now();
      _loadingCompleters[resourceKey]?.complete();
    } catch (error) {
      debugPrint('Error cargando $resourceKey: $error');
      _loadingCompleters[resourceKey]?.completeError(error);
    } finally {
      _isLoading[resourceKey] = false;
    }
  }

  // Métodos públicos para refrescar datos desde la UI
  Future<void> refreshCriticalData(BuildContext context) async {
    // Limpiar timestamps para forzar recarga
    _lastLoaded.remove('workers');
    _lastLoaded.remove('assignments');
    _lastLoaded.remove('areas');

    await _loadCriticalData(context);
  }

  Future<void> refreshData(String resource, BuildContext context) async {
    _lastLoaded.remove(resource);

    switch (resource) {
      case 'workers':
        await _loadWorkers(context);
        break;
      case 'assignments':
        await _loadAssignments(context);
        break;
      case 'areas':
        await _loadAreas(context);
        break;
      case 'tasks':
        await _loadTasks(context);
        break;
      case 'clients':
        await _loadClients(context);
        break;
      // case 'chargers':
      //   await _loadChargers(context);
      //   break;
      case 'faults':
        await _loadFaults(context);
        break;
    }
  }
}
