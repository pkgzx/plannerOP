import 'package:flutter/material.dart';
import 'package:plannerop/core/model/area.dart';
import 'package:plannerop/services/areas/areas.dart';
import 'package:plannerop/store/auth.dart';
import 'package:provider/provider.dart';

class AreasProvider extends ChangeNotifier {
  List<Area> _areas = [];
  final AreaService _areaService = AreaService();

  List<Area> get areas => _areas;

  void setAreas(List<Area> areas) {
    _areas = areas;
    notifyListeners();
  }

  Future<void> fetchAreas(BuildContext context) async {
    if (_areas.isEmpty) {
      final String token =
          Provider.of<AuthProvider>(context, listen: false).accessToken;
      try {
        final List<Area> areas = await _areaService.fetchAreas(token);
        setAreas(areas);
      } catch (e) {
        debugPrint('Error al obtener las áreas en FetchAreas_provider');
      }
    }
  }
}
