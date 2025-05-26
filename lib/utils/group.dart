import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/operation.dart';
import 'package:plannerop/core/model/workerGroup.dart';
import 'package:plannerop/store/feedings.dart';
import 'package:plannerop/store/workers.dart';
import 'package:plannerop/utils/operations.dart';
import 'package:plannerop/utils/foodUtils.dart';
import 'package:plannerop/utils/worker_utils.dart';
import 'package:plannerop/widgets/operations/components/utils.dart';
import 'package:provider/provider.dart';

String getGroupName(DateTime? startDate, DateTime? endDate, String? startTime,
    String? endTime) {
  // Reemplazar la generación del nombre de grupo
  String groupName = '';

  // Determinar si las fechas son diferentes
  bool hasDifferentDates = startDate != null &&
      endDate != null &&
      DateFormat('yyyy-MM-dd').format(startDate) !=
          DateFormat('yyyy-MM-dd').format(endDate);

  // Caso 1: Tiene todos los campos de horario (fecha y hora de inicio y fin)
  if (startDate != null &&
      endDate != null &&
      startTime != null &&
      endTime != null) {
    if (hasDifferentDates) {
      // Fechas diferentes: mostrar ambas fechas completas con horas
      groupName =
          ' ${DateFormat('dd/MM').format(startDate)} $startTime - ${DateFormat('dd/MM').format(endDate)} $endTime';
    } else {
      // Misma fecha: mostrar fecha una vez con ambas horas
      groupName =
          ' ${DateFormat('dd/MM').format(startDate)} $startTime-$endTime';
    }
  }
  // Caso 2: Solo tiene fechas (sin horas)
  else if (startDate != null && endDate != null) {
    if (hasDifferentDates) {
      groupName =
          ' ${DateFormat('dd/MM').format(startDate)} - ${DateFormat('dd/MM').format(endDate)}';
    } else {
      groupName = ' ${DateFormat('dd/MM').format(startDate)}';
    }
  }
  // Caso 3: Solo tiene horas (sin fechas)
  else if (startTime != null && endTime != null) {
    groupName = ' $startTime-$endTime';
  }
  // Caso 4: Combinaciones parciales
  else if (startDate != null && startTime != null) {
    groupName = ' ${DateFormat('dd/MM').format(startDate!)} $startTime';
  } else if (endDate != null && endTime != null) {
    groupName = 'Fin: ${DateFormat('dd/MM').format(endDate!)} $endTime';
  }
  // Caso 5: Solo una fecha o hora
  else if (startDate != null) {
    groupName = 'Inicio: ${DateFormat('dd/MM').format(startDate!)}';
  } else if (endDate != null) {
    groupName = 'Fin: ${DateFormat('dd/MM').format(endDate!)}';
  } else if (startTime != null) {
    groupName = 'Inicio: $startTime';
  } else if (endTime != null) {
    groupName = 'Fin: $endTime';
  }

  return groupName;
}

