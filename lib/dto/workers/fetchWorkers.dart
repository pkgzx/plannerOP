import 'package:plannerop/core/model/worker.dart';

class FetchWorkersDto {
  final List<Worker> workers;
  final bool isSuccess;

  FetchWorkersDto({required this.workers, required this.isSuccess});
}
