import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/widgets/assingments/activeAssignments.dart';
import 'package:plannerop/widgets/assingments/pendingAssignments.dart';
import 'package:plannerop/widgets/assingments/historyAssignments.dart';
import 'package:plannerop/widgets/assingments/addAssignmentDialog.dart';

class AsignacionesTab extends StatefulWidget {
  const AsignacionesTab({super.key});

  @override
  _AsignacionesTabState createState() => _AsignacionesTabState();
}

class _AsignacionesTabState extends State<AsignacionesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isSearching = false;
  bool _showFloatingSearchBar = false;

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
      backgroundColor: const Color(0xFFE0E5EC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE0E5EC),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar asignaciones...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF718096)),
                    onPressed: _clearSearch,
                  ),
                ),
                style: const TextStyle(color: Color(0xFF2D3748)),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text(
                'Asignaciones',
                style: TextStyle(
                  color: Color(0xFF2D3748),
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.cancel : Icons.search,
              color: const Color(0xFF718096),
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
          // Botón para mostrar estadísticas o información adicional
          IconButton(
            icon: const Icon(
              Icons.pie_chart_outline,
              color: Color(0xFF718096),
            ),
            onPressed: () {
              // Mostrar estadísticas o información de resumen
              _showStatisticsModal(context);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF3182CE),
              indicatorWeight: 3,
              labelColor: const Color(0xFF2D3748),
              unselectedLabelColor: const Color(0xFF718096),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Pendientes'),
                Tab(text: 'En Proceso'),
                Tab(text: 'Finalizadas'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña de asignaciones pendientes
          PendingAssignmentsView(searchQuery: _searchQuery),

          // Pestaña de asignaciones activas (en proceso)
          ActiveAssignmentsView(searchQuery: _searchQuery),

          // Pestaña de asignaciones completadas (historial)
          HistoryAssignmentsView(searchQuery: _searchQuery),
        ],
      ),
      floatingActionButton: NeumorphicFloatingActionButton(
        child: const Icon(Icons.add, color: Colors.white),
        style: const NeumorphicStyle(
          color: Color(0xFF3182CE),
          depth: 4,
          intensity: 0.6,
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddAssignmentDialog(),
          );
        },
      ),
    );
  }

  void _showStatisticsModal(BuildContext context) {
    final assignmentsProvider =
        Provider.of<AssignmentsProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3182CE).withOpacity(0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Estadísticas de Asignaciones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjetas con estadísticas
                      Row(
                        children: [
                          _buildStatCard(
                            'Pendientes',
                            '${assignmentsProvider.pendingAssignments.length}',
                            const Color(0xFFF6AD55),
                            Icons.pending_actions_outlined,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'En Proceso',
                            '${assignmentsProvider.inProgressAssignments.length}',
                            const Color(0xFF3182CE),
                            Icons.directions_run_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatCard(
                            'Completadas',
                            '${assignmentsProvider.completedAssignments.length}',
                            const Color(0xFF38A169),
                            Icons.check_circle_outline,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Total',
                            '${assignmentsProvider.assignments.length}',
                            const Color(0xFF718096),
                            Icons.summarize_outlined,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Asignaciones completadas por día',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Aquí iría un gráfico si tuvieras una biblioteca de gráficos
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Gráfico de estadísticas",
                          style: TextStyle(color: Color(0xFF718096)),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Trabajadores más activos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Lista de trabajadores más activos (simulada)
                      _buildTopWorkerItem('Carlos Méndez', '8 asignaciones'),
                      _buildTopWorkerItem('Ana Gutiérrez', '6 asignaciones'),
                      _buildTopWorkerItem('Roberto Sánchez', '5 asignaciones'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 3,
          intensity: 0.7,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopWorkerItem(String name, String stats) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                Colors.primaries[name.hashCode % Colors.primaries.length],
            radius: 18,
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  stats,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.trending_up,
            color: Color(0xFF38A169),
            size: 16,
          ),
        ],
      ),
    );
  }
}
