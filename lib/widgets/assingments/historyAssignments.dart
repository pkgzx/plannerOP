import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:plannerop/widgets/assingments/emptyState.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Añadir esta importación

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

        final completedAssignments = provider.completedAssignments;
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
                    'Historial de Asignaciones',
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
                    ...assignments
                        .map((assignment) => _buildAssignmentCard(assignment)),
                    const SizedBox(height: 24),
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

        // Filtro de rango de fechas
        const Text(
          'Rango de Fechas',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked;
                      // Si la fecha de inicio es posterior a la fecha de fin, actualizar la fecha de fin
                      if (_endDate != null && _startDate!.isAfter(_endDate!)) {
                        _endDate = _startDate;
                      }
                    });
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Color(0xFF718096),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _startDate == null
                            ? 'Desde'
                            : DateFormat('dd/MM/yyyy').format(_startDate!),
                        style: TextStyle(
                          color: _startDate == null
                              ? const Color(0xFF718096)
                              : const Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _endDate = picked;
                    });
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Color(0xFF718096),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _endDate == null
                            ? 'Hasta'
                            : DateFormat('dd/MM/yyyy').format(_endDate!),
                        style: TextStyle(
                          color: _endDate == null
                              ? const Color(0xFF718096)
                              : const Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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

  Widget _buildAssignmentCard(Assignment assignment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 4,
          intensity: 0.5,
          color: Colors.white,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
          lightSource: LightSource.topLeft,
          shadowDarkColorEmboss: Colors.grey.withOpacity(0.2),
          shadowLightColorEmboss: Colors.white,
        ),
        child: InkWell(
          onTap: () => _showAssignmentDetails(context, assignment),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: const Color(0xFF38A169),
                  width: 4,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment.task,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.room_outlined,
                                size: 14,
                                color: Color(0xFF718096),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  assignment.area,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF718096),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Completed status - Elegante insignia de estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38A169).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF38A169),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'COMPLETADA',
                            style: TextStyle(
                              color: Color(0xFF38A169),
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Completed date with elegant icon
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38A169).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: Color(0xFF38A169),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy')
                            .format(assignment.endDate ?? DateTime.now()),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF38A169),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Elegant separator
                Container(
                  height: 1,
                  color: const Color(0xFFEDF2F7),
                  margin: const EdgeInsets.only(bottom: 12),
                ),

                // Footer with workers and time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Workers count
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF718096).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.people_outline,
                            size: 12,
                            color: const Color(0xFF718096),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${assignment.workers.length} trabajador${assignment.workers.length > 1 ? 'es' : ''}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Tiempo de la tarea (si está disponible)
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 12,
                          color: Color(0xFF718096),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          assignment.time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF718096),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Workers chips - mostrar si hay pocos trabajadores
                if (assignment.workers.isNotEmpty &&
                    assignment.workers.length <= 3) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: assignment.workers.map((worker) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6FFFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF38A169).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 8,
                              backgroundColor: Colors.primaries[
                                  worker.name.hashCode %
                                      Colors.primaries.length],
                              child: Text(
                                worker.name
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              worker.name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2C7A7B),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAssignmentDetails(BuildContext context, Assignment assignment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
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
                  color: const Color(0xFF38A169).withOpacity(0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Detalles de la Asignación',
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
                    Text(
                      assignment.task,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF38A169),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Assignment information
                      _buildDetailSection(
                        title: 'Información',
                        items: [
                          DetailItem(
                            icon: Icons.room_outlined,
                            label: 'Área:',
                            value: assignment.area,
                          ),
                          DetailItem(
                            icon: Icons.calendar_today_outlined,
                            label: 'Fecha programada:',
                            value: DateFormat('dd/MM/yyyy')
                                .format(assignment.date),
                          ),
                          DetailItem(
                            icon: Icons.schedule_outlined,
                            label: 'Hora programada:',
                            value: assignment.time,
                          ),
                          DetailItem(
                            label: 'Hora de finalización:',
                            value: assignment.endTime ?? 'No especificada',
                            icon: Icons.timer_outlined,
                          ),
                          DetailItem(
                            icon: Icons.check_circle_outline,
                            label: 'Completada el:',
                            value: DateFormat('dd/MM/yyyy HH:mm')
                                .format(assignment.endDate ?? DateTime.now()),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Workers section
                      const Text(
                        'Trabajadores Asignados',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Workers list
                      ...assignment.workers.map((worker) {
                        return _buildWorkerItem(worker);
                      }),
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

  Widget _buildDetailSection({
    required String title,
    required List<DetailItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.icon,
                  size: 16,
                  color: const Color(0xFF718096),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildWorkerItem(Worker worker) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: Colors
                  .primaries[worker.name.hashCode % Colors.primaries.length],
              radius: 20,
              child: Text(
                worker.name.toString().substring(0, 1).toUpperCase(),
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
                    worker.name.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  if (worker.area.isNotEmpty)
                    Text(
                      worker.area.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF718096),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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