Widget buildGroupsSection(
    BuildContext context, List<WorkerGroup> groups, String title,
    {Operation? assignment,
    Map<int, bool> alimentacionStatus = const {},
    List<String> foods = const [], // Este será ignorado, calculamos por grupo
    Function(int, bool)? onAlimentacionChanged}) {
  // Obtener el FeedingProvider
  final feedingProvider = Provider.of<FeedingProvider>(context);

  for (var group in groups) {
    group.workersData = group.workers
        .map((workerId) =>
            context.read<WorkersProvider>().getWorkerById(workerId))
        .toList();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 57, 80, 121),
        ),
      ),
      const SizedBox(height: 12),
      ...groups.asMap().entries.map((entry) {
        final index = entry.key;
        final group = entry.value;

        // NUEVO: Calcular alimentación específica para este grupo
        List<String> groupFoods = [];
        bool hasGroupFoodRights = false;
        String currentFoodType = '';

        // Determinar horarios para este grupo específico
        String? groupStartTime = group.startTime;
        String? groupEndTime = group.endTime;

        // Si el grupo no tiene horarios específicos, usar los de la operación
        if ((groupStartTime == null || groupStartTime.isEmpty) &&
            assignment != null) {
          groupStartTime = assignment.time;
          groupEndTime = assignment.endTime;
        }

        // Solo calcular alimentación si tenemos horarios válidos
        if (groupStartTime != null && groupStartTime.isNotEmpty) {
          groupFoods = FoodUtils.determinateFoodsWithDeliveryStatus(
            groupStartTime,
            groupEndTime,
            context,
            operationId: assignment?.id,
            workerId: null, // No específico para trabajador individual
          );

          hasGroupFoodRights = groupFoods.isNotEmpty &&
              !groupFoods.contains('Sin alimentación') &&
              !groupFoods.contains('Sin alimentación actual') &&
              !groupFoods[0].contains('ya entregado');

          if (hasGroupFoodRights) {
            currentFoodType = groupFoods[0];
          }
        }

        debugPrint(
            'Grupo ${index + 1}: Horario $groupStartTime - $groupEndTime, Comidas: $groupFoods');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera del grupo
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3182CE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Grupo ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Horario del grupo
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF2F7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: Color(0xFF4A5568),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          getGroupName(
                              group.startDate != null
                                  ? DateTime.parse(group.startDate!)
                                  : null,
                              group.endDate != null
                                  ? DateTime.parse(group.endDate!)
                                  : null,
                              group.startTime,
                              group.endTime),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4A5568),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Servicio
              Row(
                children: [
                  const Icon(
                    Icons.design_services,
                    size: 16,
                    color: Color(0xFF3182CE),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      getServiceName(context, group.serviceId),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ],
              ),

              // NUEVO: Mostrar información de alimentación del grupo
              if (hasGroupFoodRights) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        getIconForFoodType(currentFoodType, false),
                        size: 12,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$currentFoodType disponible',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Trabajadores - SECCIÓN MODIFICADA
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.people,
                    size: 16,
                    color: Color(0xFF4A5568),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trabajadores asignados:',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A5568),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Lista de trabajadores con nombre y DNI
                        if (group.workersData != null &&
                            group.workersData!.isNotEmpty)
                          ...group.workersData!.map((worker) {
                            // MODIFICADO: Verificar estado de alimentación para este trabajador CON EL HORARIO DEL GRUPO
                            bool _alimentacionEntregada = false;
                            bool _puedeMarcarAlimentacion = false;

                            if (assignment != null && hasGroupFoodRights) {
                              // Verificar si ya está marcada para este trabajador específico
                              _alimentacionEntregada = feedingProvider.isMarked(
                                  assignment.id ?? 0,
                                  worker.id,
                                  currentFoodType);

                              // Verificar si puede marcar alimentación usando los horarios del grupo
                              _puedeMarcarAlimentacion =
                                  FoodUtils.puedeMarcarAlimentacion(
                                      groupStartTime,
                                      groupEndTime,
                                      context,
                                      assignment.id ?? 0,
                                      worker.id);
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: _alimentacionEntregada
                                    ? Colors.green.shade50.withOpacity(0.7)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _alimentacionEntregada
                                      ? Colors.green.withOpacity(0.3)
                                      : const Color(0xFF3182CE)
                                          .withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Primera fila: información del trabajador
                                  Row(
                                    children: [
                                      // Avatar del trabajador
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor:
                                            getColorForWorker(worker),
                                        child: Text(
                                          worker.name.isNotEmpty
                                              ? worker.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Información del trabajador
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              worker.name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF2D3748),
                                              ),
                                            ),
                                            Text(
                                              'DNI: ${worker.document}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF718096),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Segunda fila: botón de alimentación (si aplica)
                                  if (hasGroupFoodRights &&
                                      onAlimentacionChanged != null &&
                                      currentFoodType.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: GestureDetector(
                                        onTap: _alimentacionEntregada
                                            ? () {
                                                // Ya está entregada, mostrar mensaje informativo
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'La alimentación ya fue entregada a ${worker.name}'),
                                                    backgroundColor:
                                                        Colors.blue,
                                                    duration: const Duration(
                                                        seconds: 2),
                                                  ),
                                                );
                                              }
                                            : (_puedeMarcarAlimentacion
                                                ? () {
                                                    onAlimentacionChanged(
                                                        worker.id, true);
                                                  }
                                                : () {
                                                    // No se puede marcar en este momento
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'La alimentación no está disponible en este horario'),
                                                        backgroundColor:
                                                            Colors.orange,
                                                        duration:
                                                            const Duration(
                                                                seconds: 2),
                                                      ),
                                                    );
                                                  }),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4, horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: _alimentacionEntregada
                                                ? Colors.green.withOpacity(0.1)
                                                : (_puedeMarcarAlimentacion
                                                    ? Colors.orange
                                                        .withOpacity(0.1)
                                                    : Colors.grey
                                                        .withOpacity(0.1)),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                              color: _alimentacionEntregada
                                                  ? Colors.green
                                                      .withOpacity(0.3)
                                                  : (_puedeMarcarAlimentacion
                                                      ? Colors.orange
                                                          .withOpacity(0.3)
                                                      : Colors.grey
                                                          .withOpacity(0.3)),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                getIconForFoodType(
                                                    currentFoodType,
                                                    _alimentacionEntregada),
                                                size: 14,
                                                color: _alimentacionEntregada
                                                    ? Colors.green[700]
                                                    : (_puedeMarcarAlimentacion
                                                        ? Colors.orange[700]
                                                        : Colors.grey[700]),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _alimentacionEntregada
                                                    ? '$currentFoodType entregado'
                                                    : (_puedeMarcarAlimentacion
                                                        ? 'Marcar $currentFoodType'
                                                        : 'No disponible'),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: _alimentacionEntregada
                                                      ? Colors.green[700]
                                                      : (_puedeMarcarAlimentacion
                                                          ? Colors.orange[700]
                                                          : Colors.grey[700]),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList()
                        else
                          // Fallback si no hay workersData disponible
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF5F5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFFEB2B2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: Color(0xFFE53E3E),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${group.workers.length} trabajador${group.workers.length != 1 ? 'es' : ''} asignado${group.workers.length != 1 ? 's' : ''} (detalles no disponibles)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFE53E3E),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    ],
  );
}
