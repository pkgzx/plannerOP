import 'package:plannerop/core/model/worker.dart';

class Fault {
  int id;
  final String description;
  final FaultType type;
  final Worker worker;

  Fault(
      {required this.description,
      required this.type,
      this.id = 0,
      required this.worker});
}

enum FaultType {
  INASSISTANCE,
  IRRESPECTFUL,
  ABANDONMENT,
}
