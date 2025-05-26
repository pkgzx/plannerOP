import 'package:flutter/material.dart';
import 'package:plannerop/services/feedings/feedings.dart';
import 'package:plannerop/utils/toast.dart';

class FeedingProvider extends ChangeNotifier {
  // Mapa de alimentación {operationId: {workerId: {type: bool}}}
  Map<int, Map<int, Map<String, bool>>> _feedingStatus = {};
  bool _isLoading = false;

  // Getters
  Map<int, Map<int, Map<String, bool>>> get feedingStatus => _feedingStatus;
  bool get isLoading => _isLoading;

  final FeedingService _feedingService = FeedingService();

  // Convertir tipo de comida al formato de la API
  String _getFeedingTypeForApi(String foodType) {
    switch (foodType) {
      case 'Desayuno':
        return 'BREAKFAST';
      case 'Almuerzo':
        return 'LUNCH';
      case 'Cena':
        return 'DINNER';
      case 'Media noche':
        return 'SNACK';
      default:
        return 'BREAKFAST';
    }
  }

  // Convertir tipo de API a formato de UI
  String _getFeedingTypeFromApi(String apiType) {
    switch (apiType) {
      case 'BREAKFAST':
        return 'Desayuno';
      case 'LUNCH':
        return 'Almuerzo';
      case 'DINNER':
        return 'Cena';
      case 'SNACK':
        return 'Media noche';
      default:
        return 'Desayuno';
    }
  }

  // Verificar si la alimentación está marcada
  bool isMarked(int operationId, int workerId, String foodType) {
    return _feedingStatus[operationId]?[workerId]?[foodType] ?? false;
  }

  // En el método markFeeding en FeedingProvider, añadir una notificación específica
  Future<bool> markFeeding({
    required int operationId,
    required int workerId,
    required String foodType,
    required BuildContext context,
  }) async {
    // Si ya está marcada, no hacer nada
    if (isMarked(operationId, workerId, foodType)) {
      return true;
    }

    _isLoading = true;
    notifyListeners();

    bool success = false;

    try {
      String apiType = _getFeedingTypeForApi(foodType);

      // Marcar como entregada
      success = await _feedingService.markFeeding(
        workerId: workerId,
        operationId: operationId,
        type: apiType,
        context: context,
      );

      if (success) {
        // Inicializar estructura de datos si es necesario
        _feedingStatus[operationId] ??= {};
        _feedingStatus[operationId]![workerId] ??= {};
        // Actualizar el estado local
        _feedingStatus[operationId]![workerId]![foodType] = true;

        showSuccessToast(context, "$foodType entregado");

        // Notificar después de actualizar los datos
        notifyListeners();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      showErrorToast(context, "Error al registrar alimentación: $e");
      return false;
    }
  }

  bool areAllWorkersMarked(
      int operationId, List<int> workerIds, String foodType) {
    if (_feedingStatus[operationId] == null) {
      return false;
    }

    for (var workerId in workerIds) {
      if (!isMarked(operationId, workerId, foodType)) {
        return false;
      }
    }

    return true;
  }

  // cargar alimentaciones de una operación específica - MÉTODO CORREGIDO
  Future<void> loadFeedingStatusForOperation(
      int operationId, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final feedingService = FeedingService();
      final List<dynamic> feedingData =
          await feedingService.getFeedingsForOperation(operationId, context);

      debugPrint("Feeding data: $feedingData");

      // Inicializar la estructura de datos para esta operación
      _feedingStatus[operationId] = {};

      // Procesar los datos recibidos
      for (var feeding in feedingData) {
        int workerId = feeding['id_worker'];
        String type = feeding['type'];

        // CORREGIDO: Convertir tipo de API a formato de UI usando el método correcto
        String foodType = _getFeedingTypeFromApi(type);

        // Inicializar la estructura si no existe
        _feedingStatus[operationId]![workerId] ??= {};

        // Marcar como entregado
        _feedingStatus[operationId]![workerId]![foodType] = true;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando alimentación: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verificar si una comida específica está marcada para un trabajador
  bool isFoodTypeMarked(int operationId, int workerId, String foodType) {
    return _feedingStatus[operationId]?[workerId]?[foodType] ?? false;
  }

  // Limpiar datos
  void clear() {
    _feedingStatus = {};
    notifyListeners();
  }
}
