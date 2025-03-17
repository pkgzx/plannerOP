import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plannerop/core/model/worker.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/store/workers.dart';
import 'package:provider/provider.dart';
import 'package:plannerop/utils/toast.dart';

// Cambiamos de StatelessWidget a StatefulWidget para poder manejar estado local
class WorkerDetailsSection extends StatefulWidget {
  final Worker worker;
  final Color specialtyColor;
  final String workerCode;

  const WorkerDetailsSection({
    Key? key,
    required this.worker,
    required this.specialtyColor,
    required this.workerCode,
  }) : super(key: key);

  @override
  State<WorkerDetailsSection> createState() => _WorkerDetailsSectionState();
}

class _WorkerDetailsSectionState extends State<WorkerDetailsSection> {
  // Variable local para mantener el número actual de faltas
  late int currentFailures;

  @override
  void initState() {
    super.initState();
    // Inicializar con el valor del worker
    currentFailures = widget.worker.failures;
  }

  @override
  void didUpdateWidget(WorkerDetailsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar si el worker cambió
    if (widget.worker.failures != currentFailures) {
      currentFailures = widget.worker.failures;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información de contacto
        _buildInfoSection(
          title: 'Información Personal',
          icon: Icons.person_outline,
          color: widget.specialtyColor,
          content: [
            _buildInfoRow(
                Icons.badge_outlined, 'Documento', widget.worker.document),
            _buildInfoRow(
                Icons.phone_outlined, 'Teléfono', widget.worker.phone),
            _buildInfoRow(Icons.calendar_today_outlined, 'Fecha de inicio',
                DateFormat('dd/MM/yyyy').format(widget.worker.startDate)),
            _buildInfoRow(Icons.qr_code_outlined, 'Código', widget.workerCode),
          ],
        ),

        const SizedBox(height: 20),

        // Información de estado
        _buildStatusSection(),

        const SizedBox(height: 20),

        // Sección de faltas
        _buildFaultsSection(context),
      ],
    );
  }

  // Nueva sección para gestionar faltas
  Widget _buildFaultsSection(BuildContext context) {
    // Si el trabajador está retirado, no mostrar esta sección
    if (widget.worker.status == WorkerStatus.deactivated) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.amber[700], size: 20),
            const SizedBox(width: 8),
            Text(
              'Registro de Faltas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.amber[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contador de faltas con visualización
              _buildFaultCounter(),

              const SizedBox(height: 16),

              // Botón para registrar nueva falta
              NeumorphicButton(
                style: NeumorphicStyle(
                  depth: 2,
                  intensity: 0.7,
                  color: const Color(0xFFED8936),
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                ),
                onPressed: () => _showAddFaultDialog(context),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_circle_outline,
                        color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Registrar Falta',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Añadir espacio entre botones
              const SizedBox(height: 12),

              // Botón para marcar ausencia/abandono
              NeumorphicButton(
                style: NeumorphicStyle(
                  depth: 2,
                  intensity: 0.7,
                  color: const Color(0xFFE53E3E),
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                ),
                onPressed: () => _showMarkAbsenceDialog(context),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.assignment_late_outlined,
                        color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Marcar Abandono de Trabajo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget para mostrar el contador de faltas de forma visual
  Widget _buildFaultCounter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total de faltas registradas:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getFaultLevelColor(),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                currentFailures.toString(), // Usamos la variable local
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Barra de progreso visual
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _calculateFaultProgress(),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_getFaultLevelColor()),
            minHeight: 8,
          ),
        ),

        const SizedBox(height: 8),

        // Estado de las faltas
        Text(
          _getFaultLevelText(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _getFaultLevelColor(),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  void _showAddFaultDialog(BuildContext context) {
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título con ícono
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.amber[700], size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Registrar Falta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const Spacer(),
                        if (!isProcessing)
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.grey[500]),
                            onPressed: () => Navigator.pop(dialogContext),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '¿Deseas registrar una falta para ${widget.worker.name}?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Divider(height: 24),

                    // Información sobre consecuencias
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber[100]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.amber[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Esta será la falta número ${currentFailures + 1} para este trabajador.',
                              style: TextStyle(
                                color: Colors.amber[900],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botones de acción
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isProcessing
                              ? null
                              : () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            foregroundColor: isProcessing
                                ? Colors.grey[400]
                                : Colors.grey[700],
                          ),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        NeumorphicButton(
                          style: NeumorphicStyle(
                            depth: isProcessing ? 0 : 2,
                            intensity: 0.7,
                            color: isProcessing
                                ? Colors.orange.shade200
                                : Colors.orange.shade600,
                            boxShape: NeumorphicBoxShape.roundRect(
                                BorderRadius.circular(8)),
                          ),
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  setDialogState(() {
                                    isProcessing = true;
                                  });

                                  try {
                                    final workersProvider =
                                        Provider.of<WorkersProvider>(context,
                                            listen: false);

                                    final success =
                                        await workersProvider.registerFault(
                                      widget.worker,
                                      context,
                                    );

                                    if (success) {
                                      // Actualizar inmediatamente el estado local
                                      setState(() {
                                        currentFailures++;
                                      });

                                      Navigator.pop(dialogContext);
                                      showSuccessToast(context,
                                          'Falta registrada correctamente');
                                    } else {
                                      setDialogState(() {
                                        isProcessing = false;
                                      });
                                      showErrorToast(context,
                                          'Error al registrar la falta');
                                    }
                                  } catch (e) {
                                    setDialogState(() {
                                      isProcessing = false;
                                    });
                                    showErrorToast(context, 'Error: $e');
                                  }
                                },
                          child: Container(
                            width: 100,
                            height: 36,
                            alignment: Alignment.center,
                            child: isProcessing
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Registrando',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Registrar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
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
        );
      },
    );
  }

