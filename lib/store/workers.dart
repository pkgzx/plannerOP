import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';

class WorkersProvider with ChangeNotifier {
  // Lista de trabajadores
  final List<Worker> _workers = [
    Worker(
      name: 'Juan Pérez',
      area: 'CARGA GENERAL',
      phone: '555-1234',
      document: '12345678',
      status: WorkerStatus.assigned,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
    ),
    Worker(
      name: 'María López',
      area: 'CARGA REFRIGERADA',
      phone: '555-5678',
      document: '87654321',
      status: WorkerStatus.assigned,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 5)),
    ),
    Worker(
      name: 'Pedro Rodríguez',
      area: 'CARGA GENERAL',
      phone: '555-9012',
      document: '13579246',
      status: WorkerStatus.assigned,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 3)),
    ),
    Worker(
      name: 'Ricardo Martínez',
      area: 'CARGA GENERAL',
      phone: '555-3456',
      document: '24681357',
      status: WorkerStatus.available,
      startDate: DateTime.now(),
    ),
  ];

  // Mapeo de especialidades a colores
  final Map<String, Color> _specialtyColors = {
    'CARGA GENERAL': const Color(0xFF4299E1), // Azul
    'CARGA REFRIGERADA': const Color(0xFF48BB78), // Verde
    'CARGA PELIGROSA': const Color(0xFFED8936), // Naranja
    'CARGA ESPECIAL': const Color(0xFFF56565), // Rojo
    'CARGA A GRANEL': const Color(0xFF9F7AEA), // Púrpura
  };

  // Getters
  List<Worker> get workers => [..._workers];

  List<Worker> getFilteredWorkers(String searchQuery) {
    if (searchQuery.isEmpty) {
      return [..._workers];
    }
    return _workers
        .where((worker) =>
            worker.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  int get totalWorkers => _workers.length;

  int get assignedWorkers =>
      _workers.where((w) => w.status == WorkerStatus.assigned).length;

  int get availableWorkers =>
      _workers.where((w) => w.status == WorkerStatus.available).length;

  Color getSpecialtyColor(String area) {
    return _specialtyColors[area] ??
        const Color(0xFF718096); // Gris por defecto
  }

  // Métodos para manipular los trabajadores
  void addWorker(Worker worker) {
    _workers.add(worker);
    notifyListeners();
  }

  List<Worker> getWorkersByStatus(WorkerStatus status) {
    return _workers.where((w) => w.status == status).toList();
  }

  void updateWorker(Worker oldWorker, Worker updatedWorker) {
    final index = _workers.indexWhere((w) => w.name == oldWorker.name);
    if (index >= 0) {
      _workers[index] = updatedWorker;
      notifyListeners();
    }
  }

  void deleteWorker(Worker worker) {
    _workers.removeWhere((w) => w.name == worker.name);
    notifyListeners();
  }

  void updateWorkerStatus(Worker worker, WorkerStatus newStatus) {
    final index = _workers.indexWhere((w) => w.name == worker.name);
    if (index >= 0) {
      final updatedWorker = Worker(
        name: worker.name,
        area: worker.area,
        phone: worker.phone,
        document: worker.document,
        status: newStatus,
        startDate: worker.startDate,
        endDate: worker.endDate,
      );
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

  Color getColorForArea(String area) {
    return _specialtyColors[area] ?? const Color(0xFF718096);
  }

  // Método para asignar un trabajador (cambia su estado a asignado)
  void assignWorker(Worker worker, DateTime endDate) {
    final index = _workers.indexWhere((w) => w.name == worker.name);
    if (index >= 0) {
      final updatedWorker = Worker(
        name: worker.name,
        area: worker.area,
        phone: worker.phone,
        document: worker.document,
        status: WorkerStatus.assigned,
        startDate: worker.startDate,
        endDate: endDate,
      );
      _workers[index] = updatedWorker;
      notifyListeners();
    }
  }

  // Método para liberar un trabajador (cambia su estado a disponible)
  void releaseWorker(Worker worker) {
    final index = _workers.indexWhere((w) => w.name == worker.name);
    if (index >= 0) {
      final updatedWorker = Worker(
        name: worker.name,
        area: worker.area,
        phone: worker.phone,
        document: worker.document,
        status: WorkerStatus.available,
        startDate: worker.startDate,
        endDate: null,
      );
      _workers[index] = updatedWorker;
      notifyListeners();
    }
  }
}
