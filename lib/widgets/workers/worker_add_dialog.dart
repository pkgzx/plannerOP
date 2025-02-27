import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/worker.dart';

class WorkerAddDialog extends StatefulWidget {
  final Function(Worker) onWorkerAdded;

  const WorkerAddDialog({
    Key? key,
    required this.onWorkerAdded,
  }) : super(key: key);

  @override
  State<WorkerAddDialog> createState() => _WorkerAddDialogState();

  static void show(BuildContext context, Function(Worker) onWorkerAdded) {
    showDialog(
      context: context,
      builder: (context) => WorkerAddDialog(
        onWorkerAdded: onWorkerAdded,
      ),
    );
  }
}

class _WorkerAddDialogState extends State<WorkerAddDialog> {
  final nameController = TextEditingController();
  final documentController = TextEditingController();
  final phoneController = TextEditingController();

  // Lista de áreas disponibles
  final List<String> areas = [
    'CARGA GENERAL',
    'CARGA REFRIGERADA',
    'CAFÉ',
    'ADMINISTRATIVA',
    'MANTENIMIENTO',
    'SEGURIDAD',
  ];

  // Valor seleccionado por defecto
  String selectedArea = 'CARGA GENERAL';

  @override
  void dispose() {
    nameController.dispose();
    documentController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        // Envuelve el contenido en SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabecera
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF4299E1).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add,
                  color: Color(0xFF4299E1),
                  size: 30,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Agregar Trabajador',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 20),

              // Campo de nombre
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person, color: Color(0xFF4299E1)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Campo de documento
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: documentController,
                  decoration: const InputDecoration(
                    labelText: 'Documento',
                    prefixIcon: Icon(Icons.badge, color: Color(0xFF4299E1)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                    hintText: 'DNI, Pasaporte, etc.',
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Campo de área con dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.work, color: Color(0xFF4299E1)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedArea,
                          hint: const Text('Seleccionar área'),
                          items: areas.map((String area) {
                            return DropdownMenuItem<String>(
                              value: area,
                              child: Text(area),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedArea = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Campo de contacto (teléfono)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono de contacto',
                    prefixIcon: Icon(Icons.phone, color: Color(0xFF4299E1)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          final newWorker = Worker(
                            name: nameController.text.trim(),
                            area: selectedArea,
                            phone: phoneController.text.trim(),
                            document: documentController.text.trim().isEmpty
                                ? 'Sin documento'
                                : documentController.text.trim(),
                            status: WorkerStatus.available,
                            startDate: DateTime.now(),
                            endDate: null,
                          );

                          widget.onWorkerAdded(newWorker);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4299E1),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Guardar',
                        style: TextStyle(
                          color: Colors.white,
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
      ),
    );
  }
}
