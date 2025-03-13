import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/pages/login.dart';
import 'package:plannerop/pages/supervisor/tabs/dashboard.dart';
import 'package:plannerop/pages/supervisor/tabs/asignaciones.dart';
import 'package:plannerop/pages/supervisor/tabs/reports.dart';
import 'package:plannerop/pages/supervisor/tabs/workers.dart';
import 'package:plannerop/store/auth.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/utils/toast.dart'; // Asegúrate de que exista este archivo

class SupervisorHome extends StatefulWidget {
  const SupervisorHome({super.key});

  @override
  _SupervisorHomeState createState() => _SupervisorHomeState();
}

class _SupervisorHomeState extends State<SupervisorHome> {
  int _selectedIndex = 0;
  int _previousIndex = 0;
  DateTime? _lastBackPressTime;

  // Usar claves globales para mantener el estado de cada tab
  final List<GlobalKey> _tabKeys = [
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey()
  ];

  // Registrar la última vez que se visitó cada tab
  Map<int, DateTime> _lastVisitTimes = {};

  // Crear tabs dinámicamente con claves para controlar su estado
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // Inicializar los widgets con sus claves
    _widgetOptions = [
      DashboardTab(key: _tabKeys[0]),
      AsignacionesTab(key: _tabKeys[1]),
      ReportesTab(key: _tabKeys[2]),
      WorkersTab(key: _tabKeys[3]),
    ];

    // Registrar el tiempo inicial para el primer tab
    _lastVisitTimes[_selectedIndex] = DateTime.now();
  }

  // Método para confirmar la salida
  Future<bool> _onWillPop() async {
    final now = DateTime.now();

    // Si el usuario presiona atrás dos veces rápidamente (dentro de 2 segundos), cerrar la app
    if (_lastBackPressTime != null &&
        now.difference(_lastBackPressTime!) < const Duration(seconds: 2)) {
      // Salir de la aplicación
      SystemNavigator.pop();
      return true;
    }

    // Primera vez que presiona atrás, mostrar diálogo de confirmación
    _lastBackPressTime = now;

    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // No cerrar sesión
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Sí cerrar sesión
            },
            child: const Text('Sí'),
          ),
        ],
      ),
    );

    // Si el usuario confirmó que quiere cerrar sesión
    if (shouldLogout == true) {
      // Cerrar sesión
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.clearAccessToken();

      // Navegar a la página de login y eliminar todas las rutas anteriores
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }

      return true; // Permitir el pop
    }

    // Mostrar mensaje al usuario
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presiona atrás de nuevo para salir de la aplicación'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    return false; // No permitir el comportamiento predeterminado del botón atrás
  }

  void _onItemTapped(int index) {
    // Si es el mismo tab, no hacemos nada
    if (index == _selectedIndex) return;

    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;

      // Registrar cuándo se visitó este tab
      _lastVisitTimes[index] = DateTime.now();

      // Actualizar datos del nuevo tab seleccionado
      _refreshTabData(index);
    });
  }

  // Método para refrescar los datos del tab seleccionado
  void _refreshTabData(int tabIndex) {
    // Calcular tiempo desde la última visita
    final previousVisit = _lastVisitTimes[tabIndex];
    final now = DateTime.now();

    // Solo refrescar si es una visita nueva o ha pasado tiempo suficiente
    final needsRefresh =
        previousVisit == null || now.difference(previousVisit).inMinutes > 1;

    if (needsRefresh) {
      // Obtener el contexto después de que el frame se haya renderizado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (tabIndex == 0) {
          // Refrescar Dashboard
          _refreshDashboard();
        } else if (tabIndex == 1) {
          // Refrescar Asignaciones
          _refreshAsignaciones();
        } else if (tabIndex == 2) {
          // Refrescar Reportes
          _refreshReportes();
        } else if (tabIndex == 3) {
          // Refrescar Trabajadores
          _refreshWorkers();
        }
      });
    }
  }

  // Métodos específicos para refrescar cada tab
  void _refreshDashboard() {
    debugPrint('🔄 Refrescando Dashboard...');
    final assignmentsProvider =
        Provider.of<AssignmentsProvider>(context, listen: false);
    // Actualizar silenciosamente sin mostrar indicadores de carga
    assignmentsProvider.refreshActiveAssignments(context);
  }

  void _refreshAsignaciones() {
    debugPrint('🔄 Refrescando Asignaciones...');
    final assignmentsProvider =
        Provider.of<AssignmentsProvider>(context, listen: false);
    // Refrescar solo asignaciones activas y pendientes
    assignmentsProvider.refreshActiveAssignments(context);
  }

  void _refreshReportes() {
    // No requiere actualización automática, pues normalmente usa datos históricos
    debugPrint('🔄 Reportes seleccionado (no requiere refresco automático)');
  }

  void _refreshWorkers() {
    debugPrint('🔄 Refrescando Trabajadores...');
    // Usar el mecanismo existente en WorkersProvider si existe
    // (esto dependerá de tu implementación actual)
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Neumorphic(
            style: NeumorphicStyle(
              depth: -3,
              intensity: 0.8,
              color: const Color(0xFF3182CE),
            ),
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withOpacity(0.6),
              selectedFontSize: 12,
              unselectedFontSize: 10,
              items: [
                _buildNavigationItem(
                    Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
                _buildNavigationItem(Icons.assignment_outlined,
                    Icons.assignment, 'Asignaciones'),
                _buildNavigationItem(Icons.insert_chart_outlined,
                    Icons.insert_chart, 'Reportes'),
                _buildNavigationItem(
                    Icons.groups_outlined, Icons.groups, 'Trabajadores'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavigationItem(
      IconData iconOutlined, IconData iconFilled, String label) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Icon(iconOutlined, size: 24),
      ),
      activeIcon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          children: [
            Icon(iconFilled, size: 24),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
      label: label,
    );
  }
}
