import 'package:flutter/material.dart';
import 'package:plannerop/core/model/fault.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/services/faults/fault.dart';
import 'package:plannerop/store/workers.dart';
import 'package:provider/provider.dart';

class FaultsProvider extends ChangeNotifier {
  List<Fault> _faults = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _hasLoadedInitialData = false;

  final FaultService _faultService = FaultService();

  // Getters
  List<Fault> get faults => _faults;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get hasLoadedInitialData => _hasLoadedInitialData;

  // Añadir una falta local
  void addFault(Fault fault) {
    _faults.add(fault);
    notifyListeners();
  }

  // Eliminar una falta
  void removeFault(Fault fault) {
    _faults.remove(fault);
    notifyListeners();
  }

  // Cargar faltas desde la API
  Future<void> fetchFaults(BuildContext context) async {
    if (_isLoading) return;

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final faults = await _faultService.fetchFaults(context);
      _faults = faults;
      _hasLoadedInitialData = true;
    } catch (e) {
      debugPrint('Error al cargar faltas: $e');
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar faltas por trabajador
  Future<List<Fault>> fetchFaultsByWorker(
      BuildContext context, int workerId) async {
    try {
      return await _faultService.fetchFaultsByWorker(context, workerId);
    } catch (e) {
      debugPrint('Error al cargar faltas por trabajador: $e');
      return [];
    }
  }

  // Obtener faltas por tipo
  List<Fault> getFaultsByType(FaultType type) {
    return _faults.where((fault) => fault.type == type).toList();
  }

  // Obtener trabajadores con más faltas (ordenados por cantidad)
  List<Worker> getWorkersWithMostFaults(BuildContext context) {
    // Crear un mapa para contar faltas por trabajador
    final Map<int, int> workerFaultCount = {};

    final WorkersProvider workersProvider =
        Provider.of<WorkersProvider>(context, listen: false);

    // Contar la cantidad de faltas por trabajador
    for (Fault fault in _faults) {
      final workerId = fault.worker.id;
      workerFaultCount[workerId] = (workerFaultCount[workerId] ?? 0) + 1;
    }

    // Obtener lista única de trabajadores
    List<Worker> uniqueWorkers = <Worker>[];
    for (final fault in _faults) {
      if (!uniqueWorkers.any((w) => w.id == fault.worker.id)) {
        uniqueWorkers.add(fault.worker);
      }
    }

    for (Worker worker in uniqueWorkers) {
      debugPrint('Unique: $worker');
    }

    // Ordenar trabajadores por cantidad de faltas (de mayor a menor)
    uniqueWorkers.sort((a, b) {
      final countA = workerFaultCount[a.id] ?? 0;
      final countB = workerFaultCount[b.id] ?? 0;
      return countB.compareTo(countA);
    });

    // retornar solo los que tienen mas de 0 faltas
    uniqueWorkers = uniqueWorkers.where((worker) {
      final faultCount = workerFaultCount[worker.id] ?? 0;
      debugPrint('Fault count: $worker');
      return faultCount > 0;
    }).toList();

    for (Worker worker in uniqueWorkers) {
      debugPrint('Unique***: $worker');
    }

    return uniqueWorkers;
  }

  // Obtener la cantidad de faltas para un trabajador específico
  int getFaultCountForWorker(int workerId) {
    return _faults.where((fault) => fault.worker.id == workerId).length;
  }
}
