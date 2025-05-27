import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/widgets/operations/activeOperations.dart';
import 'package:plannerop/widgets/operations/pendingOperations.dart';
import 'package:plannerop/widgets/operations/historyOperations.dart';
import 'package:plannerop/widgets/operations/add/addOperationDialog.dart';

class OperationsTab extends StatefulWidget {
  const OperationsTab({super.key});

  @override
  _OperationsTabState createState() => _OperationsTabState();
}

class _OperationsTabState extends State<OperationsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Cerrar la barra de búsqueda al cambiar de pestaña
      if (_isSearching) {
        setState(() {
          _isSearching = false;
          _searchQuery = "";
          _searchController.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = "";
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Cambio a fondo blanco para consistencia
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor:
            const Color(0xFF4299E1), // Cambio a azul como en otros componentes
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar operaciones...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.7)), // Texto más claro
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear,
                        color: Colors.white), // Icono blanco
                    onPressed: _clearSearch,
                  ),
                ),
                style: const TextStyle(color: Colors.white), // Texto blanco
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text(
                'Operaciones',
                style: TextStyle(
                  color: Colors.white, // Texto blanco
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.cancel : Icons.search,
              color: Colors.white, // Icono blanco
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = "";
                  _searchController.clear();
                }
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            // Contenedor para dar un fondo completo a la TabBar
            decoration: const BoxDecoration(
              color: Color(0xFF4299E1), // Fondo azul
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
              child: TabBar(
                controller: _tabController,
                indicatorColor:
                    Colors.white, // Indicador en blanco para contraste
                indicatorWeight: 3,
                labelColor: Colors.white, // Etiqueta seleccionada en blanco
                unselectedLabelColor: Colors.white
                    .withOpacity(0.7), // No seleccionado semi-transparente
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.normal),
                tabs: const [
                  Tab(text: 'Pendientes'),
                  Tab(text: 'En Curso'),
                  Tab(text: 'Finalizadas'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña de asignaciones pendientes
          PendingOperationsView(searchQuery: _searchQuery),

          // Pestaña de asignaciones activas (en proceso)
          ActiveOperationsView(searchQuery: _searchQuery),

          // Pestaña de asignaciones completadas (historial)
          HistoryOperationsView(searchQuery: _searchQuery),
        ],
      ),
      floatingActionButton: NeumorphicFloatingActionButton(
        child: const Icon(Icons.add, color: Colors.white),
        style: NeumorphicStyle(
          color: const Color(0xFF4299E1), // Cambio a azul consistente
          depth: 4,
          intensity: 0.6,
          boxShape: NeumorphicBoxShape.roundRect(
              BorderRadius.circular(30)), // Más redondeado
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddOperationDialog(),
          );
        },
      ),
    );
  }
}
