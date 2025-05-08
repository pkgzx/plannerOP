import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/store/areas.dart';
import 'package:plannerop/store/chargersOp.dart';
import 'package:plannerop/store/feedings.dart';
import 'package:plannerop/store/workers.dart';

import 'package:plannerop/utils/toast.dart';
import 'package:plannerop/widgets/assingments/components/buildWorkerItem.dart';
import 'package:plannerop/widgets/assingments/editAssignmentForm.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/store/assignments.dart';
import 'package:plannerop/widgets/assingments/emptyState.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:plannerop/widgets/assingments/components/showCompletionDialog.dart';
import 'package:plannerop/widgets/assingments/components/utils.dart';

// Actualizar ActiveAssignmentsView para mostrar indicador sutil de actualización
class ActiveAssignmentsView extends StatefulWidget {
  final String searchQuery;

  const ActiveAssignmentsView({Key? key, required this.searchQuery})
      : super(key: key);

  @override
  _ActiveAssignmentsViewState createState() => _ActiveAssignmentsViewState();
}

class _ActiveAssignmentsViewState extends State<ActiveAssignmentsView> {
  String? _selectedArea;
  int? _selectedSupervisorId;
  bool _showFilters = false;
  Map<int, bool> alimentacionStatus = {};

  List<String> _determinateFoods(String? horaInicio, String? horaFin) {
    List<String> foods = [];

    // 1. Obtener la hora actual
    DateTime now = DateTime.now();
    // TimeOfDay currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
    TimeOfDay currentTime = TimeOfDay(hour: 18, minute: 31); // Para pruebas
    int currentMinutes = currentTime.hour * 60 + currentTime.minute;

    // 2. Convertir strings de hora a objetos TimeOfDay para la operación
    TimeOfDay? inicio =
        horaInicio != null ? _parseTimeString(horaInicio) : null;
    TimeOfDay? fin = horaFin != null ? _parseTimeString(horaFin) : null;

    if (inicio == null) return foods; // Sin hora de inicio, no hay comidas

    // Convertir horas a minutos para facilitar comparaciones
    int inicioMinutos = inicio.hour * 60 + inicio.minute;
    int finMinutos = fin != null
        ? fin.hour * 60 + fin.minute
        : inicioMinutos + 480; // Asumir 8 horas de duración por defecto

    // Si la operación termina antes que inicia, asumimos que cruza la medianoche
    if (finMinutos < inicioMinutos) {
      finMinutos += 24 * 60; // Sumar un día completo
    }

    // 3. Definir horarios exactos de comidas
    int desayunoHora = 6 * 60; // 6:00 am
    int almuerzoHora = 12 * 60; // 12:00 pm
    int cenaHora = 18 * 60; // 6:00 pm
    int mediaNocheHora = 0; // 00:00 am

    // 4. Definir periodos extendidos para cada comida
    int periodoDesayuno = 10 * 60; // Desayuno relevante hasta las 10 am
    int periodoAlmuerzo = 16 * 60; // Almuerzo relevante hasta las 4 pm
    int periodoCena = 21 * 60; // Cena relevante hasta las 9 pm
    int periodoMediaNoche = 3 * 60; // Media noche relevante hasta las 3 am

    // Verificar si la operación está activa o ya ocurrió durante el día actual
    bool operacionEnCursoHoy = (inicioMinutos <= currentMinutes) &&
        (finMinutos >= currentMinutes || fin == null);

    if (operacionEnCursoHoy) {
      // LÓGICA CORREGIDA: Dar derecho a comida si:
      // 1. La operación comienza ESTRICTAMENTE ANTES de la hora de la comida Y termina después
      // O 2. La operación está activa durante el periodo de la comida
      List<String> todasLasComidas = [];

      // Verificar qué comidas corresponden a esta operación
      // Desayuno - 6:00 am - Solo si comienza ANTES de las 6:00 am y termina después
      if ((inicioMinutos < desayunoHora)) {
        todasLasComidas.add('Desayuno');
      }

      // Almuerzo - 12:00 pm - Solo si comienza ANTES de las 12:00 pm y termina después
      if (inicioMinutos < almuerzoHora || finMinutos >= almuerzoHora) {
        todasLasComidas.add('Almuerzo');
      }

      // Cena - 6:00 pm - Solo si comienza ANTES de las 6:00 pm y termina después
      if (inicioMinutos < cenaHora || finMinutos >= cenaHora) {
        todasLasComidas.add('Cena');
      }

      // Media noche - 00:00 am - Caso especial debido al cruce de la medianoche
      // Media noche sin cruce de día - Solo si comienza ANTES de las 00:00 am
      if (inicioMinutos < mediaNocheHora || finMinutos >= mediaNocheHora) {
        todasLasComidas.add('Media noche');
      }
      // Media noche con cruce de día (inicio tardío, después de las 8pm)
      else if (inicioMinutos >= 20 * 60) {
        int mediaNocheAjustada =
            mediaNocheHora + 24 * 60; // 00:00 del día siguiente
        if (inicioMinutos < mediaNocheAjustada &&
            finMinutos >= mediaNocheAjustada) {
          todasLasComidas.add('Media noche');
        }
      }

      // Si no hay comidas, retornar lista vacía
      if (todasLasComidas.isEmpty) return foods;

      // *** CORRECCIÓN AQUÍ: Determinar cuál comida mostrar según la hora actual ***
      // El problema está en la lógica para seleccionar la comida según la hora actual

      // Verificamos en qué franja horaria estamos actualmente
      String comidaAMostrar = '';

      if (currentMinutes >= mediaNocheHora &&
          currentMinutes <= periodoMediaNoche) {
        // Entre 12 am y 3 am: Mostrar media noche
        if (todasLasComidas.contains('Media noche')) {
          comidaAMostrar = 'Media noche';
        }
      } else if (currentMinutes >= desayunoHora &&
          currentMinutes <= periodoDesayuno) {
        // Entre 6 am y 10 am: Mostrar desayuno
        if (todasLasComidas.contains('Desayuno')) {
          comidaAMostrar = 'Desayuno';
        }
      } else if (currentMinutes >= almuerzoHora &&
          currentMinutes <= periodoAlmuerzo) {
        // Entre 12 pm y 4 pm: Mostrar almuerzo
        if (todasLasComidas.contains('Almuerzo')) {
          comidaAMostrar = 'Almuerzo';
        }
      } else if (currentMinutes >= cenaHora && currentMinutes <= periodoCena) {
        // Entre 6 pm y 9 pm: Mostrar cena
        // CORRECCIÓN: Asegurarse de que este bloque se ejecute correctamente
        debugPrint("Estamos en horario de cena");
        if (todasLasComidas.contains('Cena')) {
          comidaAMostrar = 'Cena';
          debugPrint("Esta operación tiene derecho a cena");
        } else {
          debugPrint("Esta operación NO tiene derecho a cena");
        }
      } else if (currentMinutes >= periodoMediaNoche &&
          currentMinutes <= desayunoHora) {
        // Esta condición está mal - corregir a:
        if (currentMinutes >= periodoCena || currentMinutes < mediaNocheHora) {
          // Entre 9 pm y 12 am: Mostrar media noche
          if (todasLasComidas.contains('Media noche')) {
            comidaAMostrar = 'Media noche';
          }
        }
      }

      // Si encontramos una comida para mostrar, la agregamos
      if (comidaAMostrar.isNotEmpty) {
        foods.add(comidaAMostrar);
        debugPrint("Comida seleccionada: $comidaAMostrar");
      } else {
        debugPrint(
            "No se encontró una comida válida para mostrar en este horario");
      }
    }

    return foods.isEmpty ? ["Sin alimentación"] : foods;
  }

