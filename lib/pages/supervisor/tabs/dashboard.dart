import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/widgets/cifras.dart';
import 'package:plannerop/widgets/quickActions.dart';
import 'package:plannerop/widgets/recentOps.dart';
import 'package:plannerop/store/workers.dart';
import 'package:provider/provider.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _isLoadingWorkers = false;
  bool _isLoadingAreas = false;

  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para programar la carga después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadWorkersIfNeeded();
      _loadAreas();
    });
  }

  // Método para verificar si necesitamos cargar trabajadores
  Future<void> _checkAndLoadWorkersIfNeeded() async {
    if (!mounted) return;

    final workersProvider =
        Provider.of<WorkersProvider>(context, listen: false);

    // Solo cargaremos si no se han cargado antes
    if (!workersProvider.hasLoadedInitialData) {
      await _loadWorkers();
    }
  }

  Future<void> _loadWorkers() async {
    if (!mounted) return;

    setState(() {
      _isLoadingWorkers = true;
    });

    final workersProvider =
        Provider.of<WorkersProvider>(context, listen: false);

    try {
      // Intentar cargar desde la API usando el método que respeta el flag
      await workersProvider.fetchWorkersIfNeeded(context);

      // Si después de intentar cargar no hay datos, añadir datos de muestra
      if (workersProvider.workers.isEmpty) {}
    } catch (e) {
      // Si algo falla, cargar datos de muestra

      // Mostrar un mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar trabajadores: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWorkers = false;
        });
      }
    }
  }

  Future<void> _loadAreas() async {
    if (!mounted) return;

    final areasProvider = Provider.of<AreasProvider>(context, listen: false);

    // Verificar si ya hay áreas cargadas
    if (areasProvider.areas.isNotEmpty) {
      debugPrint(
          'Áreas ya cargadas anteriormente: ${areasProvider.areas.length}');
      return;
    }

    debugPrint('Iniciando carga de áreas desde API...');

    // Mostrar indicador de carga para áreas
    setState(() {
      _isLoadingAreas = true;
    });

    try {
      // Llamar al método fetchAreas con await para asegurar que se complete
      await areasProvider.fetchAreas(context);

      // Verificar si se cargaron áreas
      if (areasProvider.areas.isNotEmpty) {
        debugPrint(
            'Áreas cargadas con éxito: ${areasProvider.areas.length} áreas');
      } else {
        debugPrint('No se cargaron áreas o la lista está vacía');

        // Si no hay áreas, cargar algunas predeterminadas
        _loadDefaultAreas(areasProvider);
      }
    } catch (e, stackTrace) {
      debugPrint('Error al cargar áreas: $e');
      debugPrint('Stack trace: $stackTrace');

      // Cargar áreas predeterminadas en caso de error
      _loadDefaultAreas(areasProvider);

      // Mostrar un mensaje de error más informativo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Error al cargar áreas. Usando áreas predeterminadas.'),
            backgroundColor: Colors.amber.shade700,
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _loadAreas,
              textColor: Colors.white,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAreas = false;
        });
      }
    }
  }

  // Método auxiliar para cargar áreas predeterminadas
  void _loadDefaultAreas(AreasProvider areasProvider) {
    // Verificar si el AreasProvider tiene un método para agregar áreas predeterminadas
    if (areasProvider.areas.isEmpty) {
      debugPrint(
          'Se cargaron áreas predeterminadas: ${areasProvider.areas.length} áreas');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE0E5EC),
        centerTitle: true,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Mostrar un indicador si se están cargando áreas
          if (_isLoadingAreas)
            Container(
              margin: const EdgeInsets.only(right: 10),
              width: 20,
              height: 20,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D3748)),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2D3748)),
            onPressed: () {
              // Al refrescar manualmente, forzamos la recarga de todo
              _loadWorkers();
              _loadAreas();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingWorkers
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Cargando datos...',
                      style: TextStyle(
                        color: Color(0xFF718096),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  // Recargar ambos datos al hacer pull-to-refresh
                  await _loadWorkers();
                  await _loadAreas();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Cifras(),
                        const SizedBox(height: 24),
                        QuickActions(),
                        const SizedBox(height: 24),
                        RecentOps(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
