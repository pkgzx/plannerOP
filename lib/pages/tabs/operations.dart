import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/store/programmings.dart';
import 'package:plannerop/widgets/operations/views/activeOperations.dart';
import 'package:plannerop/widgets/operations/pendingOperations.dart';
import 'package:plannerop/widgets/operations/views/historyOperations.dart';
import 'package:plannerop/widgets/operations/add/addOperationDialog.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class OperationsTab extends StatefulWidget {
  const OperationsTab({super.key});

  @override
  _OperationsTabState createState() => _OperationsTabState();
}

class _OperationsTabState extends State<OperationsTab>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isSearching = false;
  Timer? _urgentCheckTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Animación para el badge pulsante
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _tabController.addListener(() {
      if (_isSearching) {
        setState(() {
          _isSearching = false;
          _searchQuery = "";
          _searchController.clear();
        });
      }
    });

    // Verificación automática cada 2 minutos
    _startUrgentCheckTimer();
  }

  void _startUrgentCheckTimer() {
    _urgentCheckTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted) {
        final programmingsProvider =
            Provider.of<ProgrammingsProvider>(context, listen: false);
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        programmingsProvider.fetchProgrammingsByDate(today, context);
      }
    });
  }

  @override
  void dispose() {
    _urgentCheckTimer?.cancel();
    _urgentCheckTimer = null;

    // Dispose de otros controladores
    _tabController.dispose();
    _searchController.dispose();
    _pulseController.dispose();

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: const Color(0xFF4299E1),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar operaciones...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: _clearSearch,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text(
                'Operaciones',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.cancel : Icons.search,
              color: Colors.white,
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
          preferredSize: const Size.fromHeight(48.0),
          child: Consumer<ProgrammingsProvider>(
            builder: (context, programmingsProvider, child) {
              final overdueCount = programmingsProvider.overdueCount;

              // Controlar animación según hay programaciones vencidas
              if (overdueCount > 0) {
                _pulseController.repeat(reverse: true);
              } else {
                _pulseController.stop();
                _pulseController.reset();
              }

              return TabBar(
                controller: _tabController,
                tabs: [
                  // Tab con badge super visible y animado
                  Tab(
                    child: Text(
                      'Pendientes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Tab(
                      child: Text(
                    'Activas',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )),
                  Tab(
                    child: Text(
                      'Historial',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: Column(
        children: [
          // ========================
          // BANNER COMPACTO PERO EFECTIVO
          // ========================
          Consumer<ProgrammingsProvider>(
            builder: (context, programmingsProvider, child) {
              final overdueProgrammings =
                  programmingsProvider.overdueProgrammings;

              if (overdueProgrammings.isEmpty) return const SizedBox();

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Icono animado compacto
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red.shade600,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 12),

                      // Texto compacto pero impactante
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.shade400,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '🚨 URGENTE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${overdueProgrammings.length} VENCIDAS',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              overdueProgrammings.length == 1
                                  ? 'Una programación requiere atención inmediata'
                                  : '${overdueProgrammings.length} programaciones requieren atención inmediata',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Botones compactos
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () => _showCriticalProgrammingsDialog(
                                  overdueProgrammings),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red.shade600,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'VER',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ========================
          // CONTENIDO DE LAS TABS
          // ========================
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                PendingOperationsView(searchQuery: _searchQuery),
                const ActiveOperationsView(searchQuery: ''),
                const HistoryOperationsView(searchQuery: ''),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: NeumorphicFloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddOperationDialog(),
          );
        },
        tooltip: 'Agregar operación',
        style: NeumorphicStyle(
          shape: NeumorphicShape.convex,
          boxShape: const NeumorphicBoxShape.circle(),
          depth: 8,
          intensity: 0.65,
          surfaceIntensity: 0.15,
          lightSource: LightSource.topLeft,
          color: Colors.blue,
          shadowLightColor: Colors.white.withOpacity(0.6),
          shadowDarkColor: Colors.grey.withOpacity(0.3),
        ),
        child: const Icon(
          Icons.add,
          color: Color.fromARGB(255, 255, 255, 255),
          size: 30,
        ),
      ),
    );
  }

  void _showCriticalProgrammingsDialog(List<dynamic> overdueProgrammings) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade600, Colors.red.shade500],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Programaciones Vencidas',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  '${overdueProgrammings.length} programaciones requieren atención inmediata',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: overdueProgrammings.length,
                  itemBuilder: (context, index) {
                    final programming = overdueProgrammings[index];
                    return _buildCompactDialogItem(programming, index);
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDialogItem(dynamic programming, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Colors.red.shade600,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.red.shade600,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  programming.client ?? 'Cliente desconocido',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  programming.service ?? 'Servicio no especificado',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Hora: ${programming.timeStart}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _getDelayText(programming),
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDelayText(dynamic programming) {
    try {
      final now = DateTime.now();
      final programmingDateTime =
          _combineDateAndTime(programming.dateStart, programming.timeStart);

      final difference = now.difference(programmingDateTime);

      if (difference.inHours > 24) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inMinutes}min';
      }
    } catch (e) {
      return 'Vencida';
    }
  }

  DateTime _combineDateAndTime(String dateStr, String timeStr) {
    final date = DateTime.parse(dateStr);
    final timeParts = timeStr.split(':');
    final hours = int.parse(timeParts[0]);
    final minutes = int.parse(timeParts[1]);

    return DateTime(date.year, date.month, date.day, hours, minutes);
  }
}
