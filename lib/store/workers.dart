import 'package:flutter/material.dart';
import 'package:plannerop/core/model/fault.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/services/workers/workers.dart';
import 'package:plannerop/dto/workers/fetchWorkers.dart';
import 'package:plannerop/store/faults.dart';
import 'package:provider/provider.dart';

class WorkersProvider with ChangeNotifier {
  // Lista de trabajadores
  final List<Worker> _workers = [];

  // Estado de carga
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasLoadedInitialData =
      false; // Flag para controlar si ya se cargaron datos

  // Servicio de trabajadores
  final WorkerService _workerService = WorkerService();

  // Getters
  List<Worker> get workers => [..._workers];
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  bool get hasLoadedInitialData => _hasLoadedInitialData;

  List<Worker> getFilteredWorkers(String searchQuery) {
    if (searchQuery.isEmpty) {
      return [..._workers];
    }
    return _workers
        .where((worker) =>
            worker.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  int get totalWorkerWithoutRetired =>
      _workers.where((w) => w.status != WorkerStatus.deactivated).length;

  int get totalWorkers => _workers.length;

  List<Worker> getWorkersAvailable() {
    return _workers.where((w) => w.status == WorkerStatus.available).toList();
  }

  int get assignedWorkers =>
      _workers.where((w) => w.status == WorkerStatus.assigned).length;

  int get disabledWorkers =>
      _workers.where((w) => w.status == WorkerStatus.incapacitated).length;

  int get retiredWorkers =>
      _workers.where((w) => w.status == WorkerStatus.deactivated).length;

  int get availableWorkers =>
      _workers.where((w) => w.status == WorkerStatus.available).length;

  Worker getWorkerById(int id) {
    return _workers.firstWhere((w) => w.id == id,
        orElse: () => Worker(
              id: 0,
              name: '',
              area: '',
              phone: '',
              document: '',
              status: WorkerStatus.available,
              startDate: DateTime.now(),
              code: '',
              failures: 0,
              idArea: 0,
            ));
  }

  // Registrar falta con descripción y actualizar el contador
  Future<bool> registerFault(
    Worker worker,
    BuildContext context, {
    String? description,
  }) async {
    try {
      // Llamar al servicio para registrar la falta
      final success = await _workerService.registerFault(worker, context,
          description: description);
      if (success) {
        // Actualizar el contador de faltas en la copia local del worker
        final index = _workers.indexWhere((w) => w.id == worker.id);
        if (index >= 0) {
          final updatedWorker = Worker(
            id: worker.id,
            name: worker.name,
            area: worker.area,
            phone: worker.phone,
            document: worker.document,
            status: worker.status,
            startDate: worker.startDate,
            endDate: worker.endDate,
            code: worker.code,
            incapacityStartDate: worker.incapacityStartDate,
            incapacityEndDate: worker.incapacityEndDate,
            failures: worker.failures + 1,
            idArea: worker.idArea,
            deactivationDate: worker.deactivationDate,
          );
          _workers[index] = updatedWorker;
          notifyListeners();
        }

        // Además de actualizar el worker, crear un registro de falta para el FaultsProvider
        if (description != null && description.isNotEmpty) {
          final faultsProvider =
              Provider.of<FaultsProvider>(context, listen: false);
          faultsProvider.addFault(Fault(
            description: description,
            type: FaultType.INASSISTANCE,
            id: 0, // El ID lo asignará la API
            worker: worker,
            createdAt: DateTime.now(),
          ));
        }

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error en registerFault: $e');
      return false;
    }
  }

  // Registrar abandono (solo registra el incidente, no incrementa el contador)
  Future<bool> registerAbandonment(
    Worker worker,
    BuildContext context, {
    String? description,
  }) async {
    try {
      if (description == null || description.isEmpty) {
        return false;
      }

      // Llamar al servicio para registrar el abandono
      final success = await _workerService.registerAbandonment(worker, context,
          description: description);

      if (success) {
        // Actualizar el contador de faltas en la copia local del worker
        final index = _workers.indexWhere((w) => w.id == worker.id);
        if (index >= 0) {
          final updatedWorker = Worker(
            id: worker.id,
            name: worker.name,
            area: worker.area,
            phone: worker.phone,
            document: worker.document,
            status: worker.status,
            startDate: worker.startDate,
            endDate: worker.endDate,
            code: worker.code,
            incapacityStartDate: worker.incapacityStartDate,
            incapacityEndDate: worker.incapacityEndDate,
            failures: worker.failures + 1,
            idArea: worker.idArea,
            deactivationDate: worker.deactivationDate,
          );
          _workers[index] = updatedWorker;
          notifyListeners();
        }

        // Además de actualizar el worker, crear un registro de falta para el FaultsProvider
        if (description != null && description.isNotEmpty) {
          final faultsProvider =
              Provider.of<FaultsProvider>(context, listen: false);
          faultsProvider.addFault(Fault(
            description: description,
            type: FaultType.INASSISTANCE,
            id: 0, // El ID lo asignará la API
            worker: worker,
            createdAt: DateTime.now(),
          ));
        }

        return true;
      }
      if (success) {
        // Crear un registro de abandono en el FaultsProvider
        final faultsProvider =
            Provider.of<FaultsProvider>(context, listen: false);
        faultsProvider.addFault(Fault(
          description: description,
          type: FaultType.ABANDONMENT,
          id: 0, // El ID lo asignará la API
          worker: worker,
          createdAt: DateTime.now(),
        ));

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error en registerAbandonment: $e');
      return false;
    }
  }

  // Registrar falta de respeto (solo registra el incidente, no incrementa el contador)
  Future<bool> registerDisrespect(
    Worker worker,
    BuildContext context, {
    String? description,
  }) async {
    try {
      if (description == null || description.isEmpty) {
        return false;
      }

      // Llamar al servicio para registrar la falta de respeto
      final success = await _workerService.registerDisrespect(worker, context,
          description: description);

      if (success) {
        // Actualizar el contador de faltas en la copia local del worker
        final index = _workers.indexWhere((w) => w.id == worker.id);
        if (index >= 0) {
          final updatedWorker = Worker(
            id: worker.id,
            name: worker.name,
            area: worker.area,
            phone: worker.phone,
            document: worker.document,
            status: worker.status,
            startDate: worker.startDate,
            endDate: worker.endDate,
            code: worker.code,
            incapacityStartDate: worker.incapacityStartDate,
            incapacityEndDate: worker.incapacityEndDate,
            failures: worker.failures + 1,
            idArea: worker.idArea,
            deactivationDate: worker.deactivationDate,
          );
          _workers[index] = updatedWorker;
          notifyListeners();
        }

        // Además de actualizar el worker, crear un registro de falta para el FaultsProvider
        if (description != null && description.isNotEmpty) {
          final faultsProvider =
              Provider.of<FaultsProvider>(context, listen: false);
          faultsProvider.addFault(Fault(
            description: description,
            type: FaultType.INASSISTANCE,
            id: 0, // El ID lo asignará la API
            worker: worker,
            createdAt: DateTime.now(),
          ));
        }

        return true;
      }
      if (success) {
        // Crear un registro de falta de respeto en el FaultsProvider
        final faultsProvider =
            Provider.of<FaultsProvider>(context, listen: false);
        faultsProvider.addFault(Fault(
          description: description,
          type: FaultType.IRRESPECTFUL,
          id: 0, // El ID lo asignará la API
          worker: worker,
          createdAt: DateTime.now(),
        ));

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error en registerDisrespect: $e');
      return false;
    }
  }

  // Método modificado para cargar trabajadores solo la primera vez
  Future<void> fetchWorkersIfNeeded(BuildContext context) async {
    // // Si ya cargamos datos previamente, no hacemos nada
    // if (_hasLoadedInitialData) {
    //   debugPrint(
    //       'Omitiendo fetchWorkers: los datos ya fueron cargados anteriormente');
    //   return;
    // }

    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      // debugPrint('Cargando trabajadores desde API (primera vez)...');
      final FetchWorkersDto result = await _workerService.fetchWorkers(context);

      if (result.isSuccess && result.workers.isNotEmpty) {
        _workers.clear();
        _workers.addAll(result.workers);
        // debugPrint(
        //     'Datos iniciales cargados correctamente: ${_workers.length} trabajadores');
      } else {
        _hasError = true;
        _errorMessage =
            'No se encontraron trabajadores o hubo un error en la API';
        debugPrint('Error o lista vacía en carga de trabajadores');
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Error de conexión: ${e.toString()}';
      debugPrint('Excepción en fetchWorkers: $e');
    } finally {
      _isLoading = false;
      _hasLoadedInitialData = true; // Marcar que ya se intentó cargar datos
      notifyListeners();
    }
  }

  // Método para cargar los trabajadores desde la API
  Future<void> fetchWorkers(BuildContext context) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      final FetchWorkersDto result = await _workerService.fetchWorkers(context);

      if (result.isSuccess && result.workers.isNotEmpty) {
        _workers.clear();
        _workers.addAll(result.workers);
      } else {
        _hasError = true;
        _errorMessage = 'Error al cargar los trabajadores';
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Error de conexión: ${e.toString()}';
    } finally {
      _isLoading = false;
      _hasLoadedInitialData =
          true; // Actualizar el flag también en recargas forzadas
      notifyListeners();
    }
  }

  // Métodos para manipular los trabajadores
  Future<Map<String, dynamic>> addWorker(
      Worker worker, BuildContext context) async {
    try {
      // Llamar al servicio y esperar respuesta
      final result = await _workerService.registerWorker(worker, context);

      // Si fue exitoso, agregar a la lista local
      if (result['success']) {
        _workers.add(worker);
        notifyListeners();
      }

      // Devolver el resultado para que la UI pueda mostrar mensajes apropiados
      return result;
    } catch (e) {
      debugPrint('Error en addWorker: $e');
      return {'success': false, 'message': 'Error al agregar trabajador: $e'};
    }
  }

  List<Worker> getWorkersByStatus(WorkerStatus status) {
    return _workers.where((w) => w.status == status).toList();
  }

  // Método general para actualizar un trabajador
  Future<bool> updateWorker(
      Worker oldWorker, Worker newWorker, BuildContext context) async {
    try {
      // Llamar al servicio para actualizar en la API
      final success = await _workerService.updateWorker(newWorker, context);
      if (success) {
        // debugPrint('Trabajador actualizado correctamente en la API');
        // Actualizar en la lista local
        final index = _workers.indexWhere((w) => w.id == oldWorker.id);
        if (index >= 0) {
          _workers[index] = newWorker;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error en updateWorker del provider: $e');
      return false;
    }
  }

  // Mantener métodos específicos para incapacitación
  Future<bool> incapacitateWorker(Worker worker, DateTime startDate,
      DateTime endDate, BuildContext context) async {
    // Crear una copia del trabajador con los nuevos datos
    final updatedWorker = Worker(
        id: worker.id,
        name: worker.name,
        area: worker.area,
        phone: worker.phone,
        document: worker.document,
        status: WorkerStatus.incapacitated,
        startDate: worker.startDate,
        endDate: worker.endDate,
        code: worker.code,
        incapacityStartDate: startDate,
        incapacityEndDate: endDate,
        failures: worker.failures);

    // Usar el método general
    return updateWorker(worker, updatedWorker, context);
  }

  // Y para retiro
  Future<bool> retireWorker(
      Worker worker, DateTime retirementDate, BuildContext context) async {
    // Crear una copia del trabajador con los nuevos datos
    final updatedWorker = Worker(
        id: worker.id,
        name: worker.name,
        area: worker.area,
        phone: worker.phone,
        document: worker.document,
        status: WorkerStatus.deactivated,
        startDate: worker.startDate,
        endDate: worker.endDate,
        code: worker.code,
        deactivationDate: retirementDate,
        failures: worker.failures);

    // Usar el método general
    return updateWorker(worker, updatedWorker, context);
  }

  void deleteWorker(Worker worker) {
    _workers.removeWhere((w) => w.name == worker.name);
    notifyListeners();
  }

  void updateWorkerStatus(Worker worker, WorkerStatus newStatus) {
    final index = _workers.indexWhere((w) => w.name == worker.name);
    if (index >= 0) {
      final updatedWorker = Worker(
          id: worker.id,
          name: worker.name,
          area: worker.area,
          phone: worker.phone,
          document: worker.document,
          status: newStatus,
          startDate: worker.startDate,
          endDate: worker.endDate,
          incapacityEndDate: worker.incapacityEndDate,
          incapacityStartDate: worker.incapacityStartDate,
          code: worker.code,
          failures: worker.failures);
      _workers[index] = updatedWorker;
      notifyListeners();
    }
  }

  List<Worker> searchWorkers(String query) {
    return _workers
        .where(
            (worker) => worker.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Método para asignar un trabajador (cambia su estado a asignado)
  // MANTIENE LA FIRMA ORIGINAL
  void assignWorker(Worker worker, DateTime endDate) {
    final index = _workers.indexWhere((w) => w.name == worker.name);
    if (index >= 0) {
      final updatedWorker = Worker(
          id: worker.id,
          name: worker.name,
          area: worker.area,
          phone: worker.phone,
          document: worker.document,
          status: WorkerStatus.assigned,
          startDate: worker.startDate,
          endDate: endDate,
          code: worker.code,
          incapacityEndDate: worker.incapacityEndDate,
          incapacityStartDate: worker.incapacityStartDate,
          failures: worker.failures);
      _workers[index] = updatedWorker;
      notifyListeners();
    }
  }

  // Método para liberar un trabajador (cambia su estado a disponible)
  // MANTIENE LA FIRMA ORIGINAL
  void releaseWorker(Worker worker) {
    final index = _workers.indexWhere((w) => w.name == worker.name);
    if (index >= 0) {
      final updatedWorker = Worker(
          id: worker.id,
          name: worker.name,
          area: worker.area,
          phone: worker.phone,
          document: worker.document,
          status: WorkerStatus.available,
          startDate: worker.startDate,
          endDate: null,
          code: worker.code,
          incapacityEndDate: worker.incapacityEndDate,
          incapacityStartDate: worker.incapacityStartDate,
          failures: worker.failures);
      _workers[index] = updatedWorker;
      notifyListeners();
    }
  }

  // Agregar estos métodos a la clase WorkersProvider

  Map<String, dynamic> workerToMap(Worker worker) {
    return {
      'id': worker.document,
      'name': worker.name,
      'area': worker.area,
      'document': worker.document,
    };
  }

  // Método para liberar un trabajador (cambia su estado a disponible)
  // MANTIENE LA FIRMA ORIGINAL
  // Actualiza estos métodos en WorkersProvider

  // Método para asignar un trabajador en el backend
  Future<bool> assignWorkerObject(Worker worker, BuildContext context) async {
    try {
      // Llamar al servicio para actualizar el estado en el backend
      final success = await _workerService.updateWorkerStatus(
          worker.id, "assigned", context);

      if (success) {
        // Actualizar estado localmente
        final index = _workers.indexWhere((w) => w.id == worker.id);
        if (index >= 0) {
          final updatedWorker = Worker(
              id: worker.id,
              name: worker.name,
              area: worker.area,
              phone: worker.phone,
              document: worker.document,
              status: WorkerStatus.assigned,
              startDate: worker.startDate,
              endDate: null,
              code: worker.code,
              incapacityEndDate: worker.incapacityEndDate,
              incapacityStartDate: worker.incapacityStartDate,
              failures: worker.failures);
          _workers[index] = updatedWorker;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error al asignar trabajador: $e');
      return false;
    }
  }

  // Método para liberar un trabajador en el backend
  Future<bool> releaseWorkerObject(Worker worker, BuildContext context) async {
    try {
      // Llamar al servicio para actualizar el estado en el backend
      final success = await _workerService.updateWorkerStatus(
          worker.id, "available", context);

      if (success) {
        // Actualizar estado localmente
        final index = _workers.indexWhere((w) => w.id == worker.id);
        if (index >= 0) {
          final updatedWorker = Worker(
              id: worker.id,
              name: worker.name,
              area: worker.area,
              phone: worker.phone,
              document: worker.document,
              status: WorkerStatus.available,
              startDate: worker.startDate,
              endDate: null,
              code: worker.code,
              incapacityEndDate: worker.incapacityEndDate,
              incapacityStartDate: worker.incapacityStartDate,
              failures: worker.failures);
          _workers[index] = updatedWorker;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error al liberar trabajador: $e');
      return false;
    }
  }
}
