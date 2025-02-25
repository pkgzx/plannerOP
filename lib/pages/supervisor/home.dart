import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/pages/supervisor/tabs/dashboard.dart';

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
      appBar: AppBar(
        title: const Text('Bienvenido, Supervisor'),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Neumorphic(
        style: NeumorphicStyle(
          depth: -4,
          intensity: 0.8,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard 📊',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: 'Asignaciones 📋',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report),
              label: 'Reportes 📑',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Perfil ⚙️',
            ),
          ],
        ),
      ),
    );
  }
}

class AsignacionesTab extends StatelessWidget {
  const AsignacionesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Lista de trabajadores con búsqueda'),
          SizedBox(height: 10),
          Text('Asignar trabajador a zona y horario'),
          SizedBox(height: 10),
          Text('Editar / eliminar asignaciones'),
        ],
      ),
    );
  }
}

class ReportesTab extends StatelessWidget {
  const ReportesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Historial de asignaciones'),
          SizedBox(height: 10),
          Text('Filtros por fecha, zona o trabajador'),
          SizedBox(height: 10),
          Text('Exportar PDF / Excel'),
        ],
      ),
    );
  }
}

class PerfilTab extends StatelessWidget {
  const PerfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Configuración de cuenta'),
          SizedBox(height: 10),
          Text('Cambio de contraseña'),
          SizedBox(height: 10),
          Text('Cerrar sesión'),
        ],
      ),
    );
  }
}