// Método para mostrar el diálogo de ausencia/abandono
  void _showMarkAbsenceDialog(BuildContext context) {
    bool isProcessing = false;
    bool isAbandonment = false; // Para distinguir entre ausencia y abandono

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título con ícono
                    Row(
                      children: [
                        Icon(Icons.assignment_late_outlined,
                            color: Colors.red[700], size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Registrar Abandono de Trabajo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const Spacer(),
                        if (!isProcessing)
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.grey[500]),
                            onPressed: () => Navigator.pop(dialogContext),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Seleccione el tipo de incidente para ${widget.worker.name}:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Divider(height: 24),

                    // Opciones para seleccionar
                    ListTile(
                      title: const Text('Ausencia'),
                      subtitle:
                          const Text('El trabajador no se presentó a trabajar'),
                      leading: Radio<bool>(
                        value: false,
                        groupValue: isAbandonment,
                        onChanged: isProcessing
                            ? null
                            : (bool? value) {
                                setDialogState(() {
                                  isAbandonment = value!;
                                });
                              },
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),

                    ListTile(
                      title: const Text('Abandono'),
                      subtitle: const Text(
                          'El trabajador abandonó su puesto sin autorización'),
                      leading: Radio<bool>(
                        value: true,
                        groupValue: isAbandonment,
                        onChanged: isProcessing
                            ? null
                            : (bool? value) {
                                setDialogState(() {
                                  isAbandonment = value!;
                                });
                              },
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 12),

                    // Información sobre consecuencias
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_outlined,
                              color: Colors.red[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Esta acción es grave y quedará registrada en el historial del trabajador.',
                              style: TextStyle(
                                color: Colors.red[900],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botones de acción
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isProcessing
                              ? null
                              : () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            foregroundColor: isProcessing
                                ? Colors.grey[400]
                                : Colors.grey[700],
                          ),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        NeumorphicButton(
                          style: NeumorphicStyle(
                            depth: isProcessing ? 0 : 2,
                            intensity: 0.7,
                            color: isProcessing
                                ? Colors.red.shade200
                                : Colors.red.shade600,
                            boxShape: NeumorphicBoxShape.roundRect(
                                BorderRadius.circular(8)),
                          ),
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  setDialogState(() {
                                    isProcessing = true;
                                  });

                                  try {
                                    final workersProvider =
                                        Provider.of<WorkersProvider>(context,
                                            listen: false);

                                    // Aquí llamaríamos a un método en WorkersProvider
                                    // que maneje el registro de ausencias/abandonos
                                    // final success = await workersProvider.registerAbsence(
                                    //   widget.worker,
                                    //   isAbandonment,
                                    //   context,
                                    // );

                                    // if (success) {
                                    //   Navigator.pop(dialogContext);
                                    //   showSuccessToast(
                                    //       context,
                                    //       isAbandonment
                                    //           ? 'Abandono registrado correctamente'
                                    //           : 'Ausencia registrada correctamente');
                                    // } else {
                                    //   setDialogState(() {
                                    //     isProcessing = false;
                                    //   });
                                    //   showErrorToast(context,
                                    //       'Error al registrar el incidente');
                                    // }
                                  } catch (e) {
                                    setDialogState(() {
                                      isProcessing = false;
                                    });
                                    showErrorToast(context, 'Error: $e');
                                  }
                                },
                          child: Container(
                            width: 100,
                            height: 36,
                            alignment: Alignment.center,
                            child: isProcessing
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Registrando',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Registrar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
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
        );
      },
    );
  }

  // Calcular el progreso de las faltas (0.0 a 1.0) basado en nuestra variable local
  double _calculateFaultProgress() {
    const int maxFaults =
        5; // Número máximo de faltas antes de considerarse crítico
    return (currentFailures / maxFaults).clamp(0.0, 1.0);
  }

  // Obtener el color según el nivel de faltas (usando nuestra variable local)
  Color _getFaultLevelColor() {
    if (currentFailures == 0) {
      return Colors.green;
    } else if (currentFailures <= 2) {
      return Colors.amber.shade600;
    } else if (currentFailures <= 4) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Obtener el texto descriptivo según el nivel de faltas (usando nuestra variable local)
  String _getFaultLevelText() {
    if (currentFailures == 0) {
      return 'Sin faltas registradas';
    } else if (currentFailures <= 2) {
      return 'Nivel de faltas bajo';
    } else if (currentFailures <= 3) {
      return 'Nivel de faltas moderado';
    } else if (currentFailures <= 4) {
      return 'Nivel de faltas alto';
    } else {
      return 'Nivel de faltas crítico';
    }
  }

  // Resto de métodos adaptados para usar widget.worker en lugar de worker
  Widget _buildStatusSection() {
    // No mostrar esta sección para trabajadores disponibles regulares
    if (widget.worker.status == WorkerStatus.available ||
        (widget.worker.status == WorkerStatus.assigned &&
            widget.worker.endDate == null)) {
      return Container();
    }

    String title;
    IconData icon;
    Color color;
    List<Widget> rows = [];

    // Configurar según el estado
    switch (widget.worker.status) {
      case WorkerStatus.assigned:
        title = 'Información de Asignación';
        icon = Icons.assignment_turned_in;
        color = Colors.amber[700]!;
        if (widget.worker.endDate != null) {
          rows.add(_buildInfoRow(
              Icons.event_available_outlined,
              'Asignado hasta',
              DateFormat('dd/MM/yyyy').format(widget.worker.endDate!)));
        }
        break;

      case WorkerStatus.incapacitated:
        title = 'Información de Incapacidad';
        icon = Icons.medical_services_outlined;
        color = Colors.purple;

        if (widget.worker.incapacityStartDate != null) {
          rows.add(_buildInfoRow(
              Icons.date_range_outlined,
              'Inicio',
              DateFormat('dd/MM/yyyy')
                  .format(widget.worker.incapacityStartDate!)));
        }

        if (widget.worker.incapacityEndDate != null) {
          rows.add(_buildInfoRow(
              Icons.date_range_outlined,
              'Fin',
              DateFormat('dd/MM/yyyy')
                  .format(widget.worker.incapacityEndDate!)));

          // Calcular días restantes
          final daysLeft = widget.worker.incapacityEndDate!
              .difference(DateTime.now())
              .inDays;
          String daysLeftText =
              daysLeft > 0 ? '$daysLeft días restantes' : 'Finalizada';

          rows.add(
              _buildInfoRow(Icons.hourglass_bottom, 'Estado', daysLeftText));
        }
        break;

      case WorkerStatus.deactivated:
        title = 'Información de Retiro';
        icon = Icons.exit_to_app;
        color = Colors.grey[700]!;

        if (widget.worker.deactivationDate != null) {
          rows.add(_buildInfoRow(
              Icons.event_busy_outlined,
              'Fecha de retiro',
              DateFormat('dd/MM/yyyy')
                  .format(widget.worker.deactivationDate!)));
        }
        break;

      default:
        return Container();
    }

    // Si no hay filas, no mostrar la sección
    if (rows.isEmpty) {
      return Container();
    }

    return _buildInfoSection(
      title: title,
      icon: icon,
      color: color,
      content: rows,
    );
  }

  // Los métodos _buildInfoSection e _buildInfoRow permanecen iguales
  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> content,
  }) {
    // Implementación existente
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              ...content,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    // Implementación existente
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
