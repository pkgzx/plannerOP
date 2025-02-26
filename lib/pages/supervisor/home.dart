import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/pages/supervisor/tabs/dashboard.dart';
import 'package:plannerop/pages/supervisor/tabs/asignaciones.dart';
import 'package:plannerop/pages/supervisor/tabs/reports.dart';
import 'package:plannerop/pages/supervisor/tabs/profile.dart';

class SupervisorHome extends StatefulWidget {
  const SupervisorHome({super.key});

  @override
  _SupervisorHomeState createState() => _SupervisorHomeState();
}

class _SupervisorHomeState extends State<SupervisorHome> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardTab(),
    AsignacionesTab(),
    ReportesTab(),
    PerfilTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Neumorphic(
          style: NeumorphicStyle(
            depth: -3,
            intensity: 0.8,
            color: const Color(0xFF3182CE), // Color azul moderno como base
          ),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors
                .transparent, // Fondo transparente para mostrar el color del Neumorphic
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
                  Icons.assignment_outlined, Icons.assignment, 'Asignaciones'),
              _buildNavigationItem(
                  Icons.insert_chart_outlined, Icons.insert_chart, 'Reportes'),
              _buildNavigationItem(
                  Icons.person_outline, Icons.person, 'Perfil'),
            ],
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