  // Helper para convertir string de hora a TimeOfDay
  TimeOfDay? _parseTimeString(String timeString) {
    try {
      final List<String> parts = timeString.split(':');
      if (parts.length < 2) return null;
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      debugPrint('Error al parsear hora: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener áreas disponibles del provider
    final areasProvider = Provider.of<AreasProvider>(context);
    final areas = areasProvider.areas
        .map((area) => area.name) // sacar las areas unicas
        .toSet()
        .toList();

    // Verificar si el área seleccionada ya no existe en la lista filtrada
    if (_selectedArea != null && !areas.contains(_selectedArea)) {
      // Resetear si el área ya no existe
      _selectedArea = null;
    }

    // Obtener supervisores disponibles del provider
    final chargersProvider = Provider.of<ChargersOpProvider>(context);
    final supervisors = chargersProvider.chargers;

    // Verificar si el supervisor seleccionado aún existe
    if (_selectedSupervisorId != null &&
        !supervisors.any((s) => s.id == _selectedSupervisorId)) {
      _selectedSupervisorId = null;
    }

    return Consumer<AssignmentsProvider>(
      builder: (context, assignmentsProvider, child) {
        if (assignmentsProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        var activeAssignments = assignmentsProvider.inProgressAssignments;

        // Ordenar y traer las más recientes
        activeAssignments.sort((a, b) => b.date.compareTo(a.date));

        // Aplicar filtros
        var filteredAssignments = activeAssignments.where((assignment) {
          // Filtrar por texto de búsqueda
          bool matchesSearch = true;
          if (widget.searchQuery.isNotEmpty) {
            final matchesTask = assignment.task
                .toLowerCase()
                .contains(widget.searchQuery.toLowerCase());
            final matchesWorker = assignment.workers.any((worker) => worker.name
                .toString()
                .toLowerCase()
                .contains(widget.searchQuery.toLowerCase()));
            matchesSearch = matchesTask || matchesWorker;
          }

          // Filtrar por área seleccionada
          bool matchesArea = true;
          if (_selectedArea != null && _selectedArea!.isNotEmpty) {
            matchesArea = assignment.area == _selectedArea;
          }

          // Filtrar por supervisor seleccionado
          bool matchesSupervisor = true;
          if (_selectedSupervisorId != null) {
            matchesSupervisor =
                assignment.inChagers.contains(_selectedSupervisorId);
          }

          return matchesSearch && matchesArea && matchesSupervisor;
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            // Si tuviéramos una recarga desde API la llamaríamos aquí
          },
          child: Column(
            children: [
              buildFilterBar(areas, supervisors, _showFilters, _selectedArea,
                  _selectedSupervisorId, context, setState),
              Expanded(
                child: filteredAssignments.isEmpty
                    ? EmptyState(
                        message: activeAssignments.isEmpty
                            ? 'No hay asignaciones activas en este momento.'
                            : 'No hay asignaciones activas que coincidan con los filtros aplicados.',
                        showClearButton: widget.searchQuery.isNotEmpty ||
                            _selectedArea != null ||
                            _selectedSupervisorId != null,
                        onClear: () {
                          setState(() {
                            _selectedArea = null;
                            _selectedSupervisorId = null;
                          });
                        },
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Consumer<FeedingProvider>(
                            builder: (context, feedingProvider, _) {
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.9,
                                ),
                                itemCount: filteredAssignments.length,
                                itemBuilder: (context, index) {
                                  final assignment = filteredAssignments[index];
                                  return _buildAssignmentCard(
                                      context, assignment, assignmentsProvider);
                                },
                              );
                            },
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignmentCard(BuildContext context, Assignment assignment,
      AssignmentsProvider provider) {
    final areas_provider = Provider.of<AreasProvider>(context, listen: false);
    final feedingProvider =
        Provider.of<FeedingProvider>(context, listen: false);

    List<String> foods = _determinateFoods(assignment.time, assignment.endTime);
    // Verificar si hay comidas y no es "Sin alimentación"
    bool validFood = foods.isNotEmpty && foods[0] != 'Sin alimentación';

    // Verificar si todos los trabajadores han recibido la comida
    bool allWorkersReceived = false;
    if (validFood) {
      // Usar el nuevo método para verificar
      List<int> workerIds = assignment.workers.map((w) => w.id).toList();
      allWorkersReceived = feedingProvider.areAllWorkersMarked(
          assignment.id ?? 0, workerIds, foods[0]);
    }

    // Mostrar chip solo si hay comida válida y NO todos han recibido
    bool shouldShowFoodChips = validFood && !allWorkersReceived;

    return Neumorphic(
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
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: const Color(0xFF3182CE),
                width: 4,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3182CE).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3182CE),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'EN CURSO',
                      style: TextStyle(
                        color: Color(0xFF3182CE),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Task name - Usando Expanded para mejor adaptación
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.task,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Area with icon
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: Color(0xFF718096),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            areas_provider
                                    .getAreaById(assignment.areaId)
                                    ?.name ??
                                "",
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

              // Elegant separator
              Container(
                height: 1,
                color: const Color(0xFFEDF2F7),
                margin: const EdgeInsets.only(bottom: 6),
              ),

              // Info footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Fecha - más compacta
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 10,
                        color: const Color(0xFF718096).withOpacity(0.8),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        DateFormat('dd/MM/yy').format(assignment.date),
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF718096).withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Worker count - más compacto
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 10,
                        color: const Color(0xFF718096).withOpacity(0.8),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        "${assignment.workers.length}",
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF718096).withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Complete button - elegante pero compacto
                  Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38A169),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38A169).withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => showCompletionDialog(
                            context: context,
                            assignment: assignment,
                            provider: provider),
                        customBorder: const CircleBorder(),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Food chips section modified with conditional rendering
              if (shouldShowFoodChips)
                Container(
                  margin: const EdgeInsets.only(top: 4.0),
                  padding: const EdgeInsets.symmetric(
                      vertical: 4.0, horizontal: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (foods.contains('Desayuno'))
                            _buildFoodChip(Icons.free_breakfast, "Desayuno",
                                Colors.orange[700]!),
                          if (foods.contains('Almuerzo'))
                            _buildFoodChip(Icons.restaurant, "Almuerzo",
                                Colors.green[700]!),
                          if (foods.contains('Cena'))
                            _buildFoodChip(
                                Icons.dinner_dining, "Cena", Colors.blue[700]!),
                          if (foods.contains('Media noche'))
                            _buildFoodChip(Icons.nightlight_round,
                                "Media noche", Colors.indigo[700]!),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodChip(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Tooltip(
        message: "",
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 2),
              Text(
                label.split(' ')[
                    0], // Mostrar solo la primera palabra para ahorrar espacio
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignmentDetails(BuildContext context, Assignment assignment) {
    final assignmentsProvider =
        Provider.of<AssignmentsProvider>(context, listen: false);

    final feedingProvider =
        Provider.of<FeedingProvider>(context, listen: false);

    feedingProvider.loadFeedingStatusForOperation(assignment.id ?? 0, context);

    final inChargersFormat =
        Provider.of<ChargersOpProvider>(context, listen: false)
            .chargers
            .where((charger) => assignment.inChagers.contains(charger.id))
            .map((charger) {
      return User(
        id: charger.id,
        name: charger.name,
        cargo: charger.cargo,
        dni: charger.dni,
        phone: charger.phone,
      );
    }).toList();

    List<String> foods = _determinateFoods(assignment.time, assignment.endTime);
    bool tieneDerechoAlimentacion = foods.isNotEmpty;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Stack(
          children: [
            Container(
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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 13, 184, 84)
                          .withOpacity(0.1),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                assignment.task,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.room_outlined,
                              size: 16,
                              color: Color.fromARGB(255, 11, 80, 53),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              assignment.area,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 11, 80, 53),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
                          _buildDetailsSection(
                            title: 'Detalles de la asignación',
                            children: [
                              buildDetailRow(
                                  'Fecha',
                                  DateFormat('dd/MM/yyyy')
                                      .format(assignment.date)),
                              buildDetailRow('Hora', assignment.time),
                              buildDetailRow('Estado', 'En curso'),
                              if (assignment.endTime != null)
                                buildDetailRow('Hora de finalización',
                                    assignment.endTime ?? 'No especificada'),
                              if (assignment.endDate != null)
                                buildDetailRow(
                                    'Fecha de finalización',
                                    DateFormat('dd/MM/yyyy')
                                        .format(assignment.endDate!)),
                              buildDetailRow('Zona', 'Zona ${assignment.zone}'),
                              if (assignment.motorship != "" &&
                                  assignment.motorship != null)
                                buildDetailRow(
                                    'Motonave', assignment.motorship ?? ''),
                            ],
                          ),
                          const SizedBox(height: 20),
                          buildWorkersSection(
                            assignment,
                            context,
                            setState: setState,
                            alimentacionStatus: alimentacionStatus,
                            foods: foods,
                            onAlimentacionChanged: tieneDerechoAlimentacion
                                ? (workerId, entregada) {
                                    // Usar el provider para marcar la comida
                                    if (foods.isNotEmpty) {
                                      feedingProvider.markFeeding(
                                        operationId: assignment.id ?? 0,
                                        workerId: workerId,
                                        foodType: foods[0],
                                        context: context,
                                      );
                                    }
                                  }
                                : null,
                          ),

                          const SizedBox(height: 20),
                          assignment.deletedWorkers.map(
                            (worker) {
                              bool entregada =
                                  alimentacionStatus[worker.id] ?? false;

                              debugPrint(
                                  'Alimentación entregada para ${worker.name}: $entregada');

                              return buildWorkerItem(worker, context,
                                  alimentacionEntregada: entregada,
                                  onAlimentacionChanged: (newValue) {
                                // Actualizar el estado local
                                setState(() {
                                  alimentacionStatus[worker.id] = newValue;
                                });

                                // Aquí podrías agregar código para guardar en base de datos si es necesario
                              });
                            },
                          ).isNotEmpty
                              ? _buildDetailsSection(
                                  title: 'Trabajadores eliminados',
                                  children: assignment.deletedWorkers.map(
                                    (worker) {
                                      return buildWorkerItem(worker, context,
                                          isDeleted: true);
                                    },
                                  ).toList(),
                                )
                              : const SizedBox(),
                          const SizedBox(height: 20),

                          // cargar los encargados de la operacion
                          _buildDetailsSection(
                            title: 'Encargados de la operación',
                            children: inChargersFormat.map((charger) {
                              return buildInChargerItem(charger);
                            }).toList(),
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),

                  // Action buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: NeumorphicButton(
                            style: NeumorphicStyle(
                              depth: 2,
                              intensity: 0.7,
                              color: Colors.white,
                              boxShape: NeumorphicBoxShape.roundRect(
                                  BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              Navigator.pop(context);

                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.9,
                                        maxHeight:
                                            MediaQuery.of(context).size.height *
                                                0.9,
                                      ),
                                      child: EditAssignmentForm(
                                        assignment: assignment,
                                        onSave: (updatedAssignment) {
                                          assignmentsProvider.updateAssignment(
                                              updatedAssignment, context);
                                          showSuccessToast(context,
                                              'Asignación actualizada');
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        },
                                        onCancel: () => Navigator.pop(context),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: const Text(
                              'Editar',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF3182CE),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Consumer<AssignmentsProvider>(
                              builder: (context, provider, child) {
                            return NeumorphicButton(
                              style: NeumorphicStyle(
                                depth: 2,
                                intensity: 0.7,
                                color: const Color(0xFF3182CE),
                                boxShape: NeumorphicBoxShape.roundRect(
                                    BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                showCompletionDialog(
                                    context: context,
                                    assignment: assignment,
                                    provider: provider);
                              },
                              child: const Text(
                                'Completar',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Botón flotante de cancelar en la esquina inferior derecha
            Positioned(
              right: 20,
              bottom: 90, // Colocado encima de los botones principales
              child: NeumorphicButton(
                style: NeumorphicStyle(
                  depth: 4,
                  intensity: 0.8,
                  color: const Color(0xFFF56565),
                  boxShape: NeumorphicBoxShape.circle(),
                  shadowDarkColor: const Color(0xFFC53030).withOpacity(0.4),
                ),
                padding: const EdgeInsets.all(16),
                onPressed: () {
                  Navigator.pop(context);
                  _showCancelDialog(context, assignment, assignmentsProvider);
                },
                // garbage icon
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Método para mostrar el diálogo de cancelación (agregarlo si no existe)
  void _showCancelDialog(BuildContext context, Assignment assignment,
      AssignmentsProvider provider) {
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Cancelar asignación'),
              content: const Text(
                '¿Estás seguro de que deseas cancelar esta asignación?',
                style: TextStyle(color: Color(0xFF718096)),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isProcessing ? null : () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    foregroundColor: isProcessing
                        ? const Color(0xFFCBD5E0)
                        : const Color(0xFF718096),
                  ),
                  child: const Text('No'),
                ),
                NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: isProcessing ? 0 : 2,
                    intensity: 0.7,
                    color: isProcessing
                        ? const Color(0xFFFED7D7)
                        : const Color(0xFFF56565),
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                  ),
                  onPressed: isProcessing
                      ? null
                      : () async {
                          setDialogState(() {
                            isProcessing = true;
                          });

                          try {
                            debugPrint(
                                'Cancelando asignación ${assignment.id}');

                            // Aquí iría la llamada a la API para cancelar
                            final success =
                                await provider.updateAssignmentStatus(
                                    assignment.id ?? 0, 'CANCELED', context);

                            final workersProvider =
                                Provider.of<WorkersProvider>(context,
                                    listen: false);
                            for (var worker in assignment.workers) {
                              workersProvider.releaseWorkerObject(
                                  worker, context);
                            }

                            Navigator.pop(dialogContext);
                            showSuccessToast(
                                context, 'Asignación cancelada exitosamente');
                          } catch (e) {
                            debugPrint('Error al cancelar asignación: $e');

                            if (context.mounted) {
                              setDialogState(() {
                                isProcessing = false;
                              });
                              showErrorToast(
                                  context, 'Error al cancelar asignación: $e');
                            }
                          }
                        },
                  child: Container(
                    width: 100,
                    height: 36,
                    child: Center(
                      child: isProcessing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Procesando',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Sí, cancelar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailsSection(
      {required String title, required List<Widget> children}) {
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
        ...children,
      ],
    );
  }
}
