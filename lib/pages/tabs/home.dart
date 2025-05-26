import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/pages/login.dart';
import 'package:plannerop/pages/tabs/operations.dart';
import 'package:plannerop/pages/tabs/dashboard.dart';
import 'package:plannerop/pages/tabs/reports.dart';
import 'package:plannerop/pages/tabs/workers.dart';

import 'package:plannerop/store/auth.dart';
import 'package:plannerop/store/user.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/utils/toast.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  DateTime? _lastBackPressTime;

  // Registrar la última vez que se visitó cada tab
  final Map<int, DateTime> _lastVisitTimes = {};

  // Crear tabs dinámicamente con claves para controlar su estado
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // Inicializar los widgets con sus claves
    _widgetOptions = [
      DashboardTab(),
      AsignacionesTab(),
      ReportesTab(),
      WorkersTab(),
    ];

    // Registrar el tiempo inicial para el primer tab
    _lastVisitTimes[_selectedIndex] = DateTime.now();
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();

    if (_lastBackPressTime != null &&
        now.difference(_lastBackPressTime!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return true;
    }

    _lastBackPressTime = now;

    // Captura las referencias a los providers antes de mostrar el diálogo
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              // IMPORTANTE: Primero cerramos el diálogo
              Navigator.of(context).pop(true);
            },
            child: const Text('Sí'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Mostrar un indicador de carga
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => PopScope(
            canPop: false,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }

      try {
        // IMPORTANTE: Usamos la referencia capturada anteriormente
        userProvider.clearUser();
        await authProvider.logout();

        // Una vez completado el logout, navegamos a la página de login
        if (mounted) {
          // IMPORTANTE: Usamos pushReplacement en lugar de pushAndRemoveUntil
          // Esto evita problemas con el contexto al desmontar widgets
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
        return true;
      } catch (e) {
        debugPrint('Error al cerrar sesión: $e');
        if (mounted) {
          // Cerrar el loader si está visible
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
          showErrorToast(context, 'Error al cerrar sesión');
        }
        return false;
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Presiona atrás de nuevo para salir de la aplicación'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return false;
    }
  }

  void _onItemTapped(int index) {
    // Si es el mismo tab, no hacemos nada
    if (index == _selectedIndex) return;

    // Verificar si el usuario es de GESTION HUMANA y está intentando acceder a tabs restringidos
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user.cargo == "GESTION HUMANA" && (index == 1 || index == 2)) {
      // Mostrar mensaje informando que no tiene permiso
      showAlertToast(context, 'No tienes permiso para acceder a este tab');
      return; // Prevenir navegación a los tabs restringidos
    }

    setState(() {
      _selectedIndex = index;

      // Registrar cuándo se visitó este tab
      _lastVisitTimes[index] = DateTime.now();

      // Actualizar datos del nuevo tab seleccionado
      _refreshTabData(index);
    });
  }

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
        }
      });
    }
  }

  // Métodos específicos para refrescar cada tab
  void _refreshDashboard() {
    // debugPrint('🔄 Refrescando Dashboard...');
    final assignmentsProvider =
        Provider.of<AssignmentsProvider>(context, listen: false);
    // Actualizar silenciosamente sin mostrar indicadores de carga
    assignmentsProvider.refreshActiveAssignments(context);
  }

  void _refreshAsignaciones() {
    // debugPrint('🔄 Refrescando Asignaciones...');
    final assignmentsProvider =
        Provider.of<AssignmentsProvider>(context, listen: false);
    // Refrescar solo asignaciones activas y pendientes
    assignmentsProvider.refreshActiveAssignments(context);
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
                _buildNavigationItem(
                    Icons.assignment_outlined, Icons.assignment, 'Operaciones'),
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
