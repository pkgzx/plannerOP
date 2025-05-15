import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/utils/assignments.dart';
import 'package:plannerop/widgets/assingments/components/UnifiedAssignmentCard.dart';
import 'package:plannerop/widgets/assingments/components/buildWorkerItem.dart';
import 'package:plannerop/widgets/assingments/emptyState.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HistoryAssignmentsView extends StatefulWidget {
  final String searchQuery;

  const HistoryAssignmentsView({
    Key? key,
    required this.searchQuery,
  }) : super(key: key);

  @override
  State<HistoryAssignmentsView> createState() => _HistoryAssignmentsViewState();
}

class _HistoryAssignmentsViewState extends State<HistoryAssignmentsView> {
  String? _selectedArea;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showFilters = false;
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    // Inicializar los datos de localización
    initializeDateFormatting('es').then((_) {
      if (mounted) {
        setState(() {
          _localeInitialized = true;
        });
      }
    });
  }

  List<Assignment> _filterAssignments(List<Assignment> assignments) {
    return assignments.where((assignment) {
      // Filtro de búsqueda por texto
      bool matchesSearch = widget.searchQuery.isEmpty ||
          assignment.task
              .toLowerCase()
              .contains(widget.searchQuery.toLowerCase()) ||
          assignment.area
              .toLowerCase()
              .contains(widget.searchQuery.toLowerCase()) ||
          assignment.workers.any((worker) => worker.name
              .toString()
              .toLowerCase()
              .contains(widget.searchQuery.toLowerCase()));

      // Filtro por área
      bool matchesArea =
          _selectedArea == null || assignment.area == _selectedArea;

      // Filtro por fecha
      bool matchesDate = true;
      if (_startDate != null) {
        matchesDate = assignment.endDate != null &&
            !assignment.endDate!.isBefore(_startDate!);
      }
      if (_endDate != null && matchesDate) {
        // Añadir un día al endDate para incluir todo ese día
        final nextDay =
            DateTime(_endDate!.year, _endDate!.month, _endDate!.day + 1);
        matchesDate =
            assignment.endDate != null && assignment.endDate!.isBefore(nextDay);
      }

      return matchesSearch && matchesArea && matchesDate;
    }).toList();
  }

  List<String> _getUniqueAreas(List<Assignment> assignments) {
    final Set<String> areas = {};
    for (var assignment in assignments) {
      areas.add(assignment.area);
    }
    return areas.toList()..sort();
  }

  String _formatMonth(DateTime date) {
    // Usar formato personalizado si la localización está inicializada
    if (_localeInitialized) {
      return DateFormat('MMMM yyyy', 'es').format(date);
    } else {
      // Fallback a formato sin localización
      String month = DateFormat('MMMM').format(date);
      return '$month ${date.year}';
    }
  }

  DateTime _parseMonth(String monthStr) {
    try {
      if (_localeInitialized) {
        return DateFormat('MMMM yyyy', 'es').parse(monthStr);
      } else {
        // Intentar parsear formato sin localización
        List<String> parts = monthStr.split(' ');
        if (parts.length >= 2) {
          String month = parts[0];
          int year = int.parse(parts[1]);
          return DateTime(year, DateFormat('MMMM').parseStrict(month).month, 1);
        }
        return DateTime.now();
      }
    } catch (e) {
      // Si hay error, devolver fecha actual
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssignmentsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Obtener todas las asignaciones y ordenarlas por fecha más reciente
        final allCompletedAssignments = provider.completedAssignments;

        // Ordenar las asignaciones por fecha de finalización (más reciente primero)
        allCompletedAssignments.sort((a, b) {
          return (b.endDate ?? DateTime.now())
              .compareTo(a.endDate ?? DateTime.now());
        });

        // Limitar a 30 asignaciones más recientes
        final completedAssignments = allCompletedAssignments.length > 30
            ? allCompletedAssignments.sublist(0, 30)
            : allCompletedAssignments;

        final filteredAssignments = _filterAssignments(completedAssignments);
        final uniqueAreas = _getUniqueAreas(completedAssignments);

        if (completedAssignments.isEmpty) {
          return const EmptyState(
            message: 'No hay asignaciones completadas.',
            showClearButton: false,
          );
        }

        if (filteredAssignments.isEmpty) {
          return EmptyState(
            message:
                'No hay asignaciones que coincidan con los filtros aplicados.',
            showClearButton: widget.searchQuery.isNotEmpty ||
                _selectedArea != null ||
                _startDate != null ||
                _endDate != null,
            onClear: () {
              setState(() {
                _selectedArea = null;
                _startDate = null;
                _endDate = null;
              });
            },
          );
        }

        // Agrupar por mes basado en la fecha de completado
        final Map<String, List<Assignment>> groupedByMonth = {};
        for (var assignment in filteredAssignments) {
          if (assignment.endDate != null) {
            final month = _formatMonth(assignment.endDate!);
            if (!groupedByMonth.containsKey(month)) {
              groupedByMonth[month] = [];
            }
            groupedByMonth[month]!.add(assignment);
          }
        }

        // Ordenar las llaves (meses) en orden decreciente para mostrar los meses más recientes primero
        final sortedMonths = groupedByMonth.keys.toList()
          ..sort((a, b) {
            final dateA = _parseMonth(a);
            final dateB = _parseMonth(b);
            return dateB.compareTo(dateA); // Orden decreciente
          });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Historial de Operaciones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _showFilters ? Icons.filter_list_off : Icons.filter_list,
                      color: _showFilters
                          ? const Color(0xFF3182CE)
                          : const Color(0xFF718096),
                    ),
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                  ),
                ],
              ),

              if (_showFilters) ...[
                const SizedBox(height: 16),
                _buildFilters(uniqueAreas),
                const Divider(height: 32),
              ],

              const SizedBox(height: 8),

              // Contador de resultados
              Text(
                '${filteredAssignments.length} asignaciones encontradas',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF718096),
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 16),

              ...sortedMonths.map((month) {
                final assignments = groupedByMonth[month]!;

                // Ordenar por fecha (más reciente primero)
                assignments.sort((a, b) {
                  return (b.endDate ?? DateTime.now())
                      .compareTo(a.endDate ?? DateTime.now());
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3182CE).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            size: 18,
                            color: Color(0xFF3182CE),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            // Capitalizar primera letra si es necesario
                            month.substring(0, 1).toUpperCase() +
                                month.substring(1),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3182CE),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3182CE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${assignments.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...assignments.map(
                      (assignment) => UnifiedAssignmentCard(
                        assignment: assignment,
                        onTap: _showAssignmentDetails,
                        statusColor: const Color(0xFF38A169),
                        statusText: 'COMPLETADA',
                        showCompletionDate: true,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters(List<String> areas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filtros',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 12),

        // Filtro de área
        const Text(
          'Área',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedArea,
              hint: const Text('Todas las áreas'),
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              icon: const Icon(Icons.arrow_drop_down),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Todas las áreas'),
                ),
                ...areas
                    .map((area) => DropdownMenuItem<String>(
                          value: area,
                          child: Text(area),
                        ))
                    .toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedArea = value;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Botón de limpiar filtros
        Center(
          child: NeumorphicButton(
            style: NeumorphicStyle(
              depth: 2,
              intensity: 0.7,
              color: Colors.white,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                _selectedArea = null;
                _startDate = null;
                _endDate = null;
              });
            },
            child: const Text(
              'Limpiar Filtros',
              style: TextStyle(
                color: Color(0xFF718096),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAssignmentDetails(BuildContext context, Assignment assignment) {
    showAssignmentDetails(
      context: context,
      assignment: assignment,
      statusColor: const Color(0xFF38A169),
      statusText: "Completada",
      workersBuilder: (assignment, context) {
        // Build workers groups if any
        List<Widget> sections = [];

        if (assignment.groups.any((group) {
          final groupWorkers = assignment.workers
              .where((w) => group.workers.contains(w.id))
              .toList();
          return groupWorkers.isNotEmpty;
        })) {
          sections.add(
            buildDetailSection(
              title: 'Grupos de Trabajadores',
              children: assignment.groups
                  .map((group) {
                    // Process each group...
                    final groupWorkers = assignment.workers
                        .where((w) => group.workers.contains(w.id))
                        .toList();

                    if (groupWorkers.isEmpty) return Container();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group header
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6FFFA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  group.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${groupWorkers.length} trabajadores',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4A5568),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Workers list
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: groupWorkers
                                .map((worker) => buildWorkerItem(
                                    worker, context,
                                    isFinished: true))
                                .toList(),
                          ),
                        ),
                      ],
                    );
                  })
                  .where((widget) => widget != Container())
                  .toList(),
            ),
          );
        }

        // Add individual workers section
        final Set<int> groupedWorkerIds = {};
        for (var group in assignment.groups) {
          groupedWorkerIds.addAll(group.workers);
        }

        final individualWorkers = assignment.workers
            .where((worker) => !groupedWorkerIds.contains(worker.id))
            .toList();

        if (individualWorkers.isNotEmpty) {
          sections.add(
            buildDetailSection(
              title: 'Trabajadores Individuales',
              children: individualWorkers
                  .map((worker) =>
                      buildWorkerItem(worker, context, isFinished: true))
                  .toList(),
            ),
          );
        }

        // Add finished workers section if applicable
        if (assignment.workersFinished.isNotEmpty) {
          sections.add(
            buildDetailSection(
              title: 'Trabajadores Finalizados',
              children: assignment.workersFinished
                  .map((worker) =>
                      buildWorkerItem(worker, context, isFinished: true))
                  .toList(),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections,
        );
      },
    );
  }
}

// Clase auxiliar para los detalles
class DetailItem {
  final IconData icon;
  final String label;
  final String value;

  DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
